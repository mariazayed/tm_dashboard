import 'package:flutter/material.dart';

import '../../models/invest/money.dart';
import '../../models/invest/projection.dart';

/// "What if" panel: change the monthly amount and the horizon and see three
/// return scenarios side by side. Starts from the current portfolio value.
class ProjectionPanel extends StatefulWidget {
  const ProjectionPanel({
    super.key,
    required this.startCents,
    required this.monthlyCents,
    required this.currency,
  });

  final int startCents;
  final int monthlyCents;
  final String currency;

  static const scenarios = [0.05, 0.07, 0.09];

  @override
  State<ProjectionPanel> createState() => _ProjectionPanelState();
}

class _ProjectionPanelState extends State<ProjectionPanel> {
  late final TextEditingController _monthly;
  late int _monthlyCents;
  double _years = 10;

  @override
  void initState() {
    super.initState();
    _monthlyCents = widget.monthlyCents;
    _monthly = TextEditingController(text: Money.plain(widget.monthlyCents));
  }

  @override
  void dispose() {
    _monthly.dispose();
    super.dispose();
  }

  void _onMonthlyChanged(String text) {
    final cents = Money.parseCents(text);
    if (cents != null) setState(() => _monthlyCents = cents);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final years = _years.round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Projection', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Starts from your current value and adds the monthly amount. '
              'These are assumptions, not predictions.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('projection-monthly'),
              controller: _monthly,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Monthly amount (${widget.currency})',
              ),
              onChanged: _onMonthlyChanged,
            ),
            const SizedBox(height: 8),
            Text('Years: $years', key: const Key('projection-years-label')),
            Slider(
              key: const Key('projection-years'),
              value: _years,
              min: 1,
              max: 40,
              divisions: 39,
              label: '$years',
              onChanged: (v) => setState(() => _years = v),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                // Four money columns do not fit a phone: stack each scenario instead.
                final narrow = constraints.maxWidth < 520;
                return narrow
                    ? Column(
                        children: [
                          for (final annual in ProjectionPanel.scenarios)
                            _stackedScenario(context, annual, years),
                        ],
                      )
                    : Table(
                        columnWidths: const {0: IntrinsicColumnWidth()},
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          _row(context, [
                            'Return',
                            'Put in',
                            'Could be',
                            'Growth',
                          ], true),
                          for (final annual in ProjectionPanel.scenarios)
                            _scenarioRow(context, annual, years),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stackedScenario(BuildContext context, double annual, int years) {
    final p = Projection.compute(
      startCents: widget.startCents,
      monthlyCents: _monthlyCents,
      years: years,
      annualReturn: annual,
    );
    String money(int cents) => Money.format(cents, widget.currency);
    final theme = Theme.of(context);
    final pct = (annual * 100).round();
    return Padding(
      key: ValueKey('scenario-$pct'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('$pct% a year', style: theme.textTheme.bodyMedium),
              ),
              Text(
                money(p.finalValueCents),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          Text(
            'Put in ${money(p.contributedCents)} · growth ${money(p.growthCents)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  TableRow _scenarioRow(BuildContext context, double annual, int years) {
    final p = Projection.compute(
      startCents: widget.startCents,
      monthlyCents: _monthlyCents,
      years: years,
      annualReturn: annual,
    );
    String money(int cents) => Money.format(cents, widget.currency);
    return _row(
      context,
      [
        '${(annual * 100).round()}%',
        money(p.contributedCents),
        money(p.finalValueCents),
        money(p.growthCents),
      ],
      false,
      key: ValueKey('scenario-${(annual * 100).round()}'),
    );
  }

  TableRow _row(
    BuildContext context,
    List<String> cells,
    bool header, {
    LocalKey? key,
  }) {
    final style = header
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium;
    return TableRow(
      children: [
        for (var i = 0; i < cells.length; i++)
          Padding(
            // TableRow keys are not findable; key the first cell as the row's handle.
            key: i == 0 ? key : null,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(
              cells[i],
              style: style,
              textAlign: i == 0 ? TextAlign.start : TextAlign.end,
            ),
          ),
      ],
    );
  }
}
