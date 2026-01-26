import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ----------------------------
/// Models
/// ----------------------------

enum MemoirMode {
  personal,
  work,
  learning,
  travel,
  milestone,
  reflection,
}

class MemoirEntry {
  final String id;
  String title;
  String description;
  DateTime date;
  MemoirMode mode;
  List<String> tags;
  List<String> attachments;
  bool expanded;

  MemoirEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.mode,
    this.tags = const [],
    this.attachments = const [],
    this.expanded = false,
  });

  MemoirEntry copyWith({
    String? title,
    String? description,
    DateTime? date,
    MemoirMode? mode,
    List<String>? tags,
    List<String>? attachments,
    bool? expanded,
  }) {
    return MemoirEntry(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      mode: mode ?? this.mode,
      tags: tags ?? List.from(this.tags),
      attachments: attachments ?? List.from(this.attachments),
      expanded: expanded ?? this.expanded,
    );
  }
}

/// ----------------------------
/// BLoC (no packages)
/// ----------------------------

abstract class MemoirEvent {}
class LoadSample extends MemoirEvent {}
class ToggleExpand extends MemoirEvent {
  final String id;
  ToggleExpand(this.id);
}
class SearchQuery extends MemoirEvent {
  final String q;
  SearchQuery(this.q);
}
class FilterByTag extends MemoirEvent {
  final String? tag;
  FilterByTag(this.tag);
}
class ToggleRTL extends MemoirEvent {}
class ToggleForceLight extends MemoirEvent {}
class AddEntry extends MemoirEvent {
  final MemoirEntry entry;
  AddEntry(this.entry);
}
class UpdateEntry extends MemoirEvent {
  final MemoirEntry entry;
  UpdateEntry(this.entry);
}
class DeleteEntry extends MemoirEvent {
  final String id;
  DeleteEntry(this.id);
}

class MemoirState {
  final List<MemoirEntry> entries;
  final String searchQuery;
  final String? tagFilter;
  final bool rtl;
  final bool forceLight;

  MemoirState({
    this.entries = const [],
    this.searchQuery = '',
    this.tagFilter,
    this.rtl = false,
    this.forceLight = false,
  });

