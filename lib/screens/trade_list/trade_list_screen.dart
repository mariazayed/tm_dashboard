// SUPERSEDED (unused): the Trades and Trade Journal pages were merged into
// one combined screen -- see TradesScreen in
// lib/screens/trade_journal/trade_journal_screen.dart, which now owns
// routing (RouteNames.trades) and the menu entry. TradesScreen carried over
// this screen's pagination (TradeService.searchPage(), infinite scroll,
// auto-fetch-more-on-empty-filter) verbatim and adds daily/weekly/monthly/
// custom grouping on top via TradeGroupCard. This file is no longer
// referenced from anywhere and is safe to delete; it's left in place only
// because this change was made without shell/file-delete access to this
// machine. classes/trade_list_filters.dart (same folder) is similarly
// unused now -- TradesScreen uses TradeJournalFilters instead.
import 'package:flutter/material.dart';

import 'package:tm_dashboard/widgets/page_back_button.dart';
import 'package:intl/intl.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/asset_model.dart';
import '../../models/strategy_model.dart';
import '../../models/trade_model.dart';
import '../../services/api_client.dart';
import '../../services/asset_service.dart';
import '../../services/strategy_service.dart';
import '../../services/trade_service.dart';
import '../../theme/app_theme.dart';
import 'classes/trade_list_filters.dart';
import 'trade_row_tile.dart';

class TradeListScreen extends StatefulWidget {
  const TradeListScreen({super.key});

  @override
  State<TradeListScreen> createState() => _TradeListScreenState();
}

class _TradeListScreenState extends State<TradeListScreen> {
  // Page size for TradeService.searchPage() -- kept small-ish since each
  // page's trades are all built as live TradeRowTile widgets once they
  // scroll into the SliverList's builder range.
  static const int _pageSize = 30;

  late Future<void> _future;

  // _trades only ever holds pages fetched so far, not the whole history --
  // that's the point: TradeService.getAll() (which returns every trade
  // ever imported) is never called here anymore. Client-side filters
  // (below) therefore filter/count against "loaded so far", not the whole
  // account history, until the user has scrolled far enough to load it
  // all.
  List<Trade> _trades = [];
  List<Asset> _assets = [];
  List<Strategy> _strategies = [];

  int _nextPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  TradeListFilters _filters = const TradeListFilters();
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();

  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _future = _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    // Start fetching the next page a bit before the user hits the bottom,
    // so scrolling doesn't stall on the network round-trip.
    final threshold = _scrollController.position.maxScrollExtent - 600;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    _trades = [];
    _nextPage = 0;
    _hasMore = true;

    // Sequential awaits (not Future.wait) -- same pattern as
    // TradeJournalScreen._load(), and avoids Future.wait's generic type
    // inference having to find a common type across List<Trade>,
    // List<Asset> and List<Strategy>. Assets/strategies still use
    // getAll(): the filter dropdowns need the complete set of choices, and
    // both lists are small/bounded (user-curated, not auto-imported), so
    // there's no memory concern there like there is with trades.
    _assets = await AssetService.fetchAssets();
    _strategies = await StrategyService.getAll();
    await _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    final result = await TradeService.searchPage(
      page: _nextPage,
      size: _pageSize,
    );

