import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm_dashboard/constants/app_theme.dart';
import 'package:tm_dashboard/screens/calendar/calendar_screen.dart';

import 'screens/calendar/calendar_state.dart';
import 'configs/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalendarCubit(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'TM Dashboard',
        theme: AppTheme().getTheme(),
        routerConfig: routes,
      ),
    );
  }
}
