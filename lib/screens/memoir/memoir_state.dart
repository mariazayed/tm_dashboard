import 'dart:async';

import '../../models/memoir_model.dart';
import '../../services/memoir_service.dart';

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
