import '../../../models/trade_model.dart';

class TradeJournal {
  final DateTime entryDateTime;
  final DateTime exitDateTime;
  final List<TradeModel> trades;

  TradeJournal({
    required this.entryDateTime,
    required this.exitDateTime,
    required this.trades,
  });

  double get totalProfit =>
      trades.fold(0, (sum, t) => sum + t.profit);
}
