import 'package:flutter/material.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/asset_model.dart';
import '../../models/strategy_model.dart';
import '../../models/trade_model.dart';
import '../../services/asset_service.dart';
import '../../services/strategy_service.dart';
import '../../services/trade_service.dart';
import 'classes/trade_list_filters.dart';
import 'trade_row_tile.dart';

class TradeListScreen extends StatefulWidget {
  const TradeListScreen({super.key});

  @override
  State<TradeListScreen> createState() => _TradeListScreenState();
}

class _TradeListScreenState extends State<TradeListScreen> {
  late Future<void> _future;

  List<Trade> _trades = [];
  List<Asset> _assets = [];
  List<Strategy> _strategies = [];

  TradeListFilters _filters = const TradeListFilters();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Sequential awaits (not Future.wait) -- same pattern as
    // TradeJournalScreen._load(), and avoids Future.wait's generic type
    // inference having to find a common type across List<Trade>,
    // List<Asset> and List<Strategy>.
    _trades = await TradeService.getAll();
    _assets = await AssetService.fetchAssets();
    _strategies = await StrategyService.getAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _updateFilters(TradeListFilters Function(TradeListFilters) update) {
    setState(() {
      _filters = update(_filters);
    });
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() => _filters = const TradeListFilters());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load trades:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final filtered = _filters.apply(_trades);

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _filterCard(constraints.maxWidth),
                    const SizedBox(height: 16),
                    _summaryRow(filtered),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            _trades.isEmpty
                                ? 'No trades yet'
                                : 'No trades match your filters',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      ...filtered.map((t) => TradeRowTile(trade: t)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- FILTER BAR ----------------

  Widget _filterCard(double maxWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by asset, strategy or notes...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => _updateFilters((f) => f.copyWith(searchText: v)),
                ),
              ),
              if (_filters.isActive) ...[
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear filters'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _assetDropdown(),
              _strategyDropdown(),
              _directionDropdown(),
              _resultDropdown(),
              _reviewDropdown(),
              _dateRangePicker(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assetDropdown() {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<Asset?>(
        initialValue: _filters.asset,
        isExpanded: true,
        decoration: _fieldDecoration('Asset'),
        items: [
          const DropdownMenuItem<Asset?>(value: null, child: Text('All assets')),
          ..._assets.map(
            (a) => DropdownMenuItem<Asset?>(value: a, child: Text(a.symbol)),
          ),
        ],
        onChanged: (v) => _updateFilters(
          (f) => f.copyWith(asset: v, clearAsset: v == null),
        ),
      ),
    );
  }

  Widget _strategyDropdown() {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<Strategy?>(
        initialValue: _filters.strategy,
        isExpanded: true,
        decoration: _fieldDecoration('Strategy'),
        items: [
          const DropdownMenuItem<Strategy?>(value: null, child: Text('All strategies')),
          ..._strategies.map(
            (s) => DropdownMenuItem<Strategy?>(value: s, child: Text(s.name)),
          ),
        ],
        onChanged: (v) => _updateFilters(
          (f) => f.copyWith(strategy: v, clearStrategy: v == null),
        ),
      ),
    );
  }

  Widget _directionDropdown() {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<TradeDirectionEnum?>(
        initialValue: _filters.direction,
        isExpanded: true,
        decoration: _fieldDecoration('Direction'),
        items: [
          const DropdownMenuItem<TradeDirectionEnum?>(value: null, child: Text('All')),
          ...TradeDirectionEnum.values.map(
            (d) => DropdownMenuItem<TradeDirectionEnum?>(value: d, child: Text(d.name)),
          ),
        ],
        onChanged: (v) => _updateFilters(
          (f) => f.copyWith(direction: v, clearDirection: v == null),
        ),
      ),
    );
  }

  Widget _resultDropdown() {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<TradeResultFilter>(
        initialValue: _filters.result,
        isExpanded: true,
        decoration: _fieldDecoration('Result'),
        items: const [
          DropdownMenuItem(value: TradeResultFilter.all, child: Text('All')),
          DropdownMenuItem(value: TradeResultFilter.win, child: Text('Wins')),
          DropdownMenuItem(value: TradeResultFilter.loss, child: Text('Losses')),
          DropdownMenuItem(value: TradeResultFilter.breakeven, child: Text('Breakeven')),
        ],
        onChanged: (v) {
          if (v != null) _updateFilters((f) => f.copyWith(result: v));
        },
      ),
    );
  }

  Widget _reviewDropdown() {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<TradeReviewFilter>(
        initialValue: _filters.reviewed,
        isExpanded: true,
        decoration: _fieldDecoration('Review status'),
        items: const [
          DropdownMenuItem(value: TradeReviewFilter.all, child: Text('All')),
          DropdownMenuItem(value: TradeReviewFilter.reviewed, child: Text('Reviewed')),
          DropdownMenuItem(value: TradeReviewFilter.unreviewed, child: Text('Unreviewed')),
        ],
        onChanged: (v) {
          if (v != null) _updateFilters((f) => f.copyWith(reviewed: v));
        },
      ),
    );
  }

  Widget _dateRangePicker() {
    final format = (DateTime? d) =>
        d == null ? null : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return SizedBox(
      width: 260,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _pickDateRange,
        child: InputDecorator(
          decoration: _fieldDecoration('Entry date range'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _filters.entryFrom == null && _filters.entryTo == null
                      ? 'Any date'
                      : '${format(_filters.entryFrom) ?? '…'} → ${format(_filters.entryTo) ?? '…'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_filters.entryFrom != null || _filters.entryTo != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => _updateFilters(
                    (f) => f.copyWith(clearEntryFrom: true, clearEntryTo: true),
                  ),
                )
              else
                const Icon(Icons.calendar_today, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = (_filters.entryFrom != null && _filters.entryTo != null)
        ? DateTimeRange(start: _filters.entryFrom!, end: _filters.entryTo!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
    );

    if (picked == null) return;

    final from = DateTime(picked.start.year, picked.start.month, picked.start.day);
    // End of day, inclusive -- otherwise a trade entered later that same
    // day would be wrongly excluded by TradeListFilters.apply().
    final to = DateTime(
      picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999,
    );

    _updateFilters((f) => f.copyWith(entryFrom: from, entryTo: to));
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ---------------- SUMMARY ----------------

  Widget _summaryRow(List<Trade> filtered) {
    final total = filtered.fold(0.0, (a, b) => a + b.profit);
    final wins = filtered.where((t) => t.profit > 0).length;
    final winRate = filtered.isEmpty ? 0.0 : wins / filtered.length * 100;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Showing ${filtered.length} of ${_trades.length} trade${_trades.length == 1 ? '' : 's'}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        if (filtered.isNotEmpty) ...[
          Text(
            'Total: ${total >= 0 ? '+' : ''}${total.toStringAsFixed(2)} \$',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: total >= 0 ? Colors.green.shade600 : Colors.red.shade400,
            ),
          ),
          Text(
            'Win rate: ${winRate.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}
