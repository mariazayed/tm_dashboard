import 'package:flutter/material.dart';

import '../../models/memoir_model.dart';
import 'memoir_state.dart';
import 'memoir_widget.dart';

class MemoirCard extends StatelessWidget {
  final MemoirModel entry;
  final MemoirBloc bloc;

  const MemoirCard({super.key, required this.entry, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    (context.findAncestorWidgetOfExactType<MemoirWidget>()
                    as MemoirWidget)
                        .openEditor(context, entry: entry);
                  },
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              entry.description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}