import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tm_dashboard/enums/trade_direction_enum.dart';
import 'package:tm_dashboard/models/asset_model.dart';
import 'package:tm_dashboard/models/trade_model.dart';
import 'package:tm_dashboard/screens/trade_journal/classes/trade_journal.dart';
import 'package:tm_dashboard/screens/trade_journal/journal_card.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

void main() {
  testWidgets('group builds trade details in batches', (tester) async {
    final entry = DateTime(2026, 1, 1);
    final asset = Asset(id: '1', name: 'Euro Dollar', symbol: 'EURUSD');
    final group = TradeGroup(
      label: 'Test group',
      sortKey: entry,
      trades: List.generate(
        45,
        (index) => Trade(
          id: index,
          entryDateTime: entry,
          exitDateTime: entry,
          asset: asset,
          direction: TradeDirectionEnum.LONG,
          entryPrice: index.toDouble(),
          exitPrice: 2,
          lot: 1,
          pips: 1,
          profit: 1,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: TradeGroupCard(group: group)),
        ),
      ),
    );

    expect(find.text('Entry 0.0 → Exit 2.0'), findsNothing);
    await tester.tap(find.text('Test group'));
    await tester.pumpAndSettle();

    expect(find.text('Entry 19.0 → Exit 2.0'), findsOneWidget);
    expect(find.text('Entry 20.0 → Exit 2.0'), findsNothing);
    expect(find.text('Show more (25 remaining)'), findsOneWidget);
  });
}
