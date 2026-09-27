import 'package:flutter/material.dart';

import '../../models/planner_models.dart';
import '../../services/planner_service.dart';
import '../../theme/app_theme.dart';
import 'planner_style.dart';
import 'sheets/focus_area_sheet.dart';
import 'widgets/planner_widgets.dart';

/// Planner settings: working hours per weekday (weekly capacity = their
/// sum) and the Focus Areas with their max share of time.
class SetupView extends StatefulWidget {
  const SetupView({super.key});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  List<double>? _savedHours;
  List<double> _hours = List.filled(7, 0);
  List<FocusAreaModel> _areas = [];
  Object? _error;
  bool _loading = true;
  bool _savingHours = false;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PlannerService.getSettings(),
        PlannerService.getFocusAreas(),
      ]);
      if (!mounted) return;
      final settings = results[0] as PlannerSettingsModel;
      setState(() {
        _savedHours = List.of(settings.dayHours);
        _hours = List.of(settings.dayHours);
        _areas = results[1] as List<FocusAreaModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _reloadAreas() async {
    try {
      final areas = await PlannerService.getFocusAreas();
      if (mounted) setState(() => _areas = areas);
    } catch (e) {
      _snack('$e');
    }
  }

  bool get _hoursDirty {
    final saved = _savedHours;
    if (saved == null) return false;
    for (var i = 0; i < 7; i++) {
      if (saved[i] != _hours[i]) return true;
    }
    return false;
  }

  double get _weeklyTotal => _hours.fold<double>(0, (a, b) => a + b);
  int get _workingDays => _hours.where((h) => h > 0).length;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveHours() async {
    setState(() => _savingHours = true);
    try {
      final saved = await PlannerService.updateSettings(_hours);
      if (!mounted) return;
      setState(() {
        _savedHours = List.of(saved.dayHours);
        _hours = List.of(saved.dayHours);
        _savingHours = false;
      });
      _snack('Working hours saved');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingHours = false);
      _snack('$e');
    }
  }

  Future<void> _openAreaSheet({FocusAreaModel? area}) async {
    final others = _areas
        .where((a) => !a.archived && a.id != area?.id)
        .fold<double>(0, (sum, a) => sum + a.maxPercent);
    final saved = await showPlannerSheet<bool>(
      context,
      FocusAreaSheet(existing: area, otherAreasPercent: others),
    );
    if (saved == true) _reloadAreas();
  }

  Future<void> _toggleArchive(FocusAreaModel area) async {
    try {
      await PlannerService.updateFocusArea(area.id, {'archived': !area.archived});
      await _reloadAreas();
      _snack(area.archived ? '"${area.name}" restored' : '"${area.name}" archived — hidden from pickers, history kept');
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _deleteArea(FocusAreaModel area) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Focus Area'),
        content: Text(
          'Delete "${area.name}"? Tasks and objectives already using it keep showing it.\n\n'
          'Tip: archiving hides it from pickers but keeps it in reports.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PlannerService.deleteFocusArea(area.id);
      await _reloadAreas();
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _move(FocusAreaModel area, int delta) async {
    final active = _areas.where((a) => !a.archived).toList();
    final i = active.indexWhere((a) => a.id == area.id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= active.length) return;
    final reordered = List.of(active)
      ..removeAt(i)
      ..insert(j, area);
    try {
      await Future.wait([
        for (var k = 0; k < reordered.length; k++)
          if (reordered[k].sortOrder != k) PlannerService.updateFocusArea(reordered[k].id, {'sortOrder': k}),
      ]);
      await _reloadAreas();
    } catch (e) {
      _snack('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return PlannerEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Couldn\'t load planner settings',
        message: '$_error',
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final hours = _buildHoursPanel();
            final areas = _buildAreasPanel();
            if (c.maxWidth >= 1050) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: hours),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: areas),
                ],
              );
            }
            return Column(children: [hours, const SizedBox(height: 20), areas]);
          },
        ),
      ],
    );
  }

  Widget _buildHoursPanel() {
    final cs = Theme.of(context).colorScheme;
    return PlannerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(title: 'Working hours', icon: Icons.schedule_outlined),
          Text(
            'Set how many hours you work on each day. Days at 0h are days off.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 7; i++) _DayHoursRow(
            day: PlannerStyle.dayNames[i],
            hours: _hours[i],
            onChanged: (v) => setState(() => _hours[i] = v),
          ),
          const Divider(height: 28),
          Row(
            children: [
              StatTile(label: 'Per week', value: PlannerStyle.hours(_weeklyTotal), icon: Icons.timelapse_outlined),
              const SizedBox(width: 10),
              StatTile(label: 'Working days', value: '$_workingDays / 7', icon: Icons.work_history_outlined),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Monthly capacity adds up these hours for every day in the month. '
            'Extra hours are added per week from the Week view.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_hoursDirty)
                TextButton(
                  onPressed: _savingHours ? null : () => setState(() => _hours = List.of(_savedHours!)),
                  child: const Text('Discard'),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _hoursDirty && !_savingHours ? _saveHours : null,
                icon: _savingHours
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check, size: 18),
                label: const Text('Save hours'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreasPanel() {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final active = _areas.where((a) => !a.archived).toList();
    final archived = _areas.where((a) => a.archived).toList();
    final totalPct = active.fold<double>(0, (s, a) => s + a.maxPercent);

    return PlannerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            title: 'Focus Areas',
            icon: Icons.category_outlined,
            trailing: FilledButton.tonalIcon(
              onPressed: () => _openAreaSheet(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
            ),
          ),
          Text(
            'Each Focus Area can take up to its max % of the week\'s (and month\'s) capacity. '
            'Going over shows a warning — it never blocks you.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (active.isEmpty)
            PlannerEmptyState(
              icon: Icons.category_outlined,
              title: 'No Focus Areas yet',
              message: 'Start with 3–5, e.g. Backtesting 30%, Journaling 15%, Learning 20%, Live trading 40%.',
              actionLabel: 'Create Focus Area',
              onAction: () => _openAreaSheet(),
            )
          else ...[
            ...active.asMap().entries.map((e) => _AreaRow(
                  area: e.value,
                  weeklyHours: _weeklyTotal,
                  canMoveUp: e.key > 0,
                  canMoveDown: e.key < active.length - 1,
                  onEdit: () => _openAreaSheet(area: e.value),
                  onArchive: () => _toggleArchive(e.value),
                  onDelete: () => _deleteArea(e.value),
                  onMoveUp: () => _move(e.value, -1),
                  onMoveDown: () => _move(e.value, 1),
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.functions, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Max % total: ${PlannerStyle.pct(totalPct)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: totalPct < 100 ? semantic.warning : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    totalPct < 100
                        ? '— below 100%, so part of your week can\'t be planned without going over a limit.'
                        : '— each max is a cap, not a reservation.',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
          if (archived.isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _showArchived = !_showArchived),
              child: Row(
                children: [
                  Icon(_showArchived ? Icons.expand_less : Icons.expand_more, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Archived (${archived.length})',
                    style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (_showArchived)
              ...archived.map((a) => _AreaRow(
                    area: a,
                    weeklyHours: _weeklyTotal,
                    onEdit: () => _openAreaSheet(area: a),
                    onArchive: () => _toggleArchive(a),
                    onDelete: () => _deleteArea(a),
                  )),
          ],
        ],
      ),
    );
  }
}

class _DayHoursRow extends StatelessWidget {
  final String day;
  final double hours;
  final ValueChanged<double> onChanged;

  const _DayHoursRow({required this.day, required this.hours, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final off = hours == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              day,
              style: TextStyle(fontWeight: FontWeight.w600, color: off ? cs.onSurfaceVariant : null),
            ),
          ),
          Expanded(
            child: Slider(
              value: hours.clamp(0, 16).toDouble(),
              min: 0,
              max: 16,
              divisions: 32,
              label: PlannerStyle.hours(hours),
              onChanged: onChanged,
            ),
          ),
          _StepButton(icon: Icons.remove, onTap: hours <= 0 ? null : () => onChanged((hours - 0.5).clamp(0, 24).toDouble())),
          SizedBox(
            width: 52,
            child: Text(
              off ? 'Off' : PlannerStyle.hours(hours),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, color: off ? cs.onSurfaceVariant : cs.primary),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: hours >= 24 ? null : () => onChanged((hours + 0.5).clamp(0, 24).toDouble())),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: onTap == null ? cs.outline : null),
      ),
    );
  }
}

class _AreaRow extends StatelessWidget {
  final FocusAreaModel area;
  final double weeklyHours;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _AreaRow({
    required this.area,
    required this.weeklyHours,
    this.canMoveUp = false,
    this.canMoveDown = false,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = PlannerStyle.colorFromHex(area.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Opacity(
              opacity: area.archived ? 0.6 : 1,
              child: Row(
                children: [
                  AreaIconBadge(area: area, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(area.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (area.maxPercent / 100).clamp(0, 1).toDouble(),
                                  minHeight: 6,
                                  color: color,
                                  backgroundColor: cs.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'max ${PlannerStyle.pct(area.maxPercent)} · ≈${PlannerStyle.hours((weeklyHours * area.maxPercent / 100 * 10).round() / 10)}/wk',
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!area.archived) ...[
                    IconButton(
                      tooltip: 'Move up',
                      visualDensity: VisualDensity.compact,
                      onPressed: canMoveUp ? onMoveUp : null,
                      icon: const Icon(Icons.keyboard_arrow_up),
                    ),
                    IconButton(
                      tooltip: 'Move down',
                      visualDensity: VisualDensity.compact,
                      onPressed: canMoveDown ? onMoveDown : null,
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          onEdit();
                        case 'archive':
                          onArchive();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
                      PopupMenuItem(
                        value: 'archive',
                        child: ListTile(
                          leading: Icon(area.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
                          title: Text(area.archived ? 'Restore' : 'Archive'),
                        ),
                      ),
                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
