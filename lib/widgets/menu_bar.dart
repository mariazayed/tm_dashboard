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
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),

          /// Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: const [
                Text(
                  "TM 🧠",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          /// Scrollable menu area
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: _menuItems(context, location)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _menuItems(BuildContext context, String location) {
    final items = _menus(context);

    return items.map((item) {
      if (item.hasChildren) {
        final hasSelectedChild = item.children!.any(
          (child) => _isActiveRoute(context, location, child.routeName),
        );

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: hasSelectedChild,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.only(bottom: 6),
            iconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            collapsedIconColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            title: Text(
              item.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: hasSelectedChild
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            children: item.children!
                .map((child) => _buildLeaf(context, child, location))
                .toList(),
          ),
        );
      }

      return _buildLeaf(context, item, location);
    }).toList();
  }

  Widget _buildLeaf(BuildContext context, _MenuItem item, String location) {
    final isSelected = _isActiveRoute(context, location, item.routeName);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.goNamed(item.routeName!),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);

    Widget buildLeaf(_MenuItem item) {
      final isSelected = _isActiveRoute(context, location, item.routeName);

      return ListTile(
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          Navigator.pop(context);
          context.goNamed(item.routeName!);
        },
      );
    }

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
                  if (item.hasChildren) {
                    final hasSelectedChild = item.children!.any(
                      (child) =>
                          _isActiveRoute(context, location, child.routeName),
                    );

                    return ExpansionTile(
                      initiallyExpanded: hasSelectedChild,
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: hasSelectedChild
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: hasSelectedChild
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      children: item.children!.map(buildLeaf).toList(),
                    );
                  }

                  return buildLeaf(item);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compares the current router location against the location a named
/// route resolves to. `GoRouterState.of(context).name`/`.path` only
/// reflect the specific route level a widget happens to be built at
/// (e.g. inside a ShellRoute they can be null even on a matched sub-route),
/// while `.uri` always reflects the full current location, so we resolve
/// each menu item's target path via [GoRouter.namedLocation] and compare
/// full paths instead.
bool _isActiveRoute(BuildContext context, String location, String? routeName) {
  if (routeName == null) return false;
  final target = Uri.parse(GoRouter.of(context).namedLocation(routeName)).path;
  return location == target;
}

class _MenuItem {
  final String label;
  final String? routeName;
  final List<_MenuItem>? children;

  bool get hasChildren => children != null && children!.isNotEmpty;

  _MenuItem({required this.label, this.routeName, this.children});
}

List<_MenuItem> _menus(BuildContext context) {
  return [
    _MenuItem(label: 'Home', routeName: RouteNames.home),
    _MenuItem(label: 'Calendar', routeName: RouteNames.calendar),
    _MenuItem(label: 'Trades', routeName: RouteNames.trades),
    _MenuItem(label: 'Goals', routeName: RouteNames.goals),
    _MenuItem(label: 'Deposits & Withdraws', routeName: RouteNames.capital),
    _MenuItem(label: 'Decisions', routeName: RouteNames.decisions),
    _MenuItem(
      label: 'Rules',
      children: [
        _MenuItem(label: 'Strict Rules', routeName: RouteNames.strictRules),
        _MenuItem(label: 'Reminder Notes', routeName: RouteNames.reminderNotes),
      ],
    ),
    _MenuItem(
      label: 'Others',
      children: [
        _MenuItem(label: 'Strategies', routeName: RouteNames.strategies),
        _MenuItem(
          label: 'Risk Management',
          routeName: RouteNames.riskManagement,
        ),
        _MenuItem(label: 'Assets', routeName: RouteNames.assets),
      ],
    ),
  ];
}
