import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';

export 'app_colors.dart';
export 'app_semantic_colors.dart';
export 'theme_cubit.dart';

/// Builds this app's light and dark [ThemeData].
///
/// Both share the same shape -- text styles, component themes, radii,
/// spacing -- and differ only in the color values they're built from (see
/// [_themeFor]), so a change to the visual language doesn't have to be
/// hand-mirrored between the two modes. [AppSemanticColors] is attached via
/// [ThemeData.extensions] so domain colors (profit/loss, chart chrome, the
/// sticky-note palette) follow the same light/dark switch as everything
/// else.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _themeFor(
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    semanticColors: AppSemanticColors.light,
    scaffoldBackground: Colors.white,
    cardColor: AppPalette.gray50,
    cardBorder: AppPalette.gray100,
    subtleFill: AppPalette.gray50,
    inputBorder: AppPalette.gray100,
    chipBackground: AppPalette.gray100,
    headlineColor: AppPalette.gray700,
    titleColor: AppPalette.gray600,
    bodyColor: AppPalette.gray500,
    iconColor: AppPalette.gray400,
    popoverColor: AppPalette.gray800,
    onPopoverColor: Colors.white,
  );

  static ThemeData get dark => _themeFor(
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    semanticColors: AppSemanticColors.dark,
    scaffoldBackground: AppPalette.gray950,
    cardColor: AppPalette.gray900,
    cardBorder: AppPalette.gray800,
    subtleFill: AppPalette.gray900,
    inputBorder: AppPalette.gray800,
    chipBackground: AppPalette.gray800,
    headlineColor: AppPalette.gray100,
    titleColor: AppPalette.gray200,
    bodyColor: AppPalette.gray400,
    iconColor: AppPalette.gray500,
    popoverColor: AppPalette.gray200,
    onPopoverColor: AppPalette.gray900,
  );

  static ColorScheme get _lightColorScheme => ColorScheme.fromSeed(
    seedColor: AppPalette.indigo400,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppPalette.indigo400,
    onPrimary: Colors.white,
    error: AppPalette.red500,
    surface: Colors.white,
    onSurface: AppPalette.gray700,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppPalette.gray50,
    surfaceContainer: AppPalette.gray50,
    surfaceContainerHigh: AppPalette.gray100,
    surfaceContainerHighest: AppPalette.gray100,
    onSurfaceVariant: AppPalette.gray500,
    outline: AppPalette.gray300,
    outlineVariant: AppPalette.gray100,
    shadow: Colors.black,
  );

  static ColorScheme get _darkColorScheme => ColorScheme.fromSeed(
    seedColor: AppPalette.indigo400,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppPalette.indigo300,
    onPrimary: AppPalette.gray900,
    error: AppPalette.red400,
    surface: AppPalette.gray900,
    onSurface: AppPalette.gray100,
    surfaceContainerLowest: AppPalette.gray950,
    surfaceContainerLow: AppPalette.gray900,
    surfaceContainer: AppPalette.gray900,
    surfaceContainerHigh: AppPalette.gray800,
    surfaceContainerHighest: AppPalette.gray800,
    onSurfaceVariant: AppPalette.gray400,
    outline: AppPalette.gray700,
    outlineVariant: AppPalette.gray800,
    shadow: Colors.black,
  );

  static ThemeData _themeFor({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required AppSemanticColors semanticColors,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color cardBorder,
    required Color subtleFill,
    required Color inputBorder,
    required Color chipBackground,
    required Color headlineColor,
    required Color titleColor,
    required Color bodyColor,
    required Color iconColor,
    required Color popoverColor,
    required Color onPopoverColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      extensions: [semanticColors],

      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: headlineColor,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: titleColor),
        bodyMedium: TextStyle(color: bodyColor),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scaffoldBackground,
        foregroundColor: headlineColor,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: headlineColor,
        ),
        iconTheme: IconThemeData(color: bodyColor),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cardBorder, width: 1),
        ),
      ),

      dividerTheme: DividerThemeData(color: cardBorder, space: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: subtleFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: iconColor, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: chipBackground,
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(color: titleColor, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w500,
        ),
        brightness: brightness,
        side: BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      iconTheme: IconThemeData(color: iconColor, size: 24),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      listTileTheme: ListTileThemeData(iconColor: iconColor, textColor: titleColor),

      drawerTheme: DrawerThemeData(backgroundColor: colorScheme.surface),

      // Tooltips and snackbars stay on an inverted surface in both modes --
      // that's what keeps a transient overlay readable regardless of what's
      // behind it, rather than following the page's own brightness.
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: popoverColor,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: onPopoverColor, fontSize: 12),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: popoverColor,
        contentTextStyle: TextStyle(color: onPopoverColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(iconColor.withValues(alpha: 0.4)),
      ),
    );
  }
}
