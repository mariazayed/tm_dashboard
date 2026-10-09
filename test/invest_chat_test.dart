import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/ai_chat_model.dart';
import 'package:tm_dashboard/screens/invest/ai_chat_screen.dart';
import 'package:tm_dashboard/services/ai_chat_service.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> sourceJson({
  String handle = 'J12',
  String type = 'JOURNAL',
  int id = 12,
  String date = '2026-03-04',
  String snippet = 'I was scared when the market dropped.',
}) => {
  'handle': handle,
  'type': type,
  'id': id,
  'date': date,
  'snippet': snippet,
};

Map<String, dynamic> answerJson({
  String answer = 'You felt scared [J12].',
  List<Map<String, dynamic>>? sources,
  bool cutOff = false,
  bool truncated = false,
  String? refusal,
}) => {
  'answer': answer,
  'sources': sources ?? [sourceJson()],
  'usedJournal': true,
  'usedNotes': true,
  'truncated': truncated,
  'cutOff': cutOff,
  'model': 'claude-test',
  'refusal': refusal,
};

Map<String, dynamic> usageJson({int calls = 3}) => {
  'date': '2026-10-06',
  'callsToday': calls,
  'dailyLimit': 60,
  'perMinuteLimit': 6,
  'inputTokens': 1200,
  'outputTokens': 300,
  'callsByFeature': {'CHAT': calls},
};

Map<String, dynamic> previewJson({String text = 'PROMPT TEXT'}) => {
  'generatedAt': '2026-10-06T12:00:00Z',
  'includeJournal': true,
  'includeNotes': true,
  'truncated': false,
  'characters': 4321,
  'maxCharacters': 20000,
  'text': text,
  'feature': 'chat',
  'systemPrompt': 'STANDING INSTRUCTIONS',
  'snippets': 2,
};

/// A server stand-in that records every request.
class Server {
  Server({
    this.configured = true,
    this.reason,
    Future<http.Response> Function(http.Request)? chat,
  }) : chatHandler = chat ?? ((_) async => ok(answerJson()));

  bool configured;
  String? reason;
  Future<http.Response> Function(http.Request) chatHandler;
  int calls = 3;
  final requests = <http.Request>[];

  Iterable<http.Request> get chats =>
      requests.where((r) => r.url.path.endsWith('/ai/chat'));

  Map<String, dynamic> body(http.Request r) =>
      jsonDecode(r.body) as Map<String, dynamic>;

