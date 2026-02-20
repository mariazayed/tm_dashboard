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

class MainMenu extends StatelessWidget {
  final Widget child;

  const MainMenu({super.key, required this.child});

  static const double _breakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < _breakpoint;

        return Scaffold(
          drawer: isSmallScreen ? _ModernDrawer() : null,
          appBar: isSmallScreen
              ? AppBar(title: const Text("TM 🧠"), elevation: 0)
              : null,
          body: Row(
            children: [
              if (!isSmallScreen) _ModernSidebar(),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModernSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).name;

    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "TM 🧠",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
          ..._menuItems(context, currentRoute),
        ],
      ),
    );
  }

  List<Widget> _menuItems(BuildContext context, String? currentRoute) {
    final items = _menus(context);

    return items.map((item) {
      final isSelected = currentRoute == item.routeName;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.goNamed(item.routeName),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                item.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _ModernDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).name;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              "TM 🧠",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 40),
            Expanded(
              child: ListView(
                children: _menus(context).map((item) {
                  final isSelected = currentRoute == item.routeName;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(item.label),
                    onTap: () {
                      Navigator.pop(context);
                      context.goNamed(item.routeName);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final String routeName;

  _MenuItem(this.label, this.routeName);
}

List<_MenuItem> _menus(BuildContext context) {
  return [
    _MenuItem('Home', RouteNames.home),
    _MenuItem('Calendar', RouteNames.calendar),
    _MenuItem('Memoir', RouteNames.memoir),
    _MenuItem('Trade Journaling', RouteNames.tradeJournal),
    _MenuItem('Risk Management', RouteNames.riskManagement),
    _MenuItem('Assets', RouteNames.assets),
    _MenuItem('Capitals', RouteNames.capitalManagement),
    _MenuItem('Reminder Notes', RouteNames.reminderNotes),
    _MenuItem('Strict Rules', RouteNames.strictRules),
    _MenuItem('Strategies', RouteNames.strategies),
  ];
}
