import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tm_dashboard/screens/calendar/calendar_screen.dart';
import 'dart:math';

import 'bloc/calendar_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalendarCubit(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TM Dashboard',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Trade Mind Dashboard 🧠'),
          ),
          body: const CalendarScreen(),
        ),
      ),
    );
  }
}