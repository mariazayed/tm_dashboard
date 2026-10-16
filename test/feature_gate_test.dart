import 'package:flutter_test/flutter_test.dart';
import 'package:tm_dashboard/configs/feature_gate.dart';
import 'package:tm_dashboard/enums/decision_category_enum.dart';
import 'package:tm_dashboard/enums/goal_category_enum.dart';

void main() {
  group('tradingRedirect (trading off)', () {
    String? r(String p) => tradingRedirect(p, tradingEnabled: false);

    test('home goes to the investing home', () {
      expect(r('/'), '/invest');
    });

    test('every trading path is redirected, including sub-paths', () {
      for (final p in tradingPaths) {
        expect(r(p), '/invest', reason: p);
        expect(r('$p/'), '/invest', reason: '$p/');
        expect(r('$p/anything'), '/invest', reason: '$p/anything');
      }
    });

    test('investing and shared pages are left alone', () {
      for (final p in [
        '/invest',
        '/invest/contributions',
        '/invest/settings',
        '/goals',
        '/decisions',
        '/planner',
        '/questions-answers',
        '/reminder-notes',
      ]) {
        expect(r(p), isNull, reason: p);
      }
      expect(r('/expenses'), '/invest');
      expect(r('/expense-reasons'), '/invest');
    });

    test('a path that merely starts with a trading word is not caught', () {
      expect(r('/trades-extra'), isNull);
    });
  });

  test('nothing is redirected when trading is on', () {
    for (final p in ['/', ...tradingPaths]) {
      expect(tradingRedirect(p, tradingEnabled: true), isNull, reason: p);
    }
  });

  group('categories', () {
    test('only MANUAL goals without trading', () {
      expect(goalCategoriesFor(tradingEnabled: false), [GoalCategoryEnum.MANUAL]);
      expect(goalCategoriesFor(tradingEnabled: true), GoalCategoryEnum.values);
    });

    test('TRADING decisions hidden, INVESTING kept', () {
      final off = decisionCategoriesFor(tradingEnabled: false);
      expect(off, isNot(contains(DecisionCategoryEnum.TRADING)));
      expect(off, contains(DecisionCategoryEnum.INVESTING));
      expect(
        decisionCategoriesFor(tradingEnabled: true),
        DecisionCategoryEnum.values,
      );
    });
  });
}
