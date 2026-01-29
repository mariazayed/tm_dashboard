import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/memoir_model.dart';
import 'memoir_card.dart';
import 'memoir_state.dart';

class DaySection extends StatelessWidget {
  final DateTime date;
  final List<MemoirModel> entries;
  final MemoirBloc bloc;

  const DaySection({super.key,
    required this.date,
    required this.entries,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            DateFormat('EEEE • MMM d, y').format(date),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ),
        ...entries.map((e) => MemoirCard(entry: e, bloc: bloc)),
      ],
    );
  }
}
