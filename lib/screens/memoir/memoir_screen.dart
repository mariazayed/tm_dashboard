import 'package:flutter/material.dart';

import 'memoir_state.dart';
import 'memoir_widget.dart';

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


