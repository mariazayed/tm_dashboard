// The theme system now lives in `lib/theme/` (colors, semantic tokens,
// component themes, and the light/dark mode cubit, split into one file
// each instead of one growing ThemeData literal). This re-export keeps any
// `import 'constants/app_theme.dart'` resolving to the same `AppTheme`.
export '../theme/app_theme.dart';
