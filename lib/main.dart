import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm_dashboard/constants/app_theme.dart';
import 'package:tm_dashboard/screens/calendar/calendar_screen.dart';

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
        theme: AppTheme().getTheme(),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE5E7EB),
                child: Icon(Icons.person_outline, size: 20, color: Color(0xFF374151)),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: const CalendarScreen(),
        ),
      ),
    );
  }
}
