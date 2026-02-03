import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_names.dart';

class MenuEntry {
  const MenuEntry({
    required this.label,
    this.shortcut,
    this.onPressed,
    this.menuChildren,
  }) : assert(
         menuChildren == null || onPressed == null,
         'onPressed is ignored if menuChildren are provided',
       );
  final String label;

  final MenuSerializableShortcut? shortcut;
  final VoidCallback? onPressed;
  final List<MenuEntry>? menuChildren;

  static List<Widget> build(List<MenuEntry> selections) {
    Widget buildSelection(MenuEntry selection) {
      if (selection.menuChildren != null) {
        return SubmenuButton(
          menuChildren: MenuEntry.build(selection.menuChildren!),
          child: Text(selection.label),
        );
      }
      return MenuItemButton(
        shortcut: selection.shortcut,
        onPressed: selection.onPressed,
        child: Text(selection.label),
      );
    }

    return selections.map<Widget>(buildSelection).toList();
  }

  static Map<MenuSerializableShortcut, Intent> shortcuts(
    List<MenuEntry> selections,
  ) {
    final Map<MenuSerializableShortcut, Intent> result =
        <MenuSerializableShortcut, Intent>{};
    for (final MenuEntry selection in selections) {
      if (selection.menuChildren != null) {
        result.addAll(MenuEntry.shortcuts(selection.menuChildren!));
      } else {
        if (selection.shortcut != null && selection.onPressed != null) {
          result[selection.shortcut!] = VoidCallbackIntent(
            selection.onPressed!,
          );
        }
      }
    }
    return result;
  }
}

class MainManu extends StatelessWidget {
  final Widget child;

  const MainManu({super.key, required this.child});

  static const double _drawerBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < _drawerBreakpoint;

        return Scaffold(
          appBar: isSmallScreen
              ? AppBar(
            title: const Text('TM 🧠'),
          )
              : null,

          drawer: isSmallScreen
              ? Drawer(
            child: SafeArea(
              child: ListView(
                children: _buildDrawerItems(context),
              ),
            ),
          )
              : null,

          body: Column(
            children: [
              // Top menu only on large screens
              if (!isSmallScreen)
                Row(
                  children: [
                    Expanded(
                      child: MenuBar(
                        children:
                        MenuEntry.build(_getMenus(context)),
                      ),
                    ),
                  ],
                ),

              // PAGE CONTENT
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  /// Drawer items
  List<Widget> _buildDrawerItems(BuildContext context) {
    return _getMenus(context)
        .map(
          (e) => ListTile(
        title: Text(e.label),
        onTap: () {
          Navigator.pop(context); // close drawer
          e.onPressed?.call();
        },
      ),
    )
        .toList();
  }

  /// Shared menu definition
  List<MenuEntry> _getMenus(BuildContext context) {
    return <MenuEntry>[
      MenuEntry(
        label: 'Home',
        onPressed: () => context.goNamed(RouteNames.home),
      ),
      MenuEntry(
        label: 'Calendar',
        onPressed: () => context.goNamed(RouteNames.calendar),
      ),
      MenuEntry(
        label: 'Memoir',
        onPressed: () => context.goNamed(RouteNames.memoir),
      ),
      MenuEntry(
        label: 'Trade Journaling',
        onPressed: () => context.goNamed(RouteNames.tradeJournal),
      ),
      MenuEntry(
        label: 'Risk Management',
        onPressed: () => context.goNamed(RouteNames.riskManagement),
      ),
      MenuEntry(
        label: 'Assets',
        onPressed: () => context.goNamed(RouteNames.assets),
      ),
      MenuEntry(
        label: 'Capitals',
        onPressed: () =>
            context.goNamed(RouteNames.capitalManagement),
      ),
      MenuEntry(
        label: 'Reminder Notes',
        onPressed: () =>
            context.goNamed(RouteNames.reminderNotes),
      ),
    ];
  }
}

