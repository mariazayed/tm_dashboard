import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:tm_dashboard/widgets/page_back_button.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TradingHoursView { week, day }

class TradingHoursScreen extends StatefulWidget {
  const TradingHoursScreen({super.key});

  @override
  State<TradingHoursScreen> createState() => _TradingHoursScreenState();
}

class _TradingHoursScreenState extends State<TradingHoursScreen> {
  static const _storageKey = 'trading_hours_allowed_slots_v1';
  static const _slotMinutes = 30;
  static const _slotsPerDay = 24 * 60 ~/ _slotMinutes;
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final Set<String> _allowedSlots = {};
  TradingHoursView _view = TradingHoursView.week;
  DateTime _selectedDate = DateTime.now();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);

    if (stored != null) {
      final decoded = jsonDecode(stored);
      if (decoded is List) {
        _allowedSlots
          ..clear()
          ..addAll(decoded.whereType<String>());
      }
    }

    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _saveSlots() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_allowedSlots.toList()..sort()),
    );
  }

  DateTime get _weekStart {
    final normalized = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  String _slotKey(int weekday, int slot) => '$weekday:$slot';

  String _slotLabel(int slot) {
    final minutes = slot * _slotMinutes;
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _slotRangeLabel(int slot) {
    final nextSlot = slot + 1;
    return '${_slotLabel(slot)} - ${_slotLabel(nextSlot == _slotsPerDay ? 0 : nextSlot)}';
  }

  void _toggleSlot(int weekday, int slot) {
    final key = _slotKey(weekday, slot);
    setState(() {
      if (_allowedSlots.contains(key)) {
        _allowedSlots.remove(key);
      } else {
        _allowedSlots.add(key);
      }
    });
    _saveSlots();
  }

  void _setRange({
    required int startSlot,
    required int endSlot,
    required bool allowed,
    int? weekday,
  }) {
    setState(() {
      final days = weekday == null
          ? Iterable<int>.generate(7, (index) => index + 1)
          : [weekday];
      for (final day in days) {
        for (int slot = startSlot; slot < endSlot; slot++) {
          final key = _slotKey(day, slot);
          if (allowed) {
            _allowedSlots.add(key);
          } else {
            _allowedSlots.remove(key);
          }
        }
      }
    });
    _saveSlots();
  }

  void _clearAll() {
    setState(_allowedSlots.clear);
    _saveSlots();
  }

  void _changeSelectedDate(int offsetDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offsetDays));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const PageBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Trading Hours'),
        actions: [
          IconButton(
            tooltip: 'Clear allowed slots',
            onPressed: _allowedSlots.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: _Toolbar(
                      view: _view,
                      selectedDate: _selectedDate,
                      weekStart: _weekStart,
                      allowedCount: _allowedSlots.length,
                      onViewChanged: (view) => setState(() => _view = view),
                      onPrevious: () => _changeSelectedDate(
                        _view == TradingHoursView.week ? -7 : -1,
                      ),
                      onNext: () => _changeSelectedDate(
                        _view == TradingHoursView.week ? 7 : 1,
                      ),
                      onToday: () =>
                          setState(() => _selectedDate = DateTime.now()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: _PresetBar(
                      selectedWeekday: _selectedDate.weekday,
                      view: _view,
                      onMarkLondon: () => _setRange(
                        startSlot: 8 * 2,
                        endSlot: 12 * 2,
                        allowed: true,
                        weekday: _view == TradingHoursView.day
                            ? _selectedDate.weekday
                            : null,
                      ),
                      onMarkNewYork: () => _setRange(
                        startSlot: 13 * 2,
                        endSlot: 17 * 2,
                        allowed: true,
                        weekday: _view == TradingHoursView.day
                            ? _selectedDate.weekday
                            : null,
                      ),
                      onBlockDay: () => _setRange(
                        startSlot: 0,
                        endSlot: _slotsPerDay,
                        allowed: false,
                        weekday: _view == TradingHoursView.day
                            ? _selectedDate.weekday
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        _LegendPill(
                          color: theme.colorScheme.primary,
                          label: 'Allowed',
                        ),
                        const SizedBox(width: 10),
                        _LegendPill(
                          color: theme.colorScheme.outlineVariant,
                          label: 'Not allowed',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _view == TradingHoursView.week
                        ? _WeeklyGrid(
                            weekStart: _weekStart,
                            allowedSlots: _allowedSlots,
                            slotLabel: _slotLabel,
                            slotKey: _slotKey,
                            onSlotTap: _toggleSlot,
                          )
                        : _DailyGrid(
                            date: _selectedDate,
                            allowedSlots: _allowedSlots,
                            slotKey: _slotKey,
                            slotRangeLabel: _slotRangeLabel,
                            onSlotTap: (slot) =>
                                _toggleSlot(_selectedDate.weekday, slot),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.view,
    required this.selectedDate,
    required this.weekStart,
    required this.allowedCount,
    required this.onViewChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final TradingHoursView view;
  final DateTime selectedDate;
  final DateTime weekStart;
  final int allowedCount;
  final ValueChanged<TradingHoursView> onViewChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rangeEnd = weekStart.add(const Duration(days: 6));
    final title = view == TradingHoursView.week
        ? '${DateFormat.MMMd().format(weekStart)} - ${DateFormat.MMMd().format(rangeEnd)}'
        : DateFormat('EEEE, MMM d').format(selectedDate);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<TradingHoursView>(
          segments: const [
            ButtonSegment(
              value: TradingHoursView.week,
              icon: Icon(Icons.view_week_outlined),
              label: Text('Week'),
            ),
            ButtonSegment(
              value: TradingHoursView.day,
              icon: Icon(Icons.today_outlined),
              label: Text('Day'),
            ),
          ],
          selected: {view},
          onSelectionChanged: (selection) => onViewChanged(selection.first),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            SizedBox(
              width: (MediaQuery.sizeOf(context).width - 144).clamp(
                100.0,
                190.0,
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: onToday,
          icon: const Icon(Icons.my_location_outlined, size: 18),
          label: const Text('Today'),
        ),
        Text(
          '$allowedCount allowed slots',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PresetBar extends StatelessWidget {
  const _PresetBar({
    required this.selectedWeekday,
    required this.view,
    required this.onMarkLondon,
    required this.onMarkNewYork,
    required this.onBlockDay,
  });

  final int selectedWeekday;
  final TradingHoursView view;
  final VoidCallback onMarkLondon;
  final VoidCallback onMarkNewYork;
  final VoidCallback onBlockDay;

  @override
  Widget build(BuildContext context) {
    final scope = view == TradingHoursView.week
        ? 'week'
        : _TradingHoursScreenState._dayLabels[selectedWeekday - 1];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.tonalIcon(
          onPressed: onMarkLondon,
          icon: const Icon(Icons.schedule_outlined, size: 18),
          label: Text('Allow London $scope'),
        ),
        FilledButton.tonalIcon(
          onPressed: onMarkNewYork,
          icon: const Icon(Icons.query_stats_outlined, size: 18),
          label: Text('Allow New York $scope'),
        ),
        OutlinedButton.icon(
          onPressed: onBlockDay,
          icon: const Icon(Icons.block_outlined, size: 18),
          label: Text(
            view == TradingHoursView.week
                ? 'Block all slots'
                : 'Block this day',
          ),
        ),
      ],
    );
  }
}

class _WeeklyGrid extends StatefulWidget {
  const _WeeklyGrid({
    required this.weekStart,
    required this.allowedSlots,
    required this.slotLabel,
    required this.slotKey,
    required this.onSlotTap,
  });

  final DateTime weekStart;
  final Set<String> allowedSlots;
  final String Function(int slot) slotLabel;
  final String Function(int weekday, int slot) slotKey;
  final void Function(int weekday, int slot) onSlotTap;

  @override
  State<_WeeklyGrid> createState() => _WeeklyGridState();
}

class _WeeklyGridState extends State<_WeeklyGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 760 ? 760 : constraints.maxWidth,
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                primary: false,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 76),
                        for (int weekday = 1; weekday <= 7; weekday++)
                          Expanded(
                            child: _DayHeader(
                              label: _TradingHoursScreenState
                                  ._dayLabels[weekday - 1],
                              date: widget.weekStart.add(
                                Duration(days: weekday - 1),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (
                      int slot = 0;
                      slot < _TradingHoursScreenState._slotsPerDay;
                      slot++
                    )
                      Row(
                        children: [
                          SizedBox(
                            width: 76,
                            child: Text(
                              widget.slotLabel(slot),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          for (int weekday = 1; weekday <= 7; weekday++)
                            Expanded(
                              child: _SlotCell(
                                allowed: widget.allowedSlots.contains(
                                  widget.slotKey(weekday, slot),
                                ),
                                onTap: () => widget.onSlotTap(weekday, slot),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DailyGrid extends StatelessWidget {
  const _DailyGrid({
    required this.date,
    required this.allowedSlots,
    required this.slotKey,
    required this.slotRangeLabel,
    required this.onSlotTap,
  });

  final DateTime date;
  final Set<String> allowedSlots;
  final String Function(int weekday, int slot) slotKey;
  final String Function(int slot) slotRangeLabel;
  final ValueChanged<int> onSlotTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _TradingHoursScreenState._slotsPerDay,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, slot) {
        final allowed = allowedSlots.contains(slotKey(date.weekday, slot));

        return Material(
          color: allowed
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSlotTap(slot),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: allowed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    allowed
                        ? Icons.check_circle_outline
                        : Icons.do_not_disturb_on_outlined,
                    color: allowed
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      slotRangeLabel(slot),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    allowed ? 'Allowed' : 'Not allowed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: allowed
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.date});

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat.MMMd().format(date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({required this.allowed, required this.onTap});

  final bool allowed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Tooltip(
        message: allowed ? 'Allowed' : 'Not allowed',
        child: Material(
          color: allowed
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: allowed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: allowed
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
