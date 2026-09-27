import 'package:flutter/material.dart';

/// A quiet preview with manual paging and an expandable full note.
class DashboardNoteStrip extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color accent;
  final bool loading;
  final int index;
  final int count;
  final ValueChanged<int> onNavigate;

  const DashboardNoteStrip({
    super.key,
    required this.title,
    required this.text,
    required this.icon,
    required this.accent,
    required this.loading,
    required this.index,
    required this.count,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: Icon(icon, color: accent, size: 20),
            title: Text(title, style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text(
              loading ? 'Loading…' : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(loading ? 'Loading…' : text),
              ),
            ],
          ),
          if (count > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Previous $title',
                  onPressed: () => onNavigate(-1),
                  icon: const Icon(Icons.chevron_left, size: 18),
                ),
                Text(
                  '${index + 1} / $count',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                IconButton(
                  tooltip: 'Next $title',
                  onPressed: () => onNavigate(1),
                  icon: const Icon(Icons.chevron_right, size: 18),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
