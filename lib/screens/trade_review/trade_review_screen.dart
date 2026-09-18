import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/entry_confirmation_enum.dart';
import '../../enums/entry_reason_enum.dart';
import '../../enums/entry_zone_type_enum.dart';
import '../../enums/exit_reason_enum.dart';
import '../../enums/invalidation_condition_enum.dart';
import '../../enums/market_bias_enum.dart';
import '../../enums/market_state_enum.dart';
import '../../enums/mistake_tag_enum.dart';
import '../../enums/probability_enum.dart';
import '../../enums/score_enum.dart';
import '../../enums/stop_loss_placement_reason_enum.dart';
import '../../enums/take_profit_placement_reason.dart';
import '../../enums/trade_source_enum.dart';
import '../../models/base_static_data_model.dart';
import '../../models/static_data.dart';
import '../../models/trade_model.dart';
import '../../services/static_data_service.dart';
import '../../services/trade_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/form_chip_select.dart';
import '../../widgets/form_multi_select.dart';

/// Phase 6: one-trade-at-a-time review queue for trades where
/// reviewedAt == null. Every enum field is a tappable chip (pre-filled from
/// the MT5 importer's deterministic classification pass where available,
/// or from an explicit "Get AI Suggestions" call), the discipline score is
/// a 1-10 slider, mistakes are a multi-select -- no free-form typing
/// required for the common case. Confirming PATCHes /trade/{id}/review.
class TradeReviewScreen extends StatefulWidget {
  const TradeReviewScreen({super.key});

  @override
  State<TradeReviewScreen> createState() => _TradeReviewScreenState();
}

class _TradeReviewScreenState extends State<TradeReviewScreen> {
  // Page size for TradeService.searchPage() when topping up the queue.
  static const int _pageSize = 50;
  // Keep at least this many unreviewed trades buffered ahead of
  // _currentIndex before fetching another page.
  static const int _minBuffered = 3;

  late Future<void> _loadFuture;

  // Trades are fetched oldest-entryDateTime-first, same page at a time, and
  // unreviewed ones are appended here -- instead of TradeService.getAll()
  // loading the entire (continuously auto-imported) trade history just to
  // filter it down to the unreviewed subset. Reviewed trades in a fetched
  // page are simply dropped, so a long stretch of already-reviewed history
  // means more pages fetched to find the next unreviewed trade -- there's
  // no server-side "unreviewed only" filter yet (reviewedAt IS NULL isn't
  // expressible through BaseSpecification's equality/like filters).
  List<Trade> _queue = [];
  StaticDataResponse? _staticData;
  int _currentIndex = 0;

  int _nextPage = 0;
  bool _hasMorePages = true;
  bool _isFillingQueue = false;

  bool _submitting = false;
  bool _suggesting = false;

  // --- Per-trade review-flow selections. Re-initialized whenever the
  // current trade changes (see _initFormForCurrentTrade). ---
  EntryReasonEnum? _entryReason;
  EntryConfirmationEnum? _entryConfirmation;
  EntryZoneTypeEnum? _entryZoneType;
  MarketBiasEnum? _marketBias;
  MarketStateEnum? _marketState;
  ProbabilityEnum? _probability;
  InvalidationConditionEnum? _invalidationCondition;
  StopLossPlacementReasonEnum? _slPlacementReason;
  TakeProfitPlacementReasonEnum? _tpPlacementReason;
  ExitReasonEnum? _exitReason;

  double _disciplineValue = 5;
  bool _disciplineTouched = false;

  bool? _followedPlan;
  bool _followedPlanTouched = false;

  List<MistakeTagEnum> _mistakeTags = [];

  // Field names the last "Get AI Suggestions" call actually filled in --
  // used only to draw a highlighted border on those chips.
  final Set<String> _aiSuggestedFields = {};

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    _queue = [];
    _currentIndex = 0;
    _nextPage = 0;
    _hasMorePages = true;

