import 'package:flutter/material.dart';

/// Raw color palette the app is built from.
///
/// These are not meant to be used directly in widgets -- reach for
/// [ColorScheme] roles (`Theme.of(context).colorScheme`) or
/// [AppSemanticColors] (`context.semanticColors`) instead, so every screen
/// automatically follows light/dark mode. This file exists purely so
/// [AppTheme]'s light and dark [ColorScheme]s and [AppSemanticColors] are
/// built from one source of truth instead of hex literals scattered across
/// every screen.
class AppPalette {
  AppPalette._();

  // --- Neutrals (the gray scale the original design was already built on)
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);
  static const gray950 = Color(0xFF0B0F17);

  // --- Brand (indigo)
  static const indigo300 = Color(0xFFA5B4FC);
  static const indigo400 = Color(0xFF818CF8);
  static const indigo500 = Color(0xFF6366F1);

  // --- Semantic accents
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);
  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const amber500 = Color(0xFFF59E0B);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const orange500 = Color(0xFFF97316);
  static const orange700 = Color(0xFFC2410C);
  static const violet500 = Color(0xFF8B5CF6);

  // --- Sticky-note pastels: light-mode originals plus muted dark-mode
  // counterparts (same hues, dropped to a low-luminance card fill so they
  // still read as distinct accents against a dark surface).
  static const noteYellowLight = Color(0xFFFFF9C4);
  static const noteBlueLight = Color(0xFFE3F2FD);
  static const noteGreenLight = Color(0xFFE8F5E9);
  static const notePinkLight = Color(0xFFFCE4EC);
  static const noteOrangeLight = Color(0xFFFFF3E0);
  static const notePurpleLight = Color(0xFFF3E5F5);

  static const noteYellowDark = Color(0xFF3F3A1E);
  static const noteBlueDark = Color(0xFF1E2A3F);
  static const noteGreenDark = Color(0xFF1B3324);
  static const notePinkDark = Color(0xFF3A1E2E);
  static const noteOrangeDark = Color(0xFF3A2A1B);
  static const notePurpleDark = Color(0xFF2C1E3A);
}
