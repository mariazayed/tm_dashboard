import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tm_dashboard/models/strategy_model.dart';
import 'package:tm_dashboard/services/strategy_service.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/asset_model.dart';
import '../../models/trade_model.dart';
import '../../services/asset_service.dart';
import '../../services/trade_service.dart';
import '../trade_list/trade_row_tile.dart';
import 'add_journal_sheet.dart';
import 'classes/trade_journal.dart';
import 'classes/trade_journal_filters.dart';
import 'journal_card.dart';

/// Combined Trades screen -- merges what used to be two separate pages:
/// TradeListScreen (a flat, filterable trade ledger) and TradeJournalScreen
/// (trades grouped into cards). Filtering and paginated loading are carried
/// over from TradeListScreen's latest version (TradeService.searchPage(),
/// infinite scroll via _scrollController, auto-fetch-more when an active
/// filter empties the currently loaded page); on top of that there's now a
/// "Group by" control (None/Daily/Weekly/Monthly/Custom -- see
/// TradeGrouping in classes/trade_journal.dart) that buckets the filtered,
/// loaded-so-far trades by entryDateTime instead of the old exact-entry/
/// exit-time "journal window" match. "None" renders the same flat
/// TradeRowTile list TradeListScreen used to; any other mode renders
/// TradeGroupCard sections. Same caveat as the old journal grouping: a
/// day/week/month/custom bucket can look incomplete until enough pages have
/// loaded to cover it fully -- it fills in as the user scrolls.
class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  // Page size for TradeService.searchPage() -- kept small-ish since each
  // page's trades are all built as live TradeRowTile/TradeGroupCard widgets
  // once they scroll into the SliverList's builder range.
  static const int _pageSize = 30;

  late Future<void> _future;

  // _trades only ever holds pages fetched so far, not the whole history --
  // that's the point: TradeService.getAll() (which returns every trade ever
  // imported) is never called here. Client-side filters/grouping (below)
  // therefore operate on "loaded so far", not the whole account history,
  // until the user has scrolled far enough to load it all.
  List<Trade> _trades = [];
  List<Asset> _assets = [];
  List<Strategy> _strategies = [];

  int _nextPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  TradeJournalFilters _filters = const TradeJournalFilters();
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();

  TradeGrouping _grouping = TradeGrouping.none;
  int _customDays = 7;
  late final _customDaysCtrl = TextEditingController(text: '$_customDays');

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
    _customDaysCtrl.dispose();
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

    // Sequential awaits (not Future.wait) -- avoids Future.wait's generic
    // type inference having to find a common type across List<Asset> and
    // List<Strategy>. Assets/strategies still use the full-list fetches:
    // the filter dropdowns and AddJournalSheet need the complete set of
    // choices, and both lists are small/bounded (user-curated, not
    // auto-imported), so there's no memory concern there like there is
    // with trades.
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

  void _updateFilters(
    TradeJournalFilters Function(TradeJournalFilters) update,
  ) {
    setState(() => _filters = update(_filters));
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() => _filters = const TradeJournalFilters());
  }

  Future<void> _openAddJournal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddJournalSheet(assets: _assets, strategies: _strategies),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _openAddJournal),
          const SizedBox(width: 8),
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

          final filteredTrades = _filters.apply(_trades);
          final grouped = _grouping != TradeGrouping.none;
          final groups = grouped
              ? TradeGrouper.group(filteredTrades, _grouping, customDays: _customDays)
              : const <TradeGroup>[];

          // An active filter can legitimately match nothing in the pages
          // loaded so far even though older, not-yet-fetched pages contain
          // matches (e.g. filtering to a rarely-traded asset). Rather than
          // making the user manually scroll an empty list to trigger the
          // next page, keep auto-fetching until either a match turns up or
          // the server confirms there's nothing left.
          if (filteredTrades.isEmpty &&
              _filters.isActive &&
              _hasMore &&
              !_isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
          }

          // CustomScrollView + SliverList instead of a ListView.builder
          // wrapping a Column of every row/card: keeps the filter card +
          // grouping bar + summary scrolling away as a normal header while
          // only building rows/cards near the viewport, and drives the
          // infinite-scroll page fetches via _scrollController.
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _filterCard(),
                      const SizedBox(height: 16),
                      _groupingBar(),
                      const SizedBox(height: 16),
                      _summaryRow(filteredTrades, groups),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (!grouped) ...[
                if (filteredTrades.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(child: _emptyState()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => TradeRowTile(trade: filteredTrades[i]),
                        childCount: filteredTrades.length,
                      ),
                    ),
                  ),
              ] else ...[
                if (groups.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(child: _emptyState()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => TradeGroupCard(group: groups[i]),
                        childCount: groups.length,
                      ),
                    ),
                  ),
              ],
              if (_hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: _isLoadingMore
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- FILTER BAR ----------------

  Widget _filterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
              Icon(Icons.tune_rounded, size: 17, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
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
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade100),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF818CF8),
                  width: 1.5,
                ),
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
      child: DropdownButtonFormField<JournalResultFilter>(
        initialValue: _filters.result,
        isExpanded: true,
        decoration: _fieldDecoration('Result'),
        items: const [
          DropdownMenuItem(value: JournalResultFilter.all, child: Text('All')),
          DropdownMenuItem(value: JournalResultFilter.win, child: Text('Wins')),
          DropdownMenuItem(
            value: JournalResultFilter.loss,
            child: Text('Losses'),
          ),
          DropdownMenuItem(
            value: JournalResultFilter.breakeven,
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
      child: DropdownButtonFormField<JournalReviewFilter>(
        initialValue: _filters.reviewed,
        isExpanded: true,
        decoration: _fieldDecoration('Review status'),
        items: const [
          DropdownMenuItem(value: JournalReviewFilter.all, child: Text('All')),
          DropdownMenuItem(
            value: JournalReviewFilter.reviewed,
            child: Text('Reviewed'),
          ),
          DropdownMenuItem(
            value: JournalReviewFilter.unreviewed,
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
    // day would be wrongly excluded by TradeJournalFilters.apply().
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
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
      ),
    );
  }

  // ---------------- GROUP BY BAR ----------------

  Widget _groupingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stacked_bar_chart_rounded,
                size: 17,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                'Group by',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          ...TradeGrouping.values.map(_groupChip),
          if (_grouping == TradeGrouping.custom) _customDaysField(),
        ],
      ),
    );
  }

  Widget _groupChip(TradeGrouping g) {
    final selected = _grouping == g;
    return ChoiceChip(
      label: Text(g.label),
      selected: selected,
      onSelected: (_) => setState(() => _grouping = g),
      showCheckmark: false,
      selectedColor: const Color(0xFF818CF8).withOpacity(0.16),
      backgroundColor: const Color(0xFFF9FAFB),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: selected ? const Color(0xFF6366F1) : Colors.grey.shade700,
      ),
      side: BorderSide(
        color: selected
            ? const Color(0xFF818CF8).withOpacity(0.4)
            : Colors.grey.shade200,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _customDaysField() {
    return SizedBox(
      width: 130,
      child: TextField(
        controller: _customDaysCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          prefixText: 'every ',
          suffixText: ' days',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
          ),
        ),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n > 0) setState(() => _customDays = n);
        },
      ),
    );
  }

  // ---------------- SUMMARY ----------------

  Widget _summaryRow(List<Trade> filteredTrades, List<TradeGroup> groups) {
    final total = filteredTrades.fold(0.0, (a, b) => a + b.profit);
    final wins = filteredTrades.where((t) => t.profit > 0).length;
    final winRate = filteredTrades.isEmpty
        ? 0.0
        : wins / filteredTrades.length * 100;
    final totalColor = total >= 0
        ? const Color(0xFF16A34A)
        : const Color(0xFFEF4444);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (_grouping != TradeGrouping.none)
          _statPill(
            icon: Icons.folder_copy_outlined,
            iconColor: const Color(0xFF818CF8),
            label: 'Groups',
            value: '${groups.length}',
          ),
        _statPill(
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFF818CF8),
          label: 'Trades',
          value: '${filteredTrades.length} / ${_trades.length} loaded',
        ),
        if (filteredTrades.isNotEmpty) ...[
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
            iconColor: const Color(0xFFF59E0B),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black.withOpacity(0.04),
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
                  color: Colors.grey.shade500,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF818CF8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 28,
              color: Color(0xFF818CF8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _trades.isEmpty ? 'No trades yet' : 'No trades match your filters',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _trades.isEmpty
                ? 'Tap + to log your first trade journal'
                : 'Try adjusting or clearing your filters',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