    _staticData = await StaticDataService.getAll();
    await _fillQueue();
    _initFormForCurrentTrade();
  }

  /// Fetches pages of trades (oldest entryDateTime first, same ordering the
  /// queue always used) and appends the unreviewed ones to [_queue], until
  /// either there's enough buffered ahead of [_currentIndex] or the server
  /// confirms there's nothing left to fetch.
  Future<void> _fillQueue() async {
    if (_isFillingQueue) return;
    _isFillingQueue = true;
    try {
      while (_hasMorePages &&
          (_queue.length - _currentIndex) < _minBuffered) {
        final result = await TradeService.searchPage(
          page: _nextPage,
          size: _pageSize,
          sortBy: 'entryDateTime',
          direction: 'ASC',
        );
        _nextPage++;
        _hasMorePages = !result.last;
        _queue.addAll(result.data.where((t) => !t.isReviewed));
      }
    } finally {
      _isFillingQueue = false;
    }
  }

  /// Tops up the queue in the background (fire-and-forget) after
  /// [_confirm]/[_skip] consume an entry, so the "Trade X of Y" progress and
  /// the ability to keep going don't stall waiting on a network round-trip.
  void _topUpQueueInBackground() {
    if (!_hasMorePages || (_queue.length - _currentIndex) >= _minBuffered) {
      return;
    }
    _fillQueue().then((_) {
      if (mounted) setState(() {});
    });
  }

  Trade? get _current =>
      _queue.isEmpty || _currentIndex >= _queue.length
      ? null
      : _queue[_currentIndex];

  void _initFormForCurrentTrade() {
    final t = _current;
    _aiSuggestedFields.clear();
    _entryReason = t?.entryReason;
    _entryConfirmation = t?.entryConfirmation;
    _entryZoneType = t?.entryZoneType;
    _marketBias = t?.marketBias;
    _marketState = t?.marketState;
    _probability = t?.probability;
    _invalidationCondition = t?.invalidationCondition;
    _slPlacementReason = t?.slPlacementReason;
    _tpPlacementReason = t?.tpPlacementReason;
    _exitReason = t?.exitReason;
    _disciplineValue = t?.disciplineScore?.value.toDouble() ?? 5;
    _disciplineTouched = t?.disciplineScore != null;
    _followedPlan = t?.followedPlan;
    _followedPlanTouched = t?.followedPlan != null;
    _mistakeTags = List.of(t?.mistakeTags ?? const []);
  }

  Future<void> _getAiSuggestions() async {
    final t = _current;
    if (t == null || _suggesting) return;

    setState(() => _suggesting = true);
    try {
      final updated = await TradeService.suggest(t.id);
      setState(() {
        _queue[_currentIndex] = updated;

        void apply<E>(E? current, E? fresh, String name, void Function(E) set) {
          if (current == null && fresh != null) {
            set(fresh);
            _aiSuggestedFields.add(name);
          }
        }

        apply(_entryReason, updated.entryReason, 'entryReason', (v) => _entryReason = v);
        apply(_entryConfirmation, updated.entryConfirmation, 'entryConfirmation', (v) => _entryConfirmation = v);
        apply(_entryZoneType, updated.entryZoneType, 'entryZoneType', (v) => _entryZoneType = v);
        apply(_marketBias, updated.marketBias, 'marketBias', (v) => _marketBias = v);
        apply(_marketState, updated.marketState, 'marketState', (v) => _marketState = v);
        apply(_probability, updated.probability, 'probability', (v) => _probability = v);
        apply(_invalidationCondition, updated.invalidationCondition, 'invalidationCondition', (v) => _invalidationCondition = v);
        apply(_slPlacementReason, updated.slPlacementReason, 'slPlacementReason', (v) => _slPlacementReason = v);
        apply(_tpPlacementReason, updated.tpPlacementReason, 'tpPlacementReason', (v) => _tpPlacementReason = v);
        apply(_exitReason, updated.exitReason, 'exitReason', (v) => _exitReason = v);
      });

      if (_aiSuggestedFields.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI had nothing new to suggest for this trade.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  Future<void> _confirm() async {
    final t = _current;
    if (t == null || _submitting) return;

    final payload = <String, dynamic>{
      // mistakeTags is always sent explicitly, even empty, so a review
      // that clears every tag actually clears it server-side rather than
      // being silently treated as "unchanged".
      'mistakeTags': _mistakeTags.map((e) => e.value).toList(),
    };
    if (_entryReason != null) payload['entryReason'] = _entryReason!.value;
    if (_entryConfirmation != null) payload['entryConfirmation'] = _entryConfirmation!.value;
    if (_entryZoneType != null) payload['entryZoneType'] = _entryZoneType!.value;
    if (_marketBias != null) payload['marketBias'] = _marketBias!.value;
    if (_marketState != null) payload['marketState'] = _marketState!.value;
    if (_probability != null) payload['probability'] = _probability!.value;
    if (_invalidationCondition != null) payload['invalidationCondition'] = _invalidationCondition!.value;
    if (_slPlacementReason != null) payload['slPlacementReason'] = _slPlacementReason!.value;
    if (_tpPlacementReason != null) payload['tpPlacementReason'] = _tpPlacementReason!.value;
    if (_exitReason != null) payload['exitReason'] = _exitReason!.value;
    if (_followedPlanTouched) payload['followedPlan'] = _followedPlan;
    if (_disciplineTouched) {
      payload['disciplineScore'] = ScoreEnum.fromValue(_disciplineValue.round()).value;
    }

    setState(() => _submitting = true);
    try {
      await TradeService.review(t.id, payload);
      setState(() {
        _queue.removeAt(_currentIndex);
        if (_currentIndex >= _queue.length) _currentIndex = 0;
        _initFormForCurrentTrade();
      });
      _topUpQueueInBackground();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _skip() {
    if (_queue.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _queue.length;
      _initFormForCurrentTrade();
    });
    _topUpQueueInBackground();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade Review')),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load review queue:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final colorScheme = Theme.of(context).colorScheme;
          final trade = _current;
          if (trade == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "You're all caught up -- no trades waiting for review.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }

          return ListView(
            padding: Responsive.pagePadding(context),
            children: [
              Text(
                // _queue.length is only what's been fetched so far -- append
                // "+" while more pages might still hold unreviewed trades,
                // since the true total isn't known without fetching
                // everything (defeating the point of paging it in).
                'Trade ${_currentIndex + 1} of ${_queue.length}${_hasMorePages ? '+' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _buildHeaderCard(trade),
              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _suggesting ? null : _getAiSuggestions,
                  icon: _suggesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Get AI Suggestions'),
                ),
              ),
              const SizedBox(height: 20),

              _buildChipSection(),
              const SizedBox(height: 12),
              _buildDisciplineSlider(),
              _buildFollowedPlanToggle(),
              _buildMistakeTagsSection(),

              const SizedBox(height: 24),
              ResponsiveRow(
                spacing: 16,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: _submitting ? null : _skip,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Skip'),
                    ),
                  ),
                  FilledButton(
                    onPressed: _submitting ? null : _confirm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _submitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Trade t) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final isProfit = t.profit >= 0;
    final profitColor = isProfit ? semantic.profit : semantic.loss;
    final isLong = t.direction.name == 'LONG';

    return Container(
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 14 : 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                t.asset.symbol,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLong
                      ? semantic.profit.withValues(alpha: 0.1)
                      : semantic.loss.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t.direction.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isLong ? semantic.profit : semantic.loss,
                  ),
                ),
              ),
              if (t.source != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.source == TradeSourceEnum.AUTO_IMPORTED ? 'MT5 IMPORT' : 'MANUAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Text(
                '${t.profit.toStringAsFixed(2)} \$',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: profitColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Entry ${t.entryPrice} → Exit ${t.exitPrice}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd MMM yyyy • HH:mm').format(t.entryDateTime)} → '
            '${DateFormat('dd MMM yyyy • HH:mm').format(t.exitDateTime)}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          if (t.strategy != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: semantic.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                t.strategy!.name,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: semantic.info),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChipSection() {
    final sd = _staticData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chip('Entry Reason', sd.entryReasons, _entryReason, 'entryReason', (v) => setState(() => _entryReason = v)),
        _chip('Entry Confirmation', sd.entryConfirmations, _entryConfirmation, 'entryConfirmation', (v) => setState(() => _entryConfirmation = v)),
        _chip('Entry Zone Type', sd.entryZoneTypes, _entryZoneType, 'entryZoneType', (v) => setState(() => _entryZoneType = v)),
        _chip('Market Bias', sd.marketBiases, _marketBias, 'marketBias', (v) => setState(() => _marketBias = v)),
        _chip('Market State', sd.marketStates, _marketState, 'marketState', (v) => setState(() => _marketState = v)),
        _chip('Probability', sd.probabilities, _probability, 'probability', (v) => setState(() => _probability = v)),
        _chip('Invalidation Condition', sd.invalidationConditions, _invalidationCondition, 'invalidationCondition', (v) => setState(() => _invalidationCondition = v)),
        _chip('SL Placement Reason', sd.stopLossPlacementReasons, _slPlacementReason, 'slPlacementReason', (v) => setState(() => _slPlacementReason = v)),
        _chip('TP Placement Reason', sd.takeProfitPlacementReasons, _tpPlacementReason, 'tpPlacementReason', (v) => setState(() => _tpPlacementReason = v)),
        _chip('Exit Reason', sd.exitReasons, _exitReason, 'exitReason', (v) => setState(() => _exitReason = v)),
      ],
    );
  }

  /// One FormChipSelect for a static-data-backed enum field. [models] is
  /// one of the typed lists off StaticDataResponse (each entry pairs an
  /// enum `id` with its display `enName`); [fieldName] is the review-form
  /// key used to look up whether the AI-suggestion pass filled this field.
  Widget _chip<E, M extends BaseStaticDataModel>(
    String title,
    List<M> models,
    E? selected,
    String fieldName,
    void Function(E?) onChanged,
  ) {
    final sorted = List<M>.of(models)..sort((a, b) => a.order.compareTo(b.order));
    final ids = sorted.map((m) => (m as dynamic).id as E).toList();
    final labels = {for (final m in sorted) (m as dynamic).id as E: m.enName};

    return FormChipSelect<E>(
      title: title,
      options: ids,
      selected: selected,
      labelBuilder: (e) => labels[e] ?? e.toString(),
      onChanged: onChanged,
      suggested: (_aiSuggestedFields.contains(fieldName) && selected != null)
          ? <E>{selected!}
          : <E>{},
    );
  }

  Widget _buildDisciplineSlider() {
    final scoreLabel = _staticData!.scoreList.firstWhere(
      (s) => s.id == _disciplineValue.round(),
      orElse: () => _staticData!.scoreList.first,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discipline Score${_disciplineTouched ? ' — ${scoreLabel.enName}' : ''}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
          ),
          Slider(
            value: _disciplineValue,
            min: 1,
            max: 10,
            divisions: 9,
            label: _disciplineValue.round().toString(),
            onChanged: (v) => setState(() {
              _disciplineValue = v;
              _disciplineTouched = true;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowedPlanToggle() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Followed Plan?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: _followedPlan != null ? {_followedPlan!} : const {},
            emptySelectionAllowed: true,
            onSelectionChanged: (selection) => setState(() {
              _followedPlan = selection.isEmpty ? null : selection.first;
              _followedPlanTouched = selection.isNotEmpty;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeTagsSection() {
    final sorted = List.of(_staticData!.mistakeTags)..sort((a, b) => a.order.compareTo(b.order));

    return FormMultiSelect<MistakeTagEnum>(
      title: 'Mistake Tags',
      options: sorted.map((m) => m.id).toList(),
      selected: _mistakeTags,
      labelBuilder: (id) => sorted.firstWhere((m) => m.id == id).enName,
      onChanged: (v) => setState(() => _mistakeTags = v),
    );
  }
}
