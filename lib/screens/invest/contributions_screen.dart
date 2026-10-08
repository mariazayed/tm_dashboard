import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/invest/contribution_model.dart';
import '../../models/invest/invest_settings_model.dart';
import '../../models/invest/money.dart';
import '../../services/contribution_service.dart';
import 'add_contribution_sheet.dart';
import 'invest_ui.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key, ContributionService? service})
    : _service = service;

  final ContributionService? _service;

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  ContributionService get _service =>
      widget._service ?? ContributionService.shared;
  late Future<(InvestSettingsModel, List<ContributionModel>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(InvestSettingsModel, List<ContributionModel>)> _load() async {
    try {
      final results = await Future.wait([
        _service.getSettings(),
        _service.getAll(),
      ]);
      return (
        results[0] as InvestSettingsModel,
        results[1] as List<ContributionModel>,
      );
    } on InvestApiException catch (e) {
      rethrow;
    }
  }

  void _reload() {
    // A block body: setState must not be handed a callback that returns a Future.
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openSheet(
    InvestSettingsModel settings, {
    ContributionModel? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddContributionSheet(
        settings: settings,
        existing: existing,
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
      hint: 'date,amount,shares,price,fee,notes\n2026-09-01,300,2.55,117.64',
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
        final (settings, items) = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Contributions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  FilledButton.icon(
                    onPressed: () => _openSheet(settings),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                  OutlinedButton(
                    onPressed: _importCsv,
                    child: const Text('Import CSV'),
                  ),
                  OutlinedButton(
                    onPressed: _exportCsv,
                    child: const Text('Copy CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No contributions yet'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = items[i];
                          return ListTile(
                            title: Text(
                              '${Money.format(c.amountCents, settings.currency)}'
                              '  ·  ${ContributionModel.dateString(c.contributedOn)}',
                            ),
                            subtitle: Text(
                              '${c.shares.toStringAsFixed(4)} ${settings.ticker} '
                              '@ ${c.price.toStringAsFixed(2)}'
                              '${c.feeCents > 0 ? '  ·  fee ${Money.format(c.feeCents, settings.currency)}' : ''}'
                              '${c.notes == null ? '' : '\n${c.notes}'}',
                            ),
                            isThreeLine: c.notes != null,
                            onTap: () => _openSheet(settings, existing: c),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(c),
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