    if (!mounted) return;
    setState(() {
      _trades = [..._trades, ...result.data];
      _hasMore = !result.last;
      _nextPage++;
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      await _fetchNextPage();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
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
        leading: const PageBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Trades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ApiClient.shared.refresh(_refresh),
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

          // An active filter can legitimately match nothing in the pages
          // loaded so far even though older, not-yet-fetched pages contain
          // matches (e.g. filtering to a rarely-traded asset). Rather than
          // making the user manually scroll an empty list to trigger the
          // next page, keep auto-fetching until either a match turns up or
          // the server confirms there's nothing left.
          if (filtered.isEmpty &&
              _filters.isActive &&
              _hasMore &&
              !_isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // CustomScrollView + SliverList instead of a SingleChildScrollView
              // wrapping a Column of every TradeRowTile: the old version built
              // (and kept alive) one full widget/render-object tree per trade
              // regardless of scroll position, so memory scaled linearly with
              // total trade count (this app auto-imports trades continuously,
              // so that count only grows). SliverList only builds rows near
              // the viewport, same as ListView.builder, while still letting
              // the filter card + summary scroll away as a normal header.
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _filterCard(constraints.maxWidth),
                          const SizedBox(height: 16),
                          _summaryRow(filtered),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverToBoxAdapter(child: _emptyState()),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              TradeRowTile(trade: filtered[index]),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                  if (_hasMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: _isLoadingMore
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- FILTER BAR ----------------

  Widget _filterCard(double maxWidth) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 17,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              if (_filters.isActive)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Clear filters'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by asset, strategy or notes...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (v) => _updateFilters((f) => f.copyWith(searchText: v)),
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
          const DropdownMenuItem<Asset?>(
            value: null,
            child: Text('All assets'),
          ),
          ..._assets.map(
            (a) => DropdownMenuItem<Asset?>(value: a, child: Text(a.symbol)),
          ),
        ],
        onChanged: (v) =>
            _updateFilters((f) => f.copyWith(asset: v, clearAsset: v == null)),
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
          const DropdownMenuItem<Strategy?>(
            value: null,
            child: Text('All strategies'),
          ),
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
          const DropdownMenuItem<TradeDirectionEnum?>(
            value: null,
            child: Text('All'),
          ),
          ...TradeDirectionEnum.values.map(
            (d) => DropdownMenuItem<TradeDirectionEnum?>(
              value: d,
              child: Text(d.name),
            ),
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
          DropdownMenuItem(
            value: TradeResultFilter.loss,
            child: Text('Losses'),
          ),
          DropdownMenuItem(
            value: TradeResultFilter.breakeven,
            child: Text('Breakeven'),
          ),
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
          DropdownMenuItem(
            value: TradeReviewFilter.reviewed,
            child: Text('Reviewed'),
          ),
          DropdownMenuItem(
            value: TradeReviewFilter.unreviewed,
            child: Text('Unreviewed'),
          ),
        ],
        onChanged: (v) {
          if (v != null) _updateFilters((f) => f.copyWith(reviewed: v));
        },
      ),
    );
  }

  Widget _dateRangePicker() {
    final format = (DateTime? d) => d == null
        ? null
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
    final initialRange =
        (_filters.entryFrom != null && _filters.entryTo != null)
        ? DateTimeRange(start: _filters.entryFrom!, end: _filters.entryTo!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
    );

    if (picked == null) return;

    final from = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    // End of day, inclusive -- otherwise a trade entered later that same
    // day would be wrongly excluded by TradeListFilters.apply().
    final to = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
      23,
      59,
      59,
      999,
    );

    _updateFilters((f) => f.copyWith(entryFrom: from, entryTo: to));
  }

  InputDecoration _fieldDecoration(String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  // ---------------- SUMMARY ----------------

  Widget _summaryRow(List<Trade> filtered) {
    final semantic = context.semanticColors;
    final total = filtered.fold(0.0, (a, b) => a + b.profit);
    final wins = filtered.where((t) => t.profit > 0).length;
    final winRate = filtered.isEmpty ? 0.0 : wins / filtered.length * 100;
    final totalColor = total >= 0 ? semantic.profit : semantic.loss;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statPill(
          icon: Icons.receipt_long_rounded,
          iconColor: Theme.of(context).colorScheme.primary,
          label: 'Trades',
          value: '${filtered.length} / ${_trades.length}',
        ),
        if (filtered.isNotEmpty) ...[
          _statPill(
            icon: total >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            iconColor: totalColor,
            label: 'Total P&L',
            value: '${total >= 0 ? '+' : ''}${_money.format(total)}',
            valueColor: totalColor,
          ),
          _statPill(
            icon: Icons.emoji_events_rounded,
            iconColor: semantic.warning,
            label: 'Win rate',
            value: '${winRate.toStringAsFixed(1)}%',
          ),
        ],
      ],
    );
  }

  Widget _statPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: colorScheme.shadow.withValues(alpha: 0.04),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 28,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _trades.isEmpty ? 'No trades yet' : 'No trades match your filters',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (_trades.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Try adjusting or clearing your filters',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
