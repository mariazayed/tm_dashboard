import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tm_dashboard/services/capital_service.dart';

import '../../enums/capital_reason_enum.dart';
import '../../models/capital_model.dart';

/// ------------------------------
/// Capital Overview Screen
/// ------------------------------
/// - Fetches all capital records from server
/// - Lists them chronologically
/// - Shows Daily / Weekly / Monthly summary
/// - Deposit & Withdraw actions with dialogs

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CapitalManagementScreen extends StatefulWidget {
  const CapitalManagementScreen({super.key});

  @override
  State<CapitalManagementScreen> createState() =>
      _CapitalManagementScreenState();
}

class _CapitalManagementScreenState
    extends State<CapitalManagementScreen> {
  bool _loading = true;
  final List<CapitalModel> _capitals = [];

  @override
  void initState() {
    super.initState();
    _fetchCapitals();
  }

  Future<void> _fetchCapitals() async {
    await Future.delayed(const Duration(milliseconds: 300));

    _capitals.addAll([
      CapitalModel(
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        reason: CapitalReasonEnum.DEPOSIT,
        amount: 5000,
        notes: 'Initial funding',
      ),
      CapitalModel(
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        reason: CapitalReasonEnum.WITHDRAW,
        amount: -120,
        notes: 'Broker commission',
      ),
    ]);

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Capital Management',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _TableHeader(),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                itemCount: _capitals.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 4),
                itemBuilder: (_, i) =>
                    _CapitalRow(_capitals[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDADDE3)),
      ),
      child: const Row(
        children: [
          _HeaderCell('DATE', flex: 2),
          _HeaderCell('TYPE'),
          _HeaderCell('NOTES', flex: 3),
          _HeaderCell('AMOUNT', align: TextAlign.right),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;

  const _HeaderCell(
      this.text, {
        this.flex = 1,
        this.align = TextAlign.left,
      });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}


class _CapitalRow extends StatelessWidget {
  final CapitalModel capital;

  const _CapitalRow(this.capital);

  @override
  Widget build(BuildContext context) {
    final isPositive = capital.amount >= 0;
    final amountColor =
    isPositive ? const Color(0xFF1A7F37) : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E4EA)),
      ),
      child: Row(
        children: [
          _Cell(
            DateFormat('yyyy-MM-dd HH:mm')
                .format(capital.dateTime),
            flex: 2,
          ),
          _Cell(capital.reason.name),
          _Cell(capital.notes ?? '-', flex: 3),
          _Cell(
            capital.amount.toStringAsFixed(2),
            align: TextAlign.right,
            color: amountColor,
            mono: true,
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  final Color? color;
  final bool mono;

  const _Cell(
      this.text, {
        this.flex = 1,
        this.align = TextAlign.left,
        this.color,
        this.mono = false,
      });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
          color: color ?? Colors.black87,
          fontFamily: mono ? 'monospace' : null,
        ),
      ),
    );
  }
}



/// ------------------------------
/// Summary Models & Widgets
/// ------------------------------

class SummaryData {
  final double profits;
  final double losses;
  final double pnl;

  SummaryData({required this.profits, required this.losses, required this.pnl});
}

class _SummarySection extends StatelessWidget {
  final SummaryData daily;
  final SummaryData weekly;
  final SummaryData monthly;
  final bool wide;

  const _SummarySection({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ElegantSummaryCard(title: 'Today', data: daily),
      _ElegantSummaryCard(title: 'This Week', data: weekly),
      _ElegantSummaryCard(title: 'This Month', data: monthly),
    ];

    return GridView.count(
      crossAxisCount: wide ? 3 : 1,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

class _ElegantSummaryCard extends StatelessWidget {
  final String title;
  final SummaryData data;

  const _ElegantSummaryCard({
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final pnlColor = data.pnl >= 0 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            pnlColor.withOpacity(0.15),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: pnlColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          /// PnL
          Text(
            data.pnl.toStringAsFixed(2),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: pnlColor,
            ),
          ),
          const SizedBox(height: 8),

          /// Breakdown
          Row(
            children: [
              _MiniStat(
                label: 'Profit',
                value: data.profits,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Loss',
                value: data.losses,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


/// ------------------------------
/// Capital List
/// ------------------------------

class _CapitalList extends StatelessWidget {
  final List<CapitalModel> capitals;

  const _CapitalList({required this.capitals});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: capitals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = capitals[i];
        final isPositive = c.amount >= 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPositive
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header row
              Row(
                children: [
                  Icon(
                    isPositive
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.reason.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    c.amount.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              /// Date
              Text(
                c.dateTime.toLocal().toString(),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey),
              ),

              /// Notes (optional)
              if (c.notes != null && c.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.notes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}