  ApiClient api() {
    final api = ApiClient(
      client: MockClient((req) async {
        requests.add(req);
        final path = req.url.path;
        if (path.endsWith('/ai/status')) {
          return ok({
            'configured': configured,
            'model': configured ? 'claude-test' : null,
            'reason': reason,
          });
        }
        if (path.endsWith('/ai/usage')) return ok(usageJson(calls: calls));
        if (path.endsWith('/ai/context')) return ok(previewJson());
        if (path.endsWith('/ai/chat')) {
          final response = await chatHandler(req);
          if (response.statusCode == 200) calls++;
          return response;
        }
        return http.Response('not found', 404);
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

void main() {
  group('history for the server', () {
    ChatTurn user(String t) => ChatTurn(assistant: false, text: t);
    ChatTurn bot(String t) => ChatTurn(assistant: true, text: t);

    test('keeps the newest six messages and drops empty ones', () {
      final turns = [for (var i = 0; i < 9; i++) user('m$i'), user('  ')];
      expect(ChatHistory.build(turns).map((t) => t.text), [
        'm3',
        'm4',
        'm5',
        'm6',
        'm7',
        'm8',
      ]);
    });

    test('clips each message to 2000 characters', () {
      final out = ChatHistory.build([bot('x' * 2500)]);
      expect(out.single.text.length, 2000);
    });

    test('does not split a surrogate pair when clipping', () {
      final text = '${'a' * 1999}\u{1F600}${'b' * 10}';
      final out = ChatHistory.build([user(text)]).single.text;
      expect(out.length, 1999);
      expect(out.codeUnits.last, isNot(inInclusiveRange(0xD800, 0xDBFF)));
    });

    test('drops the oldest messages until the total fits 6000', () {
      final turns = [for (var i = 0; i < 4; i++) user('${i}x' * 1000)];
      final out = ChatHistory.build(turns);
      expect(out.length, 3); // four of 2,000 characters is 8,000
      expect(out.first.text.startsWith('0x'), isFalse);
      expect(
        out.fold<int>(0, (s, t) => s + t.text.length),
        lessThanOrEqualTo(ChatHistory.maxTotalChars),
      );
    });

    test('turns serialise as the server expects', () {
      expect(user('hi').toJson(), {'role': 'user', 'text': 'hi'});
      expect(bot('yo').toJson(), {'role': 'assistant', 'text': 'yo'});
    });
  });

  group('service', () {
    test('chat posts the question, history and switches', () async {
      final s = Server();
      final answer = await AiChatService(api: s.api()).chat(
        question: 'How did I feel?',
        history: const [ChatTurn(assistant: false, text: 'earlier')],
        includeJournal: false,
        includeNotes: true,
      );
      final req = s.chats.single;
      expect(req.method, 'POST');
      expect(req.headers['Content-Type'], contains('application/json'));
      expect(s.body(req), {
        'question': 'How did I feel?',
        'history': [
          {'role': 'user', 'text': 'earlier'},
        ],
        'includeJournal': false,
        'includeNotes': true,
      });
      expect(answer.answer, 'You felt scared [J12].');
      expect(answer.sources.single.handle, 'J12');
      expect(answer.sources.single.isJournal, isTrue);
      expect(answer.refused, isFalse);
      expect(answer.model, 'claude-test');
    });

    test('a refusal and the flags parse', () async {
      final s = Server(
        chat: (_) async => ok(
          answerJson(
            refusal: 'ADVICE',
            sources: [],
            cutOff: true,
            truncated: true,
          ),
        ),
      );
      final a = await AiChatService(api: s.api()).chat(question: 'q');
      expect(a.refused, isTrue);
      expect(a.refusal, 'ADVICE');
      expect(a.cutOff, isTrue);
      expect(a.truncated, isTrue);
      expect(a.sources, isEmpty);
    });

    test('server errors keep their message and status', () async {
      for (final entry in {
        503: 'AI is switched off. Set ai.enabled=true on the server',
        429: 'The daily AI limit (60 calls) is used up.',
        502: 'The AI service did not answer. Try again in a moment.',
        400: 'The question is too long',
      }.entries) {
        final s = Server(
          chat: (_) async => ok({'message': entry.value}, entry.key),
        );
        await expectLater(
          AiChatService(api: s.api()).chat(question: 'q'),
          throwsA(
            isA<InvestApiException>()
                .having((e) => e.statusCode, 'status', entry.key)
                .having((e) => e.message, 'message', entry.value),
          ),
        );
      }
    });

    test('usage parses and counts what is left', () async {
      final usage = await AiChatService(api: Server().api()).usage();
      expect(usage.callsToday, 3);
      expect(usage.dailyLimit, 60);
      expect(usage.remaining, 57);
    });

    test('a chat preview asks for the chat prompt of that question', () async {
      final s = Server();
      final preview = await PlanService(
        api: s.api(),
      ).aiContext(question: 'How did I feel?', includeJournal: false);
      final q = s.requests.last.url.queryParameters;
      expect(q['feature'], 'chat');
      expect(q['q'], 'How did I feel?');
      expect(q['includeJournal'], 'false');
      expect(preview.feature, 'chat');
      expect(preview.systemPrompt, 'STANDING INSTRUCTIONS');
      expect(preview.snippets, 2);
    });
  });

  group('screen', () {
    Future<Server> open(
      WidgetTester tester, {
      Server? server,
      void Function(BuildContext, ChatSource)? onOpenSource,
    }) async {
      final s = server ?? Server();
      final api = s.api();
      await tester.pumpWidget(
        host(
          AiChatScreen(
            service: AiChatService(api: api),
            planService: PlanService(api: api),
            onOpenSource: onOpenSource,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return s;
    }

    Future<void> ask(WidgetTester tester, String question) async {
      await tester.enterText(find.byKey(const Key('chat-input')), question);
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
    }

    testWidgets('always shows that AI can be wrong and the usage so far', (
      tester,
    ) async {
      await open(tester);
      expect(
        find.text('AI can be wrong. It does not give financial advice.'),
        findsOneWidget,
      );
      expect(find.text('Today: 3 of 60 AI calls used.'), findsOneWidget);
    });

    testWidgets('when AI is not ready it says why and cannot be used', (
      tester,
    ) async {
      final s = await open(
        tester,
        server: Server(
          configured: false,
          reason: 'AI is switched off. Set ai.enabled=true on the server',
        ),
      );
      expect(find.byKey(const Key('chat-unavailable')), findsOneWidget);
      expect(find.textContaining('Set ai.enabled=true'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('chat-input'))).enabled,
        isFalse,
      );
      expect(
        tester.widget<IconButton>(find.byKey(const Key('chat-send'))).onPressed,
        isNull,
      );
      expect(
        s.requests.where((r) => r.url.path.endsWith('/ai/usage')),
        isEmpty,
        reason: 'no point asking for usage when AI is off',
      );
    });

    testWidgets('a failed status call offers a retry', (tester) async {
      var fail = true;
      final api = ApiClient(
        client: MockClient((req) async {
          if (fail) return http.Response('boom', 500);
          return ok({'configured': true, 'model': 'm', 'reason': null});
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        host(
          AiChatScreen(
            service: AiChatService(api: api),
            planService: PlanService(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-load-error')), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-input')), findsOneWidget);
    });

    testWidgets('send is off until there is a question', (tester) async {
      await open(tester);
      IconButton send() =>
          tester.widget<IconButton>(find.byKey(const Key('chat-send')));
      expect(send().onPressed, isNull);
      await tester.enterText(find.byKey(const Key('chat-input')), '   ');
      await tester.pump();
      expect(send().onPressed, isNull);
      await tester.enterText(find.byKey(const Key('chat-input')), 'hi');
      await tester.pump();
      expect(send().onPressed, isNotNull);
    });

    testWidgets('shows the question, the answer and a chip per source', (
      tester,
    ) async {
      final s = await open(
        tester,
        server: Server(
          chat: (_) async => ok(
            answerJson(
              answer: 'Scared [J12], and you read about it [N7].',
              sources: [
                sourceJson(),
                sourceJson(
                  handle: 'N7',
                  type: 'NOTE',
                  id: 7,
                  date: '2026-02-01',
                  snippet: 'Low fees matter.',
                ),
              ],
            ),
          ),
        ),
      );
      await ask(tester, 'How did I feel?');
      expect(find.text('How did I feel?'), findsOneWidget);
      expect(
        find.text('Scared [J12], and you read about it [N7].'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('source-J12')), findsOneWidget);
      expect(find.byKey(const Key('source-N7')), findsOneWidget);
      expect(find.text('J12 · Mar 4'), findsOneWidget);
      expect(find.text('N7 · Feb 1'), findsOneWidget);
      expect(s.chats.length, 1);
      expect(
        tester.widget<TextField>(find.byKey(const Key('chat-input'))).enabled,
        isTrue,
      );
      expect(find.text('Today: 4 of 60 AI calls used.'), findsOneWidget);
    });

    testWidgets('the privacy switches are sent and start on', (tester) async {
      final s = await open(tester);
      await tester.tap(find.byKey(const Key('chat-privacy-journal')));
      await tester.pump();
      await ask(tester, 'q');
      expect(s.body(s.chats.single)['includeJournal'], false);
      expect(s.body(s.chats.single)['includeNotes'], true);
    });

    testWidgets('a follow-up carries the earlier turns', (tester) async {
      final s = await open(
        tester,
        server: Server(
          chat: (_) async => ok(answerJson(answer: 'Calm [J12].')),
        ),
      );
      await ask(tester, 'first');
      await ask(tester, 'and later?');
      expect(s.body(s.chats.first)['history'], isEmpty);
      expect(s.body(s.chats.last)['history'], [
        {'role': 'user', 'text': 'first'},
        {'role': 'assistant', 'text': 'Calm [J12].'},
      ]);
    });

    testWidgets('a refused answer is shown but never sent back', (
      tester,
    ) async {
      var n = 0;
      final s = await open(
        tester,
        server: Server(
          chat: (_) async {
            n++;
            return n == 1
                ? ok(
                    answerJson(
                      answer: 'I can not tell you what to buy.',
                      refusal: 'ADVICE',
                      sources: [],
                    ),
                  )
                : ok(answerJson());
          },
        ),
      );
      await ask(tester, 'Should I sell?');
      expect(find.text('I can not tell you what to buy.'), findsOneWidget);
      expect(find.text('This answer was replaced, not shown.'), findsOneWidget);
      await ask(tester, 'How did I feel?');
      expect(
        s.body(s.chats.last)['history'],
        isEmpty,
        reason: 'neither the refusal nor the question that caused it',
      );
    });

    testWidgets('notes when an answer was cut short or material was left out', (
      tester,
    ) async {
      await open(
        tester,
        server: Server(
          chat: (_) async => ok(answerJson(cutOff: true, truncated: true)),
        ),
      );
      await ask(tester, 'q');
      expect(
        find.text('The answer was cut short. Ask a narrower question.'),
        findsOneWidget,
      );
      expect(
        find.text('Some older material was left out to fit the size limit.'),
        findsOneWidget,
      );
    });

    testWidgets('an error shows its message and gives the question back', (
      tester,
    ) async {
      var fail = true;
      final s = await open(
        tester,
        server: Server(
          chat: (_) async => fail
              ? ok({
                  'message': 'The daily AI limit (60 calls) is used up.',
                }, 429)
              : ok(answerJson()),
        ),
      );
      await ask(tester, 'How did I feel?');
      expect(
        find.text('The daily AI limit (60 calls) is used up.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('question')), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-input')))
            .controller!
            .text,
        'How did I feel?',
      );

      fail = false;
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-error')), findsNothing);
      expect(find.byKey(const Key('answer')), findsOneWidget);
      expect(s.chats.length, 2);
    });

    testWidgets('an unreachable server says so', (tester) async {
      await open(
        tester,
        server: Server(chat: (_) async => throw http.ClientException('down')),
      );
      await ask(tester, 'q');
      expect(find.text('Could not reach the server'), findsOneWidget);
    });

    testWidgets(
      'cancel stops waiting, restores the question and ignores a late answer',
      (tester) async {
        final late = Completer<http.Response>();
        await open(tester, server: Server(chat: (_) => late.future));
        await tester.enterText(find.byKey(const Key('chat-input')), 'slow one');
        await tester.pump();
        await tester.tap(find.byKey(const Key('chat-send')));
        await tester.pump();
        expect(find.byKey(const Key('chat-thinking')), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byKey(const Key('chat-input'))).enabled,
          isFalse,
        );

        await tester.tap(find.byKey(const Key('chat-cancel')));
        await tester.pump();
        expect(find.byKey(const Key('chat-thinking')), findsNothing);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('chat-input')))
              .controller!
              .text,
          'slow one',
        );

        late.complete(ok(answerJson(answer: 'TOO LATE')));
        await tester.pumpAndSettle();
        expect(find.text('TOO LATE'), findsNothing);
        expect(find.byKey(const Key('answer')), findsNothing);
      },
    );

    testWidgets(
      'new chat clears the conversation and the next question starts fresh',
      (tester) async {
        final s = await open(tester);
        await ask(tester, 'first');
        await tester.tap(find.byKey(const Key('chat-new')));
        await tester.pump();
        expect(find.byKey(const Key('answer')), findsNothing);
        await ask(tester, 'second');
        expect(s.body(s.chats.last)['history'], isEmpty);
      },
    );

    testWidgets('a source chip shows the excerpt and opens the right screen', (
      tester,
    ) async {
      ChatSource? opened;
      await open(tester, onOpenSource: (_, source) => opened = source);
      await ask(tester, 'q');
      await tester.tap(find.byKey(const Key('source-J12')));
      await tester.pumpAndSettle();
      expect(find.text('Journal entry · Mar 4, 2026'), findsOneWidget);
      expect(find.text('I was scared when the market dropped.'), findsWidgets);
      expect(find.text('Open journal'), findsOneWidget);

      await tester.tap(find.byKey(const Key('source-open')));
      await tester.pumpAndSettle();
      expect(opened?.handle, 'J12');
      expect(find.byKey(const Key('source-text')), findsNothing);
    });

    testWidgets('a note source is labelled as a learning note', (tester) async {
      await open(
        tester,
        server: Server(
          chat: (_) async => ok(
            answerJson(
              sources: [
                sourceJson(
                  handle: 'N7',
                  type: 'NOTE',
                  id: 7,
                  date: '2026-02-01',
                  snippet: 'Low fees matter.',
                ),
              ],
            ),
          ),
        ),
      );
      await ask(tester, 'q');
      await tester.tap(find.byKey(const Key('source-N7')));
      await tester.pumpAndSettle();
      expect(find.text('Learning note · Feb 1, 2026'), findsOneWidget);
      expect(find.text('Open learning'), findsOneWidget);
    });

    testWidgets(
      'see what will be sent previews the prompt for the typed question',
      (tester) async {
        final s = await open(tester);
        expect(
          tester
              .widget<TextButton>(find.byKey(const Key('chat-preview')))
              .onPressed,
          isNull,
          reason: 'nothing to preview until a question is typed',
        );
        await tester.tap(find.byKey(const Key('chat-privacy-notes')));
        await tester.enterText(
          find.byKey(const Key('chat-input')),
          'How did I feel?',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('chat-preview')));
        await tester.pumpAndSettle();

        final call = s.requests.lastWhere(
          (r) => r.url.path.endsWith('/ai/context'),
        );
        expect(call.url.queryParameters['feature'], 'chat');
        expect(call.url.queryParameters['q'], 'How did I feel?');
        expect(call.url.queryParameters['includeNotes'], 'false');
        expect(find.byKey(const Key('context-text')), findsOneWidget);
        expect(find.text('PROMPT TEXT'), findsOneWidget);
        expect(find.textContaining('4321 of 20000 characters'), findsOneWidget);
        expect(find.textContaining('2 pieces of your writing'), findsOneWidget);
        expect(find.byKey(const Key('context-system')), findsOneWidget);
        expect(
          s.chats,
          isEmpty,
          reason: 'a preview sends nothing to the model',
        );
      },
    );

    for (final width in [320.0, 390.0, 768.0]) {
      testWidgets(
        'fits a $width wide screen with a long answer and many chips',
        (tester) async {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await open(
            tester,
            server: Server(
              chat: (_) async => ok(
                answerJson(
                  answer:
                      'A very long answer with no breaks ${'word ' * 120}[J1]',
                  cutOff: true,
                  truncated: true,
                  sources: [
                    for (var i = 1; i <= 8; i++)
                      sourceJson(
                        handle: 'J$i',
                        id: i,
                        date: '2026-03-0${i + 1}',
                        snippet: 'Entry $i ${'text ' * 80}',
                      ),
                  ],
                ),
              ),
            ),
          );
          await ask(tester, 'A long question ${'why ' * 60}');
          expect(
            tester.takeException(),
            isNull,
            reason: 'no overflow at $width',
          );
          await tester.tap(find.byKey(const Key('source-J1')));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'dialog fits at $width',
          );
        },
      );
    }
  });
}
