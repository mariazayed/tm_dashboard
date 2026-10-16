import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tm_dashboard/widgets/page_back_button.dart';

import '../../models/invest/contribution_model.dart';
import '../../models/invest/invest_settings_model.dart';
import '../../models/invest/money.dart';
import '../../models/invest/holding_model.dart';
import '../../services/contribution_service.dart';
import '../../services/holding_service.dart';
import 'add_contribution_sheet.dart';
import 'invest_ui.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({
    super.key,
    ContributionService? service,
    HoldingService? holdings,
  }) : _service = service,
       _holdings = holdings;

  final ContributionService? _service;
  final HoldingService? _holdings;

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  ContributionService get _service =>
      widget._service ?? ContributionService.shared;
  HoldingService get _holdingService =>
      widget._holdings ?? HoldingService.shared;
  late Future<
    (InvestSettingsModel, List<ContributionModel>, List<HoldingModel>)
  >
  _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(InvestSettingsModel, List<ContributionModel>, List<HoldingModel>)>
  _load() async {
    final results = await Future.wait([
      _service.getSettings(),
      _service.getAll(),
      // The list of funds is optional: an older server has none, and the page works without it.
      _holdingService
          .list()
          .then<List<HoldingModel>>((h) => h)
          .catchError((_) => <HoldingModel>[]),
    ]);
    return (
      results[0] as InvestSettingsModel,
      results[1] as List<ContributionModel>,
      results[2] as List<HoldingModel>,
    );
  }

  void _reload() {
    // A block body: setState must not be handed a callback that returns a Future.
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openSheet(
    InvestSettingsModel settings,
    List<HoldingModel> holdings,
    List<ContributionModel> items, {
    ContributionModel? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddContributionSheet(
        settings: settings,
        existing: existing,
        holdings: holdings,
        contributions: items,
        // the list is newest first, so this is the fund you bought last
        defaultHoldingId: items.isEmpty ? null : items.first.holdingId,
        service: widget._service,
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(ContributionModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contribution?'),
        content: Text(
          'The ${ContributionModel.dateString(c.contributedOn)} contribution '
          'will be removed from your totals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(c.id);
      _reload();
    } on InvestApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _exportCsv() async {
    try {
      final csv = await _service.exportCsv();
      await Clipboard.setData(ClipboardData(text: csv));
      _toast('CSV copied to the clipboard');
    } on InvestApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _importCsv() async {
    final csv = await askForText(
      context,
      title: 'Import CSV',
      confirmLabel: 'Import',
      minLines: 6,
      maxLines: 12,
      width: 480,
      hint:
          'date,amount,shares,price,fee,notes,ticker\n2026-09-01,300,2.55,117.64,,,VT',
      fieldKey: const Key('csv-input'),
    );
    if (csv == null || csv.trim().isEmpty) return;
    try {
      final result = await _service.importCsv(csv);
      if (!mounted) return;
      if (result.ok) {
        _toast(
          'Imported ${result.imported}, skipped ${result.skipped} duplicates',
        );
        _reload();
      } else {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Nothing imported'),
            content: SingleChildScrollView(
              child: Text(result.errors.take(20).join('\n')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on InvestApiException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (settings, items, holdings) = snapshot.data!;
        final cashBalance = items.fold<int>(
          0,
          (sum, c) => sum + c.cashDeltaCents,
        );
        final availableCash = cashBalance > 0 ? cashBalance : 0;
        final totalContributed = items.fold<int>(
          0,
          (sum, c) => sum + c.amountCents + c.feeCents,
        );
        final colors = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 600;
                  final title = Row(
                    children: [
                      const PageBackButton(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contributions',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your buys, fees and cash ready to reinvest.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final actions = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openSheet(settings, holdings, items),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _importCsv,
                        icon: const Icon(Icons.file_upload_outlined),
                        label: const Text('Import CSV'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _exportCsv,
                        icon: const Icon(Icons.content_copy_rounded),
                        label: const Text('Copy CSV'),
                      ),
                    ],
                  );
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 16), actions],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 16),
                      actions,
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primaryContainer.withValues(alpha: 0.72),
                        colors.surfaceContainerHigh,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available to reinvest',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Money.format(availableCash, settings.currency),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          children: [
                            _SummaryMetric(
                              label: 'Contributions',
                              value: '${items.length}',
                            ),
                            _SummaryMetric(
                              label: 'Total added',
                              value: Money.format(
                                totalContributed,
                                settings.currency,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${items.length} ${items.length == 1 ? 'entry' : 'entries'}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 42,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No contributions yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add your first buy to start tracking your progress.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        padding: const EdgeInsets.only(bottom: 12),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final c = items[i];
                          return Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _openSheet(
                                settings,
                                holdings,
                                items,
                                existing: c,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  8,
                                  14,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          colors.secondaryContainer,
                                      foregroundColor:
                                          colors.onSecondaryContainer,
                                      child: const Icon(
                                        Icons.south_west_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 2,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                Money.format(
                                                  c.amountCents + c.feeCents,
                                                  settings.currency,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              Text(
                                                ContributionModel.dateString(
                                                  c.contributedOn,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: colors
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 9),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              _DetailChip(
                                                icon: Icons.pie_chart_outline,
                                                text:
                                                    '${c.shares.toStringAsFixed(4)} ${c.ticker ?? settings.ticker} @ ${c.price.toStringAsFixed(2)}',
                                              ),
                                              _DetailChip(
                                                icon: Icons.receipt_outlined,
                                                text:
                                                    'Fee ${Money.format(c.feeCents, settings.currency)}',
                                              ),
                                              _DetailChip(
                                                icon: Icons
                                                    .account_balance_wallet_outlined,
                                                text:
                                                    'Cash left ${Money.format(c.cashLeftCents, settings.currency)}',
                                              ),
                                            ],
                                          ),
                                          if (c.notes != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              c.notes!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        colors.onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      onPressed: () => _confirmDelete(c),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 2),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
