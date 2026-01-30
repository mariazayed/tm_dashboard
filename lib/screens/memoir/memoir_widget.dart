import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/memoir_model.dart';
import 'day_section.dart';
import 'memoir_state.dart';

class MemoirWidget extends StatelessWidget {
  final MemoirBloc bloc;
  final MemoirState state;

  const MemoirWidget({super.key, required this.bloc, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final grouped = groupByDate(state.entries);
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    return Scaffold(
      appBar: AppBar(title: const Text('Memoir Calendar')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final entries = grouped[date]!;

          return DaySection(date: date, entries: entries, bloc: bloc);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
        onPressed: () => openEditor(context),
      ),
    );
  }

  void openEditor(BuildContext context, {MemoirModel? entry}) {
    final isNew = entry == null;
    final titleCtrl = TextEditingController(text: entry?.title ?? '');
    final descCtrl = TextEditingController(text: entry?.description ?? '');
    var date = entry?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isNew ? 'New Entry' : 'Edit Entry',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Text(DateFormat.yMMMd().format(date)),
                    const Spacer(),
                    TextButton(
                      child: const Text('Change'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => date = picked);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    final newEntry = MemoirModel(
                      id: isNew
                          ? DateTime.now().millisecondsSinceEpoch
                          : entry!.id,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      date: date,
                    );

                    bloc.eventSink.add(
                      isNew ? AddEntry(newEntry) : UpdateEntry(newEntry),
                    );

                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<DateTime, List<MemoirModel>> groupByDate(List<MemoirModel> entries) {
    final map = <DateTime, List<MemoirModel>>{};

    for (final e in entries) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      map.putIfAbsent(key, () => []).add(e);
    }

    return map;
  }
}
