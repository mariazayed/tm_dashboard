import 'package:flutter_test/flutter_test.dart';
import 'package:tm_dashboard/enums/trade_direction_enum.dart';
import 'package:tm_dashboard/models/asset_model.dart';
import 'package:tm_dashboard/services/trade_calculator_service.dart';

void main() {
  group('TradeCalculatorService.calculatePips', () {
    test('uses the selected asset pip size for long trades', () {
      final asset = Asset(
        id: '1',
        name: 'Euro Dollar',
        symbol: 'EURUSD',
        pipSize: 0.0001,
      );

      final pips = TradeCalculatorService.calculatePips(
        asset: asset,
        direction: TradeDirectionEnum.LONG,
        entry: 1.1000,
        exit: 1.1100,
      );

      expect(pips, closeTo(100, 0.0001));
    });

    test('flips sign for short trades', () {
      final asset = Asset(
        id: '1',
        name: 'Euro Dollar',
        symbol: 'EURUSD',
        pipSize: 0.0001,
      );

      final pips = TradeCalculatorService.calculatePips(
        asset: asset,
        direction: TradeDirectionEnum.SHORT,
        entry: 1.1000,
        exit: 1.0990,
      );

      expect(pips, closeTo(10, 0.0001));
    });

    test('returns zero when the asset has no pip size', () {
      final asset = Asset(id: '1', name: 'Unconfigured', symbol: 'TEST');

      final pips = TradeCalculatorService.calculatePips(
        asset: asset,
        direction: TradeDirectionEnum.LONG,
        entry: 10,
        exit: 11,
      );

      expect(pips, 0);
    });
  });
}
