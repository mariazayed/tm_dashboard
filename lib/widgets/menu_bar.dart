import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_names.dart';
import '../theme/app_theme.dart';

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

class _ModernSidebar extends StatefulWidget {
  @override
  State<_ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<_ModernSidebar> {
  bool _collapsed = false;

  static const double _expandedWidth = 260;
  static const double _collapsedWidth = 76;

  void _toggleCollapsed() => setState(() => _collapsed = !_collapsed);

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: _collapsed ? _collapsedWidth : _expandedWidth,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),

            /// Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _collapsed ? 12 : 24),
              child: Row(
                mainAxisAlignment: _collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!_collapsed)
                    const Text(
                      "TM 🧠",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  _buildHeaderActions(context),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Scrollable menu area
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: _menuItems(context, location)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The sidebar header's icon button(s) -- the theme toggle and the
  /// collapse/expand toggle. Laid out side by side when the sidebar is
  /// expanded (there's room next to the "TM 🧠" wordmark) and stacked when
  /// it's collapsed (the rail is too narrow for two icons side by side).
  Widget _buildHeaderActions(BuildContext context) {
    final themeButton = BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final (icon, tooltip) = switch (mode) {
          ThemeMode.light => (
            Icons.light_mode_outlined,
            'Light theme · tap for dark',
          ),
          ThemeMode.dark => (
            Icons.dark_mode_outlined,
            'Dark theme · tap to follow system',
          ),
          ThemeMode.system => (
            Icons.brightness_auto_outlined,
            'Following system theme · tap for light',
          ),
        };

        return _HeaderIconButton(
          icon: icon,
          tooltip: tooltip,
          onTap: () => context.read<ThemeCubit>().cycle(),
        );
      },
    );

    final collapseButton = _HeaderIconButton(
      icon: _collapsed ? Icons.menu : Icons.menu_open,
      tooltip: _collapsed ? 'Expand sidebar' : 'Collapse sidebar',
      onTap: _toggleCollapsed,
    );

    if (_collapsed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [collapseButton, const SizedBox(height: 2), themeButton],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [themeButton, const SizedBox(width: 2), collapseButton],
    );
  }

  List<Widget> _menuItems(BuildContext context, String location) {
    final items = _menus(context);

    return items.map((item) {
      if (item.hasChildren) {
        final hasSelectedChild = item.children!.any(
          (child) => _isActiveRoute(context, location, child.routeName),
        );
        final iconColor = hasSelectedChild
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

        if (_collapsed) {
          // Collapsed: show only the group's icon. Tapping it expands the
          // sidebar again so its children become reachable.
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Tooltip(
              message: item.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _toggleCollapsed,
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 20, color: iconColor),
                ),
              ),
            ),
          );
        }

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: hasSelectedChild,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.only(bottom: 6),
            iconColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            collapsedIconColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            leading: item.icon != null
                ? Icon(item.icon, size: 20, color: iconColor)
                : null,
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
    final contentColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    final leaf = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.goNamed(item.routeName!),
      child: Container(
        height: 44,
        alignment: _collapsed ? Alignment.center : Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: _collapsed ? 0 : 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _collapsed
            ? Icon(item.icon, size: 20, color: contentColor)
            : Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 18, color: contentColor),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: _collapsed ? Tooltip(message: item.label, child: leaf) : leaf,
    );
  }
}

/// Small square icon button shared by the sidebar header's theme and
/// collapse toggles -- pulled out so both read the same size/tooltip/ripple
/// behavior instead of repeating the Tooltip+InkWell+Padding boilerplate.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
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
        leading: item.icon != null
            ? Icon(
                item.icon,
                color: isSelected ? theme.colorScheme.primary : null,
              )
            : null,
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.12),
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
                      leading: item.icon != null
                          ? Icon(
                              item.icon,
                              color: hasSelectedChild
                                  ? theme.colorScheme.primary
                                  : null,
                            )
                          : null,
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
  final IconData? icon;
  final List<_MenuItem>? children;

  bool get hasChildren => children != null && children!.isNotEmpty;

  _MenuItem({required this.label, this.routeName, this.icon, this.children});
}

List<_MenuItem> _menus(BuildContext context) {
  return [
    _MenuItem(
      label: 'Home',
      routeName: RouteNames.home,
      icon: Icons.space_dashboard_outlined,
    ),
    _MenuItem(
      label: 'Calendar',
      routeName: RouteNames.calendar,
      icon: Icons.calendar_month_outlined,
    ),
    _MenuItem(
      label: 'Trading Hours',
      routeName: RouteNames.tradingHours,
      icon: Icons.event_available_outlined,
    ),
    _MenuItem(
      label: 'Trades',
      routeName: RouteNames.trades,
      icon: Icons.show_chart_outlined,
    ),
    _MenuItem(
      label: 'Goals',
      routeName: RouteNames.goals,
      icon: Icons.flag_outlined,
    ),
    _MenuItem(
      label: 'Decisions',
      routeName: RouteNames.decisions,
      icon: Icons.fact_check_outlined,
    ),
    _MenuItem(
      label: 'Questions & Answers',
      routeName: RouteNames.questionsAnswers,
      icon: Icons.quiz_outlined,
    ),
    _MenuItem(
      label: 'Expenses',
      routeName: RouteNames.expenses,
      icon: Icons.receipt_long_outlined,
    ),
    _MenuItem(
      label: 'Others',
      icon: Icons.more_horiz_outlined,
      children: [
        _MenuItem(
          label: 'Assets',
          routeName: RouteNames.assets,
          icon: Icons.account_balance_wallet_outlined,
        ),
        _MenuItem(
          label: 'Deposits & Withdraws',
          routeName: RouteNames.capital,
          icon: Icons.swap_horiz_outlined,
        ),
        _MenuItem(
          label: 'Expense Reasons',
          routeName: RouteNames.expenseReasons,
          icon: Icons.sell_outlined,
        ),
        _MenuItem(
          label: 'Reminder Notes',
          routeName: RouteNames.reminderNotes,
          icon: Icons.push_pin_outlined,
        ),
        _MenuItem(
          label: 'Risk Management',
          routeName: RouteNames.riskManagement,
          icon: Icons.shield_outlined,
        ),
        _MenuItem(
          label: 'Strategies',
          routeName: RouteNames.strategies,
          icon: Icons.psychology_outlined,
        ),
        _MenuItem(
          label: 'Strict Rules',
          routeName: RouteNames.strictRules,
          icon: Icons.gavel_outlined,
        ),
      ],
    ),
  ];
}
