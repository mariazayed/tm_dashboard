import 'package:flutter/material.dart';

import 'package:tm_dashboard/widgets/page_back_button.dart';

import '../../models/planner_models.dart';
import 'month_view.dart';
import 'setup_view.dart';
import 'week_view.dart';

enum PlannerTab { week, month, setup }

/// Planner page: weekly plan, monthly plan, and setup (working hours +
/// Focus Areas). Holds the selected week/month so switching tabs -- or
/// opening a week from the month's week strip -- keeps your place.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  PlannerTab _tab = PlannerTab.week;
  DateTime _weekStart = mondayOf(DateTime.now());
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _openWeek(DateTime monday) {
    setState(() {
      _weekStart = mondayOf(monday);
      _tab = PlannerTab.week;
    });
  }

  void _goToSetup() => setState(() => _tab = PlannerTab.setup);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Widget body;
    switch (_tab) {
      case PlannerTab.week:
        body = WeekView(
          key: const ValueKey('week'),
          weekStart: _weekStart,
          onWeekChanged: (d) => setState(() {
            _weekStart = mondayOf(d);
            // Keep the month tab roughly in step with the week you browse.
            _month = DateTime(_weekStart.year, _weekStart.month);
          }),
          onGoToSetup: _goToSetup,
        );
      case PlannerTab.month:
        body = MonthView(
          key: const ValueKey('month'),
          month: _month,
          onMonthChanged: (m) =>
              setState(() => _month = DateTime(m.year, m.month)),
          onOpenWeek: _openWeek,
          onGoToSetup: _goToSetup,
        );
      case PlannerTab.setup:
        body = const SetupView(key: ValueKey('setup'));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const PageBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Planner'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<PlannerTab>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.standard,
                    side: WidgetStatePropertyAll(
                      BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: PlannerTab.week,
                      icon: Icon(Icons.view_week_outlined, size: 18),
                      label: Text('Week'),
                    ),
                    ButtonSegment(
                      value: PlannerTab.month,
                      icon: Icon(Icons.calendar_view_month_outlined, size: 18),
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value: PlannerTab.setup,
                      icon: Icon(Icons.tune_outlined, size: 18),
                      label: Text('Setup'),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        child: body,
      ),
    );
  }
}
