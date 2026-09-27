import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/data_service.dart';
import 'package:tm_dashboard/services/static_data_service.dart';
import 'package:tm_dashboard/services/planner_service.dart';
import 'package:tm_dashboard/services/asset_service.dart';
import 'package:tm_dashboard/services/capital_service.dart';
import 'package:tm_dashboard/services/day_service.dart';
import 'package:tm_dashboard/services/decision_service.dart';
import 'package:tm_dashboard/services/expense_service.dart';
import 'package:tm_dashboard/services/expense_reason_service.dart';
import 'package:tm_dashboard/services/goal_service.dart';
import 'package:tm_dashboard/services/memoir_service.dart';
import 'package:tm_dashboard/services/question_answer_service.dart';
import 'package:tm_dashboard/services/question_category_service.dart';
import 'package:tm_dashboard/services/reminder_notes_service.dart';
import 'package:tm_dashboard/services/strategy_service.dart';
import 'package:tm_dashboard/services/strict_rules_service.dart';
import 'package:tm_dashboard/services/trade_service.dart';

void main() {
  test('all data services reuse reads and share write invalidation', () async {
    var requests = 0;
    await http.runWithClient(
      () async {
        ApiClient.shared.clear();
        final loaders = <Future<Object?> Function()>[
          () => AssetService.fetchAssets(),
          () => AssetService.fetchAssetsPaged(),
          () => CapitalService.getAll(),
          () => CapitalService.getAllPaged(),
          () => CapitalService.getDepositsAndWithdrawsPaged(),
          () => DayService().getAll(),
          () => DecisionService.getAll(),
          () => DecisionService.getAllPaged(),
          () => ExpenseService.fetchAll(),
          () => ExpenseService.fetchAllPaged(),
          () => ExpenseReasonService.fetchAll(),
          () => ExpenseReasonService.fetchAllPaged(),
          () => GoalService.getAll(),
          () => GoalService.getAllPaged(),
          () => MemoirService().getAll(),
          () => QuestionAnswerService.getAll(),
          () => QuestionAnswerService.getAllPaged(),
          () => QuestionCategoryService.getAll(),
          () => QuestionCategoryService.getAllPaged(),
          () => ReminderNotesService.getAll(),
          () => ReminderNotesService.getAllPaged(),
          () => StrategyService.getAll(),
          () => StrategyService.getAllPaged(),
          () => StrictRulesService.getAll(),
          () => StrictRulesService.getAllPaged(),
          () => TradeService.getAll(),
          () => TradeService.searchPage(page: 0),
          () => TradeService.getRecentForAnalytics(),
          () => TradeService.getForMonth(DateTime(2026, 9)),
          () => StaticDataService.getAll(),
          () => DataService().getAll(),
          () => PlannerService.getSettings(),
          () => PlannerService.getFocusAreas(),
        ];
        for (final load in loaders) {
          await load();
          final count = requests;
          await load();
          expect(
            requests,
            count,
            reason: 'Repeated service calls must hit cache',
          );
        }
        final first = await StaticDataService.getAll();
        expect(identical(first, await DataService().getAll()), isTrue);
        await TradeService.create([]);
        final before = requests;
        await CapitalService.getAllPaged();
        expect(requests, before + 1);
        expect(identical(first, await StaticDataService.getAll()), isFalse);
        ApiClient.shared.clear();
      },
      () => MockClient((request) async {
        requests++;
        if (request.url.path.endsWith('/search')) {
          return http.Response(
            jsonEncode({'status': 'success', 'data': [], 'last': true}),
            200,
          );
        }
        if (request.url.path.endsWith('/staticData') ||
            request.url.path.endsWith('/settings')) {
          return http.Response('{}', 200);
        }
        return http.Response('[]', 200);
      }),
    );
  });
}
