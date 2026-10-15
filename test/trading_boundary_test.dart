import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tm_dashboard/configs/feature_gate.dart';

/// Keeps trading code behind the feature gate. These are source-level checks
/// (no widgets), so a trading screen cannot quietly be wired into investing
/// or into an ungated route without this test failing.
const _tradingScreenDirs = [
  'calendar',
  'trade_journal',
  'trade_list',
  'trade_review',
  'trading_hours',
  'risk_management',
  'strategies',
  'assets',
  'dashboard',
];

const _tradingServices = [
  'trade_service',
  'trade_calculator_service',
  'day_service',
  'strategy_service',
  'asset_service',
  'memoir_service',
];

const _tradingModels = [
  'trade_model',
  'day_model',
  'strategy_model',
  'asset_model',
  'memoir_model',
];

/// Files outside the trading folders that are allowed to reach into them,
/// and why. Add to this list only with a reason.
const _mayImportTradingScreens = {
  'lib/configs/routes.dart': 'declares the (gated) trading routes',
  'lib/main.dart': 'provides CalendarCubit, which is trading-only state',
  'lib/screens/capital/capital_screen.dart':
      'reuses capital_list.dart and capital_stat_card.dart from the dashboard. '
      'Move those two widgets to lib/widgets before deleting the dashboard',
};

const _mayImportTradingModels = {
  'lib/services/capital_service.dart': 'capital still maps trade P&L rows',
  'lib/services/reminder_notes_service.dart': 'notes can reference a trade',
};

final _importRe = RegExp(r'''^import\s+['"]([^'"]+)['"]''', multiLine: true);

/// Normalised `lib/...` paths of every file [file] imports from this project.
List<String> _importsOf(File file) {
  final rel = file.path.replaceAll('\\', '/');
  final out = <String>[];
  for (final m in _importRe.allMatches(file.readAsStringSync())) {
    final target = m.group(1)!;
    if (target.startsWith('package:tm_dashboard/')) {
      out.add('lib/${target.substring('package:tm_dashboard/'.length)}');
    } else if (!target.contains(':')) {
      out.add(
        Uri.parse(rel).resolve(target).path.replaceFirst(RegExp(r'^/+'), ''),
      );
    }
  }
  return out;
}

List<File> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

String _rel(File f) => f.path.replaceAll('\\', '/');

bool _inTradingScreens(String path) =>
    _tradingScreenDirs.any((d) => path.startsWith('lib/screens/$d/'));

bool _isTradingService(String path) =>
    _tradingServices.any((s) => path == 'lib/services/$s.dart');

bool _isTradingModel(String path) =>
    _tradingModels.any((m) => path == 'lib/models/$m.dart');

bool _isInvesting(String path) =>
    path.startsWith('lib/screens/invest/') ||
    path.startsWith('lib/models/invest/') ||
    const [
      'contribution_service',
      'journal_service',
      'learning_service',
      'plan_service',
      'ai_chat_service',
    ].any((s) => path == 'lib/services/$s.dart');

void main() {
  final files = _dartFiles();

  test('the scan finds the code it is supposed to guard', () {
    expect(files.length, greaterThan(100));
    expect(files.any((f) => _inTradingScreens(_rel(f))), isTrue);
    expect(files.any((f) => _isInvesting(_rel(f))), isTrue);
  });

  test('investing code never imports trading code', () {
    final offenders = <String>[];
    for (final f in files.where((f) => _isInvesting(_rel(f)))) {
      for (final i in _importsOf(f)) {
        if (_inTradingScreens(i) || _isTradingService(i) || _isTradingModel(i)) {
          offenders.add('${_rel(f)} -> $i');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('only the allow-listed files import trading screens', () {
    final offenders = <String>[];
    for (final f in files) {
      final path = _rel(f);
      if (_inTradingScreens(path) || _mayImportTradingScreens.containsKey(path)) {
        continue;
      }
      for (final i in _importsOf(f)) {
        if (_inTradingScreens(i)) offenders.add('$path -> $i');
      }
    }
    expect(offenders, isEmpty);
  });

  test('trading services are only used by trading code', () {
    final offenders = <String>[];
    for (final f in files) {
      final path = _rel(f);
      if (_inTradingScreens(path) || _isTradingService(path)) continue;
      for (final i in _importsOf(f)) {
        if (_isTradingService(i)) offenders.add('$path -> $i');
      }
    }
    expect(offenders, isEmpty);
  });

  test('trading models are only used by trading code and the allow-list', () {
    final offenders = <String>[];
    for (final f in files) {
      final path = _rel(f);
      if (_inTradingScreens(path) ||
          _isTradingService(path) ||
          _isTradingModel(path) ||
          _mayImportTradingModels.containsKey(path)) {
        continue;
      }
      for (final i in _importsOf(f)) {
        if (_isTradingModel(i)) offenders.add('$path -> $i');
      }
    }
    expect(offenders, isEmpty);
  });

  test('every route that builds a trading screen is hidden by the gate', () {
    final routes = File('lib/configs/routes.dart').readAsStringSync();
    final routeRe = RegExp(
      r'name:\s*RouteNames\.(\w+),\s*path:\s*\x27([^\x27]*)\x27,\s*'
      r'builder:\s*\(context,\s*state\)\s*=>\s*(?:const\s+)?(\w+)\(',
    );
    final matches = routeRe.allMatches(routes).toList();
    expect(matches.length, greaterThan(15), reason: 'route regex stopped matching');

    // class name -> defining file
    final classRe = RegExp(r'^class\s+(\w+)', multiLine: true);
    final definedIn = <String, String>{};
    for (final f in files) {
      for (final m in classRe.allMatches(f.readAsStringSync())) {
        definedIn[m.group(1)!] = _rel(f);
      }
    }

    final unguarded = <String>[];
    for (final m in matches) {
      final name = m.group(1)!;
      final path = m.group(2)!;
      final screenFile = definedIn[m.group(3)!];
      if (screenFile == null || !_inTradingScreens(screenFile)) continue;
      final fullPath = path.isEmpty || path == '/' ? '/' : '/$path';
      final redirected =
          tradingRedirect(fullPath, tradingEnabled: false) == investingHomePath;
      if (!redirected || !isTradingRouteName(name)) {
        unguarded.add('$name ($fullPath)');
      }
    }
    expect(unguarded, isEmpty, reason: 'add these to feature_gate.dart');
  });
}
