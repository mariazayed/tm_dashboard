import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'calendar_state.dart';


class Header extends StatelessWidget {
  const Header({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat.yMMMM().format(state.currentMonth),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Row(
                children: [
                  _HeaderButton(
                    icon: Icons.chevron_left,
                    onPressed: () => context.read<CalendarCubit>().previousMonth(),
                  ),
                  const SizedBox(width: 8),
                  _HeaderButton(
                    icon: Icons.chevron_right,
                    onPressed: () => context.read<CalendarCubit>().nextMonth(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF374151)),
        onPressed: onPressed,
      ),
    );
  }
}