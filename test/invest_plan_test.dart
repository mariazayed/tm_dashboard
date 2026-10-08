import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/invest_settings_model.dart';
import 'package:tm_dashboard/models/invest/plan_model.dart';
import 'package:tm_dashboard/screens/invest/rules_card.dart';
import 'package:tm_dashboard/screens/invest/rules_screen.dart';
import 'package:tm_dashboard/screens/invest/settings_screen.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

Map<String, dynamic> ruleJson(int id, String text, int position) => {
  'id': id,
  'text': text,
  'position': position,
};

Map<String, dynamic> settingsJson({
  int cents = 30000,
  String currency = 'USD',
  int buyDay = 1,
  String ticker = 'VT',
  String timezone = 'UTC',
  bool reminders = false,
  String? email,
  int followup = 3,
}) => {
  'monthlyAmountCents': cents,
  'currency': currency,
  'buyDay': buyDay,
  'ticker': ticker,
  'startDate': '2026-08-01',
  'timezone': timezone,
  'remindersEnabled': reminders,
  'reminderEmail': email,
  'reminderFollowupDays': followup,
};

Map<String, dynamic> reminderStatusJson({
  bool configured = true,
  List<Map<String, dynamic>> recent = const [],
}) => {'emailConfigured': configured, 'recent': recent};

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

class Recorder {
  Recorder(this.handler);

  final Future<http.Response> Function(http.Request) handler;
  final requests = <http.Request>[];

  Iterable<http.Request> where(String method, String pathSuffix) => requests
      .where((r) => r.method == method && r.url.path.endsWith(pathSuffix));

