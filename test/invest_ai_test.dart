import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/plan_model.dart';
import 'package:tm_dashboard/screens/invest/ai_context_dialog.dart';
import 'package:tm_dashboard/screens/invest/settings_screen.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

Map<String, dynamic> previewJson({
  String text = '# Owner context\n- Invests \$300.00 per month into VT',
  int characters = 49,
  bool truncated = false,
  bool journal = true,
  bool notes = true,
}) => {
  'generatedAt': '2026-10-06T12:00:00Z',
  'includeJournal': journal,
  'includeNotes': notes,
  'truncated': truncated,
  'characters': characters,
  'maxCharacters': 12000,
  'text': text,
};

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

class Recorder {
  Recorder(this.handler);

  final Future<http.Response> Function(http.Request) handler;
  final requests = <http.Request>[];

  Iterable<http.Request> get contextCalls =>
      requests.where((r) => r.url.path.endsWith('/ai/context'));

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

Map<String, dynamic> settingsJson() => {
  'monthlyAmountCents': 30000,
  'currency': 'USD',
  'buyDay': 1,
  'ticker': 'VT',
  'startDate': '2026-08-01',
  'timezone': 'UTC',
  'remindersEnabled': false,
  'reminderEmail': null,
  'reminderFollowupDays': 3,
};

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('models and service', () {
    test('status and preview parse', () {
      final ready = AiStatusModel.fromJson({
        'configured': true,
        'model': 'claude-x',
        'reason': null,
      });
      expect(ready.configured, isTrue);
      expect(ready.model, 'claude-x');
      final missing = AiStatusModel.fromJson({
        'configured': false,
        'model': null,
        'reason': 'Set ai.provider.api-key on the server',
      });
      expect(missing.reason, contains('api-key'));

      final preview = AiContextPreview.fromJson(
        previewJson(truncated: true, journal: false),
      );
      expect(preview.truncated, isTrue);
      expect(preview.includeJournal, isFalse);
      expect(preview.maxCharacters, 12000);
    });

    test('the context call carries both privacy switches', () async {
      final r = Recorder((_) async => ok(previewJson()));
      final service = PlanService(api: r.api());
      await service.aiContext();
      expect(r.contextCalls.last.url.queryParameters, {
        'includeJournal': 'true',
        'includeNotes': 'true',
      });
      await service.aiContext(includeJournal: false, includeNotes: false);
      expect(r.contextCalls.last.url.queryParameters, {
        'includeJournal': 'false',
        'includeNotes': 'false',
      });
    });

    test('status goes to the status route', () async {
      final r = Recorder(
        (_) async => ok({'configured': false, 'model': null, 'reason': 'x'}),
      );
      await PlanService(api: r.api()).aiStatus();
      expect(r.requests.single.url.path, '/api/v1/invest/ai/status');
    });
  });

  group('AiContextDialog', () {
    Future<Recorder> open(WidgetTester tester, Recorder r) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(AiContextDialog(service: PlanService(api: r.api()))),
      );
      await tester.pumpAndSettle();
      return r;
    }

    testWidgets('shows the exact text and how much of the limit it uses', (
      tester,
    ) async {
      await open(
        tester,
        Recorder((_) async => ok(previewJson(characters: 49))),
      );
      expect(find.byKey(const Key('context-text')), findsOneWidget);
      expect(
        find.textContaining('Invests \$300.00 per month into VT'),
        findsOneWidget,
      );
      expect(find.text('49 of 12000 characters'), findsOneWidget);
      expect(
        find.textContaining('reminder email and login details are never'),
        findsOneWidget,
      );
    });

    testWidgets('says when older entries were left out', (tester) async {
      await open(
        tester,
        Recorder(
          (_) async => ok(previewJson(characters: 11990, truncated: true)),
        ),
      );
      expect(
        find.text('11990 of 12000 characters (older entries were left out)'),
        findsOneWidget,
      );
    });

