import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tm_dashboard/services/memoir_service.dart';

import '../../models/memoir_model.dart';

abstract class MemoirEvent {}

class LoadSample extends MemoirEvent {}

class ToggleExpand extends MemoirEvent {
  final int id;

  ToggleExpand(this.id);
}

class AddEntry extends MemoirEvent {
  final MemoirModel entry;

  AddEntry(this.entry);
}

class UpdateEntry extends MemoirEvent {
  final MemoirModel entry;

  UpdateEntry(this.entry);
}

class DeleteEntry extends MemoirEvent {
  final String id;

  DeleteEntry(this.id);
}

class MemoirState {
  final List<MemoirModel> entries;
  final bool loading;
  final String? error;

  MemoirState({this.entries = const [], this.loading = false, this.error});

  MemoirState copyWith({
    List<MemoirModel>? entries,
    bool? loading,
    String? error,
  }) {
    return MemoirState(
      entries: entries ?? List.from(this.entries),
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class MemoirBloc {
  final _stateController = StreamController<MemoirState>.broadcast();

  MemoirState _state = MemoirState();

  Stream<MemoirState> get stream => _stateController.stream;

  final _eventController = StreamController<MemoirEvent>();

  Sink<MemoirEvent> get eventSink => _eventController.sink;

  MemoirBloc() {
    _eventController.stream.listen(_mapEvent);
  }

  void _emit(MemoirState s) {
    _state = s;
    _stateController.add(_state);
  }

  Future<void> _mapEvent(MemoirEvent event) async {
    try {
      if (event is LoadSample) {
        _emit(_state.copyWith(loading: true));

        final memoirs = await MemoirService().getAll();

        _emit(_state.copyWith(entries: memoirs, loading: false));
      } else if (event is AddEntry) {
        final created = await MemoirService().create(event.entry);

        final updated = List<MemoirModel>.from(_state.entries)..add(created);

        _emit(_state.copyWith(entries: updated));
      } else if (event is UpdateEntry) {
        await MemoirService().update(event.entry.id, event.entry);

        final updated = _state.entries.map((m) {
          return m.id == event.entry.id ? event.entry : m;
        }).toList();

        _emit(_state.copyWith(entries: updated));
      }
    } catch (e) {
      _emit(_state.copyWith(loading: false, error: e.toString()));
    }
  }

  void dispose() {
    _stateController.close();
    _eventController.close();
  }
}

class MemoirScreen extends StatefulWidget {
  const MemoirScreen({super.key});

  @override
  State<MemoirScreen> createState() => _MemoirScreenState();
}

class _MemoirScreenState extends State<MemoirScreen> {
  late final MemoirBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MemoirBloc();
    bloc.eventSink.add(LoadSample());
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MemoirState>(
      stream: bloc.stream,
      initialData: MemoirState(),
      builder: (context, snapshot) {
        final state = snapshot.data!;
        return MemoirWidget(bloc: bloc, state: state);
      },
    );
  }
}

Map<DateTime, List<MemoirModel>> groupByDate(List<MemoirModel> entries) {
  final map = <DateTime, List<MemoirModel>>{};

  for (final e in entries) {
    final key = DateTime(e.date.year, e.date.month, e.date.day);
    map.putIfAbsent(key, () => []).add(e);
  }

  return map;
}

/// ----------------------------
/// Screen
/// ----------------------------

class MemoirWidget extends StatelessWidget {
  final MemoirBloc bloc;
  final MemoirState state;

  const MemoirWidget({super.key, required this.bloc, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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

          return _DaySection(
            date: date,
            entries: entries,
            bloc: bloc,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
        onPressed: () => _openEditor(context),
      ),
    );
  }

  void _openEditor(BuildContext context, {MemoirModel? entry}) {
    final isNew = entry == null;
    final titleCtrl = TextEditingController(text: entry?.title ?? '');
    final descCtrl = TextEditingController(text: entry?.description ?? '');
    DateTime date = entry?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isNew ? 'New Entry' : 'Edit Entry',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      if (picked != null) date = picked;
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
    );
  }
}

/// ----------------------------
/// Card
/// ----------------------------

class _MemoirCard extends StatelessWidget {
  final MemoirModel entry;
  final MemoirBloc bloc;

  const _MemoirCard({required this.entry, required this.bloc});

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
                  DateFormat.Hm().format(entry.date),
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    (context.findAncestorWidgetOfExactType<MemoirWidget>()
                    as MemoirWidget)
                        ._openEditor(context, entry: entry);
                  },
                ),
              ],
            ),

            Text(
              entry.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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

class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<MemoirModel> entries;
  final MemoirBloc bloc;

  const _DaySection({
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
        ...entries.map((e) => _MemoirCard(entry: e, bloc: bloc)),
      ],
    );
  }
}