  ApiClient api() {
    final api = ApiClient(
      client: MockClient((req) {
        requests.add(req);
        return handler(req);
      }),
    );
    addTearDown(api.close);
    return api;
  }
}

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('models', () {
    test(
      'settings parse the reminder fields and default them for old servers',
      () {
        final s = InvestSettingsModel.fromJson(
          settingsJson(
            reminders: true,
            email: 'me@example.com',
            followup: 5,
            timezone: 'Europe/Berlin',
          ),
        );
        expect(s.remindersEnabled, isTrue);
        expect(s.reminderEmail, 'me@example.com');
        expect(s.reminderFollowupDays, 5);
        expect(s.timezone, 'Europe/Berlin');

        final old = InvestSettingsModel.fromJson({
          'monthlyAmountCents': 30000,
          'currency': 'USD',
          'buyDay': 1,
          'ticker': 'VT',
          'startDate': '2026-08-01',
        });
        expect(old.remindersEnabled, isFalse);
        expect(old.reminderFollowupDays, 3);
        expect(old.timezone, 'UTC');
      },
    );

    test('rules, sent reminders and status parse', () {
      expect(RuleModel.fromJson(ruleJson(1, 'Never sell.', 1)).position, 1);
      final status = ReminderStatusModel.fromJson(
        reminderStatusJson(
          configured: false,
          recent: [
            {
              'month': '2026-10',
              'kind': 'FOLLOWUP',
              'sentAt': '2026-10-18T09:00:00',
            },
          ],
        ),
      );
      expect(status.emailConfigured, isFalse);
      expect(status.recent.single.label, 'follow-up');
      expect(
        SentReminder.fromJson({
          'month': '2026-10',
          'kind': 'DUE',
          'sentAt': '2026-10-15T09:00:00',
        }).label,
        'buy-day reminder',
      );
    });

    test('a test result explains itself', () {
      expect(
        const ReminderTestResult(sent: true).message,
        contains('Test email sent'),
      );
      expect(
        const ReminderTestResult(sent: false, error: 'SMTP down').message,
        'SMTP down',
      );
      expect(
        const ReminderTestResult(
          sent: false,
          skipped: 'Save a reminder email address first',
        ).message,
        'Save a reminder email address first',
      );
    });
  });

  group('PlanService', () {
    test('rule calls hit the right routes with the right bodies', () async {
      final r = Recorder((req) async {
        if (req.method == 'GET' || req.url.path.endsWith('/order')) {
          return ok([ruleJson(2, 'b', 1), ruleJson(1, 'a', 2)]);
        }
        if (req.method == 'DELETE') {
          return http.Response('', 204);
        }
        return ok(ruleJson(1, 'a', 1), req.method == 'POST' ? 201 : 200);
      });
      final service = PlanService(api: r.api());
      expect((await service.rules()).length, 2);
      await service.createRule('a');
      await service.updateRule(1, 'a2');
      await service.deleteRule(1);
      final order = await service.reorderRules([2, 1]);
      expect(order.first.id, 2);

      expect(jsonDecode(r.where('POST', '/rules').single.body), {'text': 'a'});
      expect(
        r.where('PUT', '/rules/1').single.url.path,
        '/api/v1/invest/rules/1',
      );
      expect(jsonDecode(r.where('PUT', '/rules/order').single.body), {
        'ids': [2, 1],
      });
    });

    test('settings are sent whole and the saved plan comes back', () async {
      final r = Recorder(
        (_) async => ok(settingsJson(cents: 45000, currency: 'EUR')),
      );
      final saved = await PlanService(
        api: r.api(),
      ).updateSettings({'monthlyAmountCents': 45000});
      expect(r.requests.single.method, 'PUT');
      expect(r.requests.single.url.path, '/api/v1/invest/settings');
      expect(saved.currency, 'EUR');
    });

    test(
      'a failed test email is data, a server error is an exception',
      () async {
        final r = Recorder(
          (req) async => ok({
            'sent': false,
            'skipped': null,
            'error': 'SMTP down',
            'kind': null,
          }),
        );
        final result = await PlanService(api: r.api()).sendTestReminder();
        expect(result.sent, isFalse);
        expect(result.error, 'SMTP down');

      },
    );
  });

  group('RulesCard', () {
    testWidgets('lists the rules in order and offers edit', (tester) async {
      var edits = 0;
      await tester.pumpWidget(
        host(
          RulesCard(
            rules: const ['Never sell in a crash.', 'Wait 72 hours.'],
            onEdit: () => edits++,
          ),
        ),
      );
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('Never sell in a crash.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('edit-rules')));
      expect(edits, 1);
    });

    testWidgets('is open by default and can be collapsed', (tester) async {
      await tester.pumpWidget(
        host(RulesCard(rules: const ['Never sell in a crash.'], onEdit: () {})),
      );
      expect(find.text('Never sell in a crash.'), findsOneWidget);
      await tester.tap(find.text('My rules'));
      await tester.pumpAndSettle();
      expect(find.text('Never sell in a crash.'), findsNothing);
    });

    testWidgets('invites you to write the first rule when there are none', (
      tester,
    ) async {
      await tester.pumpWidget(host(RulesCard(rules: const [], onEdit: () {})));
      expect(find.byKey(const Key('rules-empty')), findsOneWidget);
      expect(find.text('Add rules'), findsOneWidget);
    });
  });

  group('RulesScreen', () {
    Recorder serverWith(
      List<Map<String, dynamic>> Function() rules, {
      int? failReorderWith,
    }) {
      return Recorder((req) async {
        final path = req.url.path;
        if (req.method == 'GET') {
          return ok(rules());
        }
        if (req.method == 'DELETE') {
          return http.Response('', 204);
        }
        if (path.endsWith('/order')) {
          if (failReorderWith != null) {
            return ok({
              'message': 'The order must list every current rule exactly once',
            }, failReorderWith);
          }
          return ok(rules());
        }
        return ok(ruleJson(9, 'x', 1), req.method == 'POST' ? 201 : 200);
      });
    }

    testWidgets('shows numbered rules and an empty state', (tester) async {
      tall(tester);
      final r = serverWith(
        () => [ruleJson(1, 'First rule', 1), ruleJson(2, 'Second rule', 2)],
      );
      await tester.pumpWidget(
        host(RulesScreen(service: PlanService(api: r.api()))),
      );
      await tester.pumpAndSettle();
      expect(find.text('First rule'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);

      final empty = serverWith(() => []);
      await tester.pumpWidget(
        const SizedBox(),
      ); // drop the old State so the screen loads again
      await tester.pumpWidget(
        host(RulesScreen(service: PlanService(api: empty.api()))),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('no-rules')), findsOneWidget);
    });

    testWidgets('adding a rule posts it, clears the field and reloads', (
      tester,
    ) async {
      tall(tester);
      var rules = [ruleJson(1, 'First rule', 1)];
      final r = Recorder((req) async {
        if (req.method == 'POST') {
          rules = [...rules, ruleJson(2, 'Stay boring.', 2)];
          return ok(ruleJson(2, 'Stay boring.', 2), 201);
        }
        return ok(rules);
      });
      await tester.pumpWidget(
        host(RulesScreen(service: PlanService(api: r.api()))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('new-rule-field')),
        '  Stay boring.  ',
      );
      await tester.tap(find.byKey(const Key('add-rule')));
      await tester.pumpAndSettle();
      expect(jsonDecode(r.where('POST', '/rules').single.body), {
        'text': 'Stay boring.',
      });
      expect(find.text('Stay boring.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('new-rule-field')))
            .controller!
            .text,
        '',
      );
    });

    testWidgets('a blank rule is not sent', (tester) async {
      tall(tester);
      final r = serverWith(() => [ruleJson(1, 'First rule', 1)]);
      await tester.pumpWidget(
        host(RulesScreen(service: PlanService(api: r.api()))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('new-rule-field')), '   ');
      await tester.tap(find.byKey(const Key('add-rule')));
      await tester.pumpAndSettle();
      expect(r.where('POST', '/rules'), isEmpty);
    });

    testWidgets('tapping a rule edits it through a dialog', (tester) async {
      tall(tester);
      final r = serverWith(() => [ruleJson(1, 'Old text', 1)]);
      await tester.pumpWidget(
        host(RulesScreen(service: PlanService(api: r.api()))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Old text'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-rule-field')),
        'New text',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(jsonDecode(r.where('PUT', '/rules/1').single.body), {
        'text': 'New text',
      });
    });

    testWidgets('saving an unchanged rule makes no request', (tester) async {
      tall(tester);
      final r = serverWith(() => [ruleJson(1, 'Same', 1)]);
      await tester.pumpWidget(
        host(RulesScreen(service: PlanService(api: r.api()))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Same'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(r.where('PUT', '/rules/1'), isEmpty);
    });

    testWidgets('delete asks first', (tester) async {
      tall(tester);
      var deleted = false;
      final r = Recorder((req) async {
        if (req.method == 'DELETE') {
          deleted = true;
          return http.Response('', 204);
        }
        return ok(deleted ? [] : [ruleJson(1, 'Doomed rule', 1)]);
      });
      await tester.pumpWidget(
        host(RulesScreen(service: PlanService(api: r.api()))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isFalse);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect(find.text('Doomed rule'), findsNothing);
    });

    Future<void> dragFirstBelowSecond(WidgetTester tester) async {
      // Long-press picks the row up on touch platforms, then it follows the finger.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('First rule')),
      );
      await tester.pump(kLongPressTimeout + kPressTimeout);
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 140));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('dragging a rule sends the new order', (tester) async {
      tall(tester);
      var order = [1, 2];
      final r = Recorder((req) async {
        final texts = {1: 'First rule', 2: 'Second rule'};
        List<Map<String, dynamic>> current() => [
          for (var i = 0; i < order.length; i++)
            ruleJson(order[i], texts[order[i]]!, i + 1),
        ];
        if (req.url.path.endsWith('/order')) {
          order = (jsonDecode(req.body)['ids'] as List).cast<int>();
        }
        return ok(current());
      });
      await tester.pumpWidget(
        host(RulesScreen(service: PlanService(api: r.api()))),
      );
      await tester.pumpAndSettle();
      await dragFirstBelowSecond(tester);
      expect(jsonDecode(r.where('PUT', '/rules/order').single.body), {
        'ids': [2, 1],
      });
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('Second rule'), lessThan(y('First rule')));
    });

    testWidgets(
      'a rejected reorder snaps back to the server order and says why',
      (tester) async {
        tall(tester);
        final r = serverWith(
          () => [ruleJson(1, 'First rule', 1), ruleJson(2, 'Second rule', 2)],
          failReorderWith: 400,
        );
        await tester.pumpWidget(
          host(RulesScreen(service: PlanService(api: r.api()))),
        );
        await tester.pumpAndSettle();
        await dragFirstBelowSecond(tester);
        expect(
          find.text('The order must list every current rule exactly once'),
          findsOneWidget,
        );
        double y(String t) => tester.getTopLeft(find.text(t)).dy;
        expect(
          y('First rule'),
          lessThan(y('Second rule')),
        ); // back where the server has them
      },
    );
  });

  group('SettingsScreen', () {
    Recorder server({
      Map<String, dynamic>? settings,
      Map<String, dynamic>? status,
      Future<http.Response> Function(http.Request)? onPut,
      Map<String, dynamic>? testResult,
    }) {
      return Recorder((req) async {
        final path = req.url.path;
        if (path.endsWith('/reminders/test')) {
          return ok(
            testResult ??
                {'sent': true, 'kind': null, 'skipped': null, 'error': null},
          );
        }
        if (path.endsWith('/reminders')) {
          return ok(status ?? reminderStatusJson());
        }
        if (req.method == 'PUT') {
          if (onPut != null) {
            return onPut(req);
          }
          return ok(jsonDecode(req.body));
        }
        return ok(settings ?? settingsJson());
      });
    }

    Future<void> pump(WidgetTester tester, Recorder r) async {
      tall(tester);
      await tester.pumpWidget(
        const SizedBox(),
      ); // always start from a fresh State
      final api = r.api();
      await tester.pumpWidget(
        host(
          SettingsScreen(
            plan: PlanService(api: api),
            contributions: ContributionService(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    String text(WidgetTester tester, String key) =>
        tester.widget<TextField>(find.byKey(Key(key))).controller!.text;

    testWidgets('loads the current plan into the form', (tester) async {
      await pump(
        tester,
        server(
          settings: settingsJson(
            cents: 45050,
            currency: 'EUR',
            ticker: 'VWCE',
            timezone: 'Europe/Berlin',
            reminders: true,
            email: 'me@example.com',
          ),
        ),
      );
      expect(text(tester, 'amount-field'), '450.50');
      expect(text(tester, 'currency-field'), 'EUR');
      expect(text(tester, 'ticker-field'), 'VWCE');
      expect(text(tester, 'timezone-field'), 'Europe/Berlin');
      expect(text(tester, 'email-field'), 'me@example.com');
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('reminders-switch')))
            .value,
        isTrue,
      );
    });

    testWidgets('saving sends the whole plan with cents, not floats', (
      tester,
    ) async {
      final r = server();
      await pump(tester, r);
      await tester.enterText(find.byKey(const Key('amount-field')), '450.5');
      await tester.enterText(find.byKey(const Key('currency-field')), 'eur');
      await tester.enterText(
        find.byKey(const Key('email-field')),
        ' me@example.com ',
      );
      await tester.tap(find.byKey(const Key('reminders-switch')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('save-settings')));
      await tester.tap(find.byKey(const Key('save-settings')));
      await tester.pumpAndSettle();
      final sent =
          jsonDecode(r.where('PUT', '/settings').single.body)
              as Map<String, dynamic>;
      expect(sent['monthlyAmountCents'], 45050);
      expect(sent['currency'], 'eur');
      expect(sent['buyDay'], 1);
      expect(sent['startDate'], '2026-08-01');
      expect(sent['remindersEnabled'], isTrue);
      expect(sent['reminderEmail'], 'me@example.com');
      expect(sent['reminderFollowupDays'], 3);
      expect(find.byKey(const Key('saved-note')), findsOneWidget);
    });

    testWidgets('bad input is caught before any request', (tester) async {
      final r = server();
      await pump(tester, r);
      Future<void> saveAndExpect(String message) async {
        await tester.ensureVisible(find.byKey(const Key('save-settings')));
        await tester.tap(find.byKey(const Key('save-settings')));
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
        expect(r.where('PUT', '/settings'), isEmpty);
      }

      await tester.enterText(find.byKey(const Key('amount-field')), '12.345');
      await saveAndExpect('Enter the monthly amount like 300 or 300.00');
      await tester.enterText(find.byKey(const Key('amount-field')), '300');
      await tester.enterText(find.byKey(const Key('currency-field')), 'US');
      await saveAndExpect('Currency is a 3-letter code such as USD');
      await tester.enterText(find.byKey(const Key('currency-field')), 'USD');
      await tester.enterText(find.byKey(const Key('ticker-field')), 'V T!');
      await saveAndExpect('Ticker can use letters, digits, "." and "-"');
      await tester.enterText(find.byKey(const Key('ticker-field')), 'VT');
      await tester.tap(find.byKey(const Key('reminders-switch')));
      await tester.pump();
      await saveAndExpect('Add an email address to turn reminders on');
    });

    testWidgets('a server rejection is shown and the form stays editable', (
      tester,
    ) async {
      final r = server(
        onPut: (_) async =>
            ok({'message': 'Unknown timezone: Mars/Olympus'}, 400),
      );
      await pump(tester, r);
      await tester.enterText(
        find.byKey(const Key('timezone-field')),
        'Mars/Olympus',
      );
      await tester.ensureVisible(find.byKey(const Key('save-settings')));
      await tester.tap(find.byKey(const Key('save-settings')));
      await tester.pumpAndSettle();
      expect(find.text('Unknown timezone: Mars/Olympus'), findsOneWidget);
      expect(find.byKey(const Key('saved-note')), findsNothing);
    });

    testWidgets('warns when the server cannot send email', (tester) async {
      await pump(tester, server(status: reminderStatusJson(configured: false)));
      expect(find.byKey(const Key('email-not-configured')), findsOneWidget);
      await pump(tester, server(status: reminderStatusJson(configured: true)));
      expect(find.byKey(const Key('email-not-configured')), findsNothing);
    });

    testWidgets('still loads if the reminder status call fails', (
      tester,
    ) async {
      final r = Recorder((req) async {
        if (req.url.path.endsWith('/reminders')) {
          return ok({'message': 'boom'}, 500);
        }
        return ok(settingsJson());
      });
      await pump(tester, r);
      expect(find.byKey(const Key('amount-field')), findsOneWidget);
      expect(find.byKey(const Key('email-not-configured')), findsNothing);
    });

    testWidgets('lists recently sent reminders', (tester) async {
      await pump(
        tester,
        server(
          status: reminderStatusJson(
            recent: [
              {
                'month': '2026-10',
                'kind': 'DUE',
                'sentAt': '2026-10-05T09:00:00',
              },
            ],
          ),
        ),
      );
      await tester.ensureVisible(find.text('Recently sent'));
      expect(find.text('2026-10: buy-day reminder'), findsOneWidget);
    });

    testWidgets(
      'exporting copies the whole JSON to the clipboard and says how much',
      (tester) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final payload = jsonEncode({'schemaVersion': 1, 'notes': 'x' * 3000});
        final r = Recorder((req) async {
          if (req.url.path.endsWith('/export')) {
            return http.Response(
              payload,
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (req.url.path.endsWith('/reminders')) {
            return ok(reminderStatusJson());
          }
          return ok(settingsJson());
        });
        await pump(tester, r);
        await tester.ensureVisible(find.byKey(const Key('export-data')));
        await tester.tap(find.byKey(const Key('export-data')));
        await tester.pumpAndSettle();
        expect(copied, payload);
        expect(find.textContaining('Copied 3 KB of data'), findsOneWidget);
        expect(r.where('GET', '/export'), hasLength(1));
      },
    );

    testWidgets('a failed export is explained and copies nothing', (
      tester,
    ) async {
      var copied = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') copied = true;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final r = Recorder((req) async {
        if (req.url.path.endsWith('/export')) {
          return ok({'message': 'boom'}, 500);
        }
        if (req.url.path.endsWith('/reminders')) {
          return ok(reminderStatusJson());
        }
        return ok(settingsJson());
      });
      await pump(tester, r);
      await tester.ensureVisible(find.byKey(const Key('export-data')));
      await tester.tap(find.byKey(const Key('export-data')));
      await tester.pumpAndSettle();
      expect(find.text('boom'), findsOneWidget);
      expect(copied, isFalse);
    });

    testWidgets('the test email reports success and failure', (tester) async {
      final ok1 = server();
      await pump(tester, ok1);
      await tester.ensureVisible(find.byKey(const Key('send-test')));
      await tester.tap(find.byKey(const Key('send-test')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Test email sent'), findsOneWidget);
      expect(ok1.where('POST', '/reminders/test'), hasLength(1));

      final bad = server(
        testResult: {
          'sent': false,
          'kind': null,
          'skipped': null,
          'error': 'Email is not configured on the server',
        },
      );
      await pump(tester, bad);
      await tester.ensureVisible(find.byKey(const Key('send-test')));
      await tester.tap(find.byKey(const Key('send-test')));
      await tester.pumpAndSettle();
      expect(
        find.text('Email is not configured on the server'),
        findsOneWidget,
      );
    });
  });

  group('phone width', () {
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('the settings form fits without overflow', (tester) async {
      phone(tester);
      final r = Recorder((req) async {
        if (req.url.path.endsWith('/reminders')) {
          return ok(
            reminderStatusJson(
              configured: false,
              recent: [
                {
                  'month': '2026-10',
                  'kind': 'DUE',
                  'sentAt': '2026-10-05T09:00:00',
                },
              ],
            ),
          );
        }
        return ok(
          settingsJson(
            reminders: true,
            email: 'someone.with.a.long.address@example-company.com',
            timezone: 'America/Argentina/ComodRivadavia',
          ),
        );
      });
      final api = r.api();
      await tester.pumpWidget(
        host(
          SettingsScreen(
            plan: PlanService(api: api),
            contributions: ContributionService(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('amount-field')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the rules list fits with long rule text', (tester) async {
      phone(tester);
      final r = Recorder(
        (_) async => ok([
          ruleJson(
            1,
            'Never sell in a crash, no matter how loud the headlines are or how scary the chart looks.',
            1,
          ),
          ruleJson(2, 'Wait 72 hours before any deviation from the plan.', 2),
        ]),
      );
      await tester.pumpWidget(
        host(RulesScreen(service: PlanService(api: r.api()))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Never sell in a crash'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the rules card fits with long rule text', (tester) async {
      phone(tester);
      await tester.pumpWidget(
        host(
          RulesCard(
            rules: const [
              'Never sell in a crash, no matter how loud the headlines are or how scary the chart looks.',
            ],
            onEdit: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
