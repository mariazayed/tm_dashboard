import 'package:flutter/material.dart';

import '../../models/invest/contribution_model.dart';
import '../../models/invest/holding_model.dart';
import '../../models/invest/invest_settings_model.dart';
import '../../models/invest/money.dart';
import '../../services/contribution_service.dart';
import '../../widgets/form_number_field.dart';
import '../../widgets/form_text_area_field.dart';

/// Add or edit one contribution. Shares and price fill each other in so you
/// only have to type what your broker shows; either can be overridden.
class AddContributionSheet extends StatefulWidget {
  const AddContributionSheet({
    super.key,
    required this.settings,
    this.existing,
    this.holdings = const [],
    this.defaultHoldingId,
    ContributionService? service,
  }) : _service = service;

  final InvestSettingsModel settings;
  final ContributionModel? existing;

  /// The funds to choose from. Empty from a server that predates funds: the
  /// plan's own ticker is used and no choice is shown.
  final List<HoldingModel> holdings;

  /// The fund to start on for a new buy, such as the one bought last time.
  final int? defaultHoldingId;
  final ContributionService? _service;

  @override
  State<AddContributionSheet> createState() => _AddContributionSheetState();
}

class _AddContributionSheetState extends State<AddContributionSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _price;
  late final TextEditingController _shares;
  late final TextEditingController _fee;
  late final TextEditingController _notes;
  late DateTime _date;
  bool _sharesEdited = false;
  bool _updatingShares = false;
  bool _saving = false;
  String? _error;
  int? _holdingId;

  bool get _isEdit => widget.existing != null;

  /// The ticker of the chosen fund, else the plan's.
  String get _ticker {
    for (final h in widget.holdings) {
      if (h.id == _holdingId) return h.ticker;
    }
    return widget.settings.ticker;
  }

  ContributionService get _service =>
      widget._service ?? ContributionService.shared;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    _date = e?.contributedOn ?? DateTime(now.year, now.month, now.day);
    _amount = TextEditingController(
      text: Money.plain(e?.amountCents ?? widget.settings.monthlyAmountCents),
    );
    _price = TextEditingController(text: e == null ? '' : '${e.price}');
    _shares = TextEditingController(text: e == null ? '' : '${e.shares}');
    _fee = TextEditingController(
      text: e == null ? '' : Money.plain(e.feeCents),
    );
    _notes = TextEditingController(text: e?.notes ?? '');
    final wanted = e?.holdingId ?? widget.defaultHoldingId;
    _holdingId = widget.holdings.any((h) => h.id == wanted)
        ? wanted
        : (widget.holdings.isEmpty ? null : widget.holdings.first.id);
    _sharesEdited = e != null;
    _amount.addListener(_recalculate);
    _price.addListener(_recalculate);
    _shares.addListener(() {
      if (!_updatingShares) _sharesEdited = true;
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _price.dispose();
    _shares.dispose();
    _fee.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _recalculate() {
    if (_sharesEdited) return;
    final cents = Money.parseCents(_amount.text);
    final price = double.tryParse(_price.text);
    if (cents == null || price == null) return;
    final shares = ContributionMath.sharesFor(cents, price);
    if (shares == null) return;
    _updatingShares = true;
    _shares.text = shares.toStringAsFixed(8);
    _updatingShares = false;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Map<String, dynamic>? _buildPayload() {
    final cents = Money.parseCents(_amount.text);
    final price = double.tryParse(_price.text);
    final shares = double.tryParse(_shares.text);
    final feeText = _fee.text.trim();
    final fee = feeText.isEmpty ? 0 : Money.parseCents(feeText);
    if (cents == null || cents <= 0) {
      setState(() => _error = 'Enter an amount like 300 or 300.00');
      return null;
    }
    if (price == null || price <= 0) {
      setState(() => _error = 'Enter the price per share');
      return null;
    }
    if (shares == null || shares <= 0) {
      setState(() => _error = 'Enter the number of shares');
      return null;
    }
    if (fee == null) {
      setState(() => _error = 'Fee must be an amount like 0 or 1.50');
      return null;
    }
    return {
      'contributedOn': ContributionModel.dateString(_date),
      'amountCents': cents,
      'shares': shares,
      'price': price,
      'feeCents': fee,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      if (_holdingId != null) 'holdingId': _holdingId,
    };
  }

  Future<void> _submit() async {
    final payload = _buildPayload();
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit contribution' : 'Add contribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('date-button'),
              onPressed: _pickDate,
              child: Text(ContributionModel.dateString(_date)),
            ),
            const SizedBox(height: 12),
            FormNumberField(
              label: 'Amount (${widget.settings.currency})',
              controller: _amount,
            ),
            if (widget.holdings.length > 1) ...[
              DropdownButtonFormField<int>(
                key: const Key('fund-picker'),
                initialValue: _holdingId,
                decoration: const InputDecoration(labelText: 'Fund'),
                items: [
                  for (final h in widget.holdings)
                    DropdownMenuItem(value: h.id, child: Text(h.title)),
                ],
                onChanged: (v) => setState(() => _holdingId = v),
              ),
              const SizedBox(height: 12),
            ],
            FormNumberField(
              label: 'Price per $_ticker share',
              controller: _price,
            ),
            FormNumberField(label: 'Shares', controller: _shares),
            FormNumberField(label: 'Fee (optional)', controller: _fee),
            FormTextAreaField(label: 'Notes (optional)', controller: _notes),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  key: const Key('form-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
