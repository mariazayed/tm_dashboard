import 'package:flutter/material.dart';

import '../../models/day_model.dart';
import '../../models/trade_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'calendar_state.dart';
import 'day_status.dart';
import 'day_trades_section.dart';

class DayEditDialog extends StatefulWidget {
  final DayModel day;
  final CalendarCubit cubit;
  final List<Trade> trades;

  const DayEditDialog({
    super.key,
    required this.day,
    required this.cubit,
    this.trades = const [],
  });

  @override
  State<DayEditDialog> createState() => _DayEditDialogState();
}

class _DayEditDialogState extends State<DayEditDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = Responsive.isMobile(context);
          final headerPadding = isMobile
              ? const EdgeInsets.fromLTRB(16, 20, 16, 12)
              : const EdgeInsets.fromLTRB(32, 24, 24, 16);
          final bodyPadding = isMobile ? 16.0 : 32.0;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: isMobile
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 16)
                : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Container(
              width: isMobile ? double.infinity : 1000,
              height: isMobile
                  ? MediaQuery.sizeOf(context).height * 0.9
                  : 800,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: headerPadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Day ${widget.day.date.day}",
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Day Overview",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: bodyPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DayStatus(day: widget.day, cubit: widget.cubit),
                          const SizedBox(height: 32),
                          DayTradesSection(trades: widget.trades),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