    testWidgets(
      'each privacy switch asks the server again with the new setting',
      (tester) async {
        final r = await open(
          tester,
          Recorder((req) async {
            final q = req.url.queryParameters;
            final journal = q['includeJournal'] == 'true';
            final notes = q['includeNotes'] == 'true';
            return ok(
              previewJson(
                text:
                    '${journal ? 'JOURNAL TEXT ' : ''}${notes ? 'NOTES TEXT' : ''}numbers only',
                journal: journal,
                notes: notes,
              ),
            );
          }),
        );
        expect(find.textContaining('JOURNAL TEXT'), findsOneWidget);

        await tester.tap(find.byKey(const Key('include-journal')));
        await tester.pumpAndSettle();
        expect(
          r.contextCalls.last.url.queryParameters['includeJournal'],
          'false',
        );
        expect(r.contextCalls.last.url.queryParameters['includeNotes'], 'true');
        expect(find.textContaining('JOURNAL TEXT'), findsNothing);
        expect(find.textContaining('NOTES TEXT'), findsOneWidget);

        await tester.tap(find.byKey(const Key('include-notes')));
        await tester.pumpAndSettle();
        expect(r.contextCalls.last.url.queryParameters, {
          'includeJournal': 'false',
          'includeNotes': 'false',
        });
        expect(find.textContaining('NOTES TEXT'), findsNothing);
        expect(find.textContaining('numbers only'), findsOneWidget);
      },
    );

    testWidgets('a slow answer for old switches cannot overwrite a newer one', (
      tester,
    ) async {
      final slow = Completer<http.Response>();
      var calls = 0;
      final r = Recorder((req) {
        calls++;
        if (calls == 2) {
          return slow.future; // the first toggle's answer arrives late
        }
        final journal = req.url.queryParameters['includeJournal'] == 'true';
        return Future.value(
          ok(
            previewJson(
              text: journal ? 'WITH JOURNAL' : 'WITHOUT JOURNAL',
              journal: journal,
            ),
          ),
        );
      });
      await open(tester, r);
      await tester.tap(
        find.byKey(const Key('include-journal')),
      ); // call 2: slow, journal=false
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('include-journal')),
      ); // call 3: journal=true again, fast
      await tester.pumpAndSettle();
      expect(find.textContaining('WITH JOURNAL'), findsOneWidget);

      slow.complete(ok(previewJson(text: 'WITHOUT JOURNAL', journal: false)));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('WITHOUT JOURNAL'),
        findsNothing,
      ); // stale answer ignored
      expect(find.textContaining('WITH JOURNAL'), findsOneWidget);
    });

    testWidgets('a failure is shown instead of a crash', (tester) async {
      await open(tester, Recorder((_) async => ok({'message': 'boom'}, 500)));
      expect(find.byKey(const Key('context-error')), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
    });
  });

  group('settings: AI section', () {
    Future<void> pump(
      WidgetTester tester,
      Map<String, dynamic>? status, {
      int statusCode = 200,
    }) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final r = Recorder((req) async {
        final path = req.url.path;
        if (path.endsWith('/ai/status')) {
          return statusCode == 200
              ? ok(status!)
              : http.Response('', statusCode);
        }
        if (path.endsWith('/ai/context')) return ok(previewJson());
        if (path.endsWith('/reminders')) {
          return ok({'emailConfigured': true, 'recent': []});
        }
        return ok(settingsJson());
      });
      final api = r.api();
      await tester.pumpWidget(const SizedBox());
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

    testWidgets(
      'a configured server shows the model and that nothing is sent until you ask',
      (tester) async {
        await pump(tester, {
          'configured': true,
          'model': 'claude-x',
          'reason': null,
        });
        final text = tester
            .widget<Text>(find.byKey(const Key('ai-status')))
            .data!;
        expect(text, contains('model claude-x'));
        expect(text, contains('Nothing about you is sent until you ask'));
        expect(text, isNot(contains('sk-')));
      },
    );

    testWidgets('an unconfigured server says what is missing', (tester) async {
      await pump(tester, {
        'configured': false,
        'model': null,
        'reason': 'Set ai.provider.api-key and ai.provider.model on the server',
      });
      final text = tester
          .widget<Text>(find.byKey(const Key('ai-status')))
          .data!;
      expect(text, contains('Not set up'));
      expect(text, contains('ai.provider.api-key and ai.provider.model'));
    });

    testWidgets(
      'an unreachable status call degrades to a plain message and the page still works',
      (tester) async {
        await pump(tester, null, statusCode: 500);
        expect(
          find.text('AI status is unavailable right now.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('amount-field')), findsOneWidget);
      },
    );

    testWidgets('the button opens the preview', (tester) async {
      await pump(tester, {'configured': false, 'model': null, 'reason': 'x'});
      await tester.ensureVisible(find.byKey(const Key('preview-ai-context')));
      await tester.tap(find.byKey(const Key('preview-ai-context')));
      await tester.pumpAndSettle();
      expect(find.text('What an AI would see'), findsOneWidget);
      expect(find.byKey(const Key('context-text')), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('What an AI would see'), findsNothing);
    });
  });
}
