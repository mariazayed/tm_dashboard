import 'package:flutter/material.dart';

import '../../models/invest/holding_model.dart';
import '../../services/contribution_service.dart';
import '../../services/holding_service.dart';
import '../../theme/app_semantic_colors.dart';
import 'invest_ui.dart';

/// The funds you buy, with the share of the portfolio you aim for in each.
/// Changes are saved straight away; they do not wait for the plan's Save button.
class FundsSection extends StatefulWidget {
  const FundsSection({super.key, HoldingService? service, this.onChanged})
    : _service = service;

  final HoldingService? _service;

  /// Called after a fund was added, changed or removed.
  final VoidCallback? onChanged;

  @override
  State<FundsSection> createState() => _FundsSectionState();
}

class _FundsSectionState extends State<FundsSection> {
  HoldingService get _service => widget._service ?? HoldingService.shared;
  List<HoldingModel>? _funds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final funds = await _service.list();
      if (mounted) {
        setState(() {
          _funds = funds;
          _error = null;
        });
      }
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) setState(() => _error = message);
    }
  }

  Future<void> _openSheet({HoldingModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FundSheet(
        existing: existing,
        suggestedTarget: existing == null
            ? (100 - HoldingModel.targetTotal(_funds ?? const [])).clamp(
                0.0,
                100.0,
              )
            : null,
        service: widget._service,
      ),
    );
    if (saved == true) {
      await _load();
      widget.onChanged?.call();
    }
  }

  Future<void> _delete(HoldingModel fund) async {
    final ok = await confirmDelete(
      context,
      title: 'Remove ${fund.ticker}?',
      message:
          'The fund is removed from your list. A fund that still has buys '
          'cannot be removed.',
    );
    if (!ok) return;
    try {
      await _service.delete(fund.id);
      await _load();
      widget.onChanged?.call();
    } on InvestApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } catch (_) {
      if (mounted) showToast(context, 'Could not reach the server');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final funds = _funds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Funds', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'What you buy each month, and the share of the portfolio you aim '
          'for in each. Every contribution belongs to one fund.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Text(_error!, key: const Key('funds-error'))
        else if (funds == null)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          for (final f in funds)
            ListTile(
              key: Key('fund-${f.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(f.title),
              subtitle: Text(_subtitle(f)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: Key('edit-fund-${f.id}'),
                    tooltip: 'Edit ${f.ticker}',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _openSheet(existing: f),
                  ),
                  IconButton(
                    key: Key('delete-fund-${f.id}'),
                    tooltip: 'Remove ${f.ticker}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: funds.length > 1 ? () => _delete(f) : null,
                  ),
                ],
              ),
            ),
          if (funds.length > 1) _targets(context, funds),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('add-fund'),
              onPressed: () => _openSheet(),
              icon: const Icon(Icons.add),
              label: const Text('Add a fund'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _targets(BuildContext context, List<HoldingModel> funds) {
    final total = HoldingModel.targetTotal(funds);
    final ok = (total - 100).abs() < 0.01;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        ok
            ? 'Targets add up to 100%.'
            : 'Targets add up to ${_pct(total)}%, not 100%.',
        key: const Key('targets-total'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ok ? null : context.semanticColors.warning,
        ),
      ),
    );
  }

  static String _subtitle(HoldingModel f) {
    final fees = f.expenseRatio == null
        ? ''
        : ' · fees ${_pct(f.expenseRatio!)}%';
    return '${f.assetClass.label} · ${f.region} · target ${_pct(f.targetPct)}%$fees';
  }

  /// 70 -> "70", 33.5 -> "33.5", 0.06 -> "0.06".
  static String _pct(double v) {
    final s = v.toStringAsFixed(3);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

/// Add or edit one fund.
class FundSheet extends StatefulWidget {
  const FundSheet({
    super.key,
    this.existing,
    this.suggestedTarget,
    HoldingService? service,
  }) : _service = service;

  final HoldingModel? existing;

  /// Pre-fills the target of a new fund (what is left to 100%).
  final double? suggestedTarget;
  final HoldingService? _service;

  @override
  State<FundSheet> createState() => _FundSheetState();
}

class _FundSheetState extends State<FundSheet> {
  late final TextEditingController _ticker;
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _expense;
  late AssetClass _class;
  late String _region;
  bool _saving = false;
  String? _error;

  HoldingService get _service => widget._service ?? HoldingService.shared;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _ticker = TextEditingController(text: e?.ticker ?? '');
    _name = TextEditingController(text: e?.name ?? '');
    _target = TextEditingController(
      text: e != null
          ? _FundsSectionState._pct(e.targetPct)
          : _FundsSectionState._pct(widget.suggestedTarget ?? 100),
    );
    _expense = TextEditingController(
      text: e?.expenseRatio == null
          ? ''
          : _FundsSectionState._pct(e!.expenseRatio!),
    );
    _class = e?.assetClass ?? AssetClass.equity;
    _region = e?.region ?? HoldingModel.regions.first;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _name.dispose();
    _target.dispose();
    _expense.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _payload() {
    final ticker = _ticker.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Za-z0-9.\-]{1,16}$').hasMatch(ticker)) {
      setState(() => _error = 'Ticker can use letters, digits, "." and "-"');
      return null;
    }
    final target = double.tryParse(_target.text.trim());
    if (target == null || target < 0 || target > 100) {
      setState(() => _error = 'The target is a share from 0 to 100');
      return null;
    }
    double? expense;
    if (_expense.text.trim().isNotEmpty) {
      expense = double.tryParse(_expense.text.trim());
      if (expense == null || expense < 0 || expense > 5) {
        setState(() => _error = 'Fees are a yearly percentage from 0 to 5');
        return null;
      }
    }
    return {
      'ticker': ticker,
      'name': _name.text.trim().isEmpty ? null : _name.text.trim(),
      'assetClass': _class.api,
      'region': _region,
      'targetPct': target,
      'expenseRatio': expense,
      'notes': widget.existing?.notes,
    };
  }

  Future<void> _submit() async {
    final payload = _payload();
    if (payload == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await _service.update(widget.existing!.id, payload);
      } else {
        await _service.create(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } on InvestApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the server');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final regions = {...HoldingModel.regions, _region}.toList();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit fund' : 'Add a fund',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('fund-ticker'),
              controller: _ticker,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Ticker',
                helperText: 'As your price source knows it, e.g. VT or BRK-B',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('fund-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AssetClass>(
              key: const Key('fund-class'),
              initialValue: _class,
              decoration: const InputDecoration(labelText: 'Kind'),
              items: [
                for (final c in AssetClass.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() => _class = v ?? _class),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('fund-region'),
              initialValue: _region,
              decoration: const InputDecoration(labelText: 'Region'),
              items: [
                for (final r in regions)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() => _region = v ?? _region),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('fund-target'),
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Target share of the portfolio (%)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('fund-expense'),
              controller: _expense,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Yearly fund charge (%, optional)',
                helperText: 'On the fund\'s factsheet, e.g. 0.06',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  key: const Key('fund-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('save-fund'),
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