  MemoirState copyWith({
    List<MemoirEntry>? entries,
    String? searchQuery,
    String? tagFilter,
    bool? rtl,
    bool? forceLight,
  }) {
    return MemoirState(
      entries: entries ?? List.from(this.entries),
      searchQuery: searchQuery ?? this.searchQuery,
      tagFilter: tagFilter ?? this.tagFilter,
      rtl: rtl ?? this.rtl,
      forceLight: forceLight ?? this.forceLight,
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

  void _mapEvent(MemoirEvent e) {
    if (e is LoadSample) {
      _emit(_state.copyWith(entries: _sampleData()));
    } else if (e is ToggleExpand) {
      _emit(_state.copyWith(
        entries: _state.entries.map((it) {
          if (it.id == e.id) return it.copyWith(expanded: !it.expanded);
          return it;
        }).toList(),
      ));
    } else if (e is SearchQuery) {
      _emit(_state.copyWith(searchQuery: e.q));
    } else if (e is FilterByTag) {
      _emit(_state.copyWith(tagFilter: e.tag));
    } else if (e is ToggleRTL) {
      _emit(_state.copyWith(rtl: !_state.rtl));
    } else if (e is ToggleForceLight) {
      _emit(_state.copyWith(forceLight: !_state.forceLight));
    } else if (e is AddEntry) {
      final list = List<MemoirEntry>.from(_state.entries)..add(e.entry);
      _emit(_state.copyWith(entries: list));
    } else if (e is UpdateEntry) {
      _emit(_state.copyWith(
        entries: _state.entries.map((it) {
          if (it.id == e.entry.id) return e.entry;
          return it;
        }).toList(),
      ));
    } else if (e is DeleteEntry) {
      _emit(_state.copyWith(
        entries: _state.entries.where((e2) => e2.id != e.id).toList(),
      ));
    }
  }

  void dispose() {
    _stateController.close();
    _eventController.close();
  }

  List<MemoirEntry> _sampleData() {
    final now = DateTime.now();
    return [
      MemoirEntry(
        id: 'm1',
        title: 'The Idea Was Born',
        description: 'I realized this should be a memoir, not a planner.',
        date: now.subtract(const Duration(days: 60)),
        mode: MemoirMode.milestone,
        tags: ['idea', 'vision'],
        attachments: ['notes.pdf'],
      ),
      MemoirEntry(
        id: 'm2',
        title: 'First Working Timeline',
        description: 'Seeing memories ordered by time felt powerful.',
        date: now.subtract(const Duration(days: 30)),
        mode: MemoirMode.work,
        tags: ['flutter', 'timeline'],
      ),
      MemoirEntry(
        id: 'm3',
        title: 'Reflection',
        description: 'Removing the Gantt was the best decision.',
        date: now.subtract(const Duration(days: 7)),
        mode: MemoirMode.reflection,
        tags: ['lesson', 'architecture'],
      ),
    ];
  }
}

/// ----------------------------
/// App
/// ----------------------------

class MemoirScreen extends StatefulWidget {
  const MemoirScreen({Key? key}) : super(key: key);

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

/// ----------------------------
/// Screen
/// ----------------------------

class MemoirWidget extends StatelessWidget {
  final MemoirBloc bloc;
  final MemoirState state;

  const MemoirWidget({Key? key, required this.bloc, required this.state})
      : super(key: key);

  List<MemoirEntry> get filtered {
    final q = state.searchQuery.toLowerCase();
    return state.entries.where((e) {
      if (state.tagFilter != null &&
          state.tagFilter!.isNotEmpty &&
          !e.tags.contains(state.tagFilter)) return false;
      if (q.isEmpty) return true;
      return '${e.title} ${e.description} ${e.tags.join(' ')}'
          .toLowerCase()
          .contains(q);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Memoir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_textdirection_r_to_l),
            onPressed: () => bloc.eventSink.add(ToggleRTL()),
          ),
          IconButton(
            icon: Icon(
              state.forceLight
                  ? Icons.light_mode
                  : Icons.light_mode_outlined,
            ),
            onPressed: () => bloc.eventSink.add(ToggleForceLight()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => bloc.eventSink.add(SearchQuery(v)),
              decoration: InputDecoration(
                hintText: 'Search memories...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (c, i) =>
                  _MemoirCard(entry: filtered[i], bloc: bloc),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
        onPressed: () => _openEditor(context),
      ),
    );
  }

  void _openEditor(BuildContext context, {MemoirEntry? entry}) {
    final isNew = entry == null;
    final titleCtrl = TextEditingController(text: entry?.title ?? '');
    final descCtrl = TextEditingController(text: entry?.description ?? '');
    final tagsCtrl =
    TextEditingController(text: (entry?.tags ?? []).join(','));
    DateTime date = entry?.date ?? DateTime.now();
    MemoirMode mode = entry?.mode ?? MemoirMode.personal;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(isNew ? 'New Entry' : 'Edit Entry',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                DropdownButtonFormField<MemoirMode>(
                  value: mode,
                  items: MemoirMode.values
                      .map((m) => DropdownMenuItem(
                      value: m, child: Text(describeEnum(m))))
                      .toList(),
                  onChanged: (v) => mode = v!,
                  decoration: const InputDecoration(labelText: 'Mode'),
                ),
                TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final newEntry = MemoirEntry(
                      id: isNew
                          ? DateTime.now().millisecondsSinceEpoch.toString()
                          : entry!.id,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      date: date,
                      mode: mode,
                      tags: tagsCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      attachments: entry?.attachments ?? [],
                    );
                    bloc.eventSink.add(
                        isNew ? AddEntry(newEntry) : UpdateEntry(newEntry));
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
}

/// ----------------------------
/// Card
/// ----------------------------

class _MemoirCard extends StatelessWidget {
  final MemoirEntry entry;
  final MemoirBloc bloc;

  const _MemoirCard({required this.entry, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(entry.mode);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => bloc.eventSink.add(ToggleExpand(entry.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_prettyDate(entry.date),
                  style: const TextStyle(color: Colors.grey)),
              const Spacer(),
              Chip(
                label: Text(describeEnum(entry.mode)),
                backgroundColor: color.withOpacity(0.15),
              )
            ]),
            const SizedBox(height: 8),
            Text(entry.title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (entry.expanded) ...[
              const SizedBox(height: 12),
              Text(entry.description),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: entry.tags.map((t) => Chip(label: Text('#$t'))).toList(),
              ),
            ]
          ]),
        ),
      ),
    );
  }

  Color _modeColor(MemoirMode m) {
    switch (m) {
      case MemoirMode.personal:
        return Colors.pink;
      case MemoirMode.work:
        return Colors.indigo;
      case MemoirMode.learning:
        return Colors.green;
      case MemoirMode.travel:
        return Colors.orange;
      case MemoirMode.milestone:
        return Colors.blue;
      case MemoirMode.reflection:
        return Colors.deepPurple;
    }
  }

  String _prettyDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}
