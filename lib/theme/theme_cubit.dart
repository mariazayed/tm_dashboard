import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the user's light/dark/system theme choice.
///
/// Follows the same Cubit pattern the rest of the app already uses for
/// screen-level state (see `CalendarCubit`) rather than introducing a
/// second state-management approach just for this. Restores the saved
/// choice on construction and writes back on every change, via
/// `shared_preferences`, so it survives an app restart.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _restore();
  }

  static const _prefsKey = 'theme_mode';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final restored = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
    if (restored != state) emit(restored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  /// Cycles light -> dark -> system -> light..., used by the sidebar's
  /// theme toggle button.
  Future<void> cycle() {
    const order = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    final next = order[(order.indexOf(state) + 1) % order.length];
    return setThemeMode(next);
  }
}
