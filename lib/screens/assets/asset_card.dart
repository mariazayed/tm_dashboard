import 'package:flutter/material.dart';

import '../../models/asset_model.dart';
import '../../theme/app_theme.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  // True while a delete request for this asset is in flight (tracked by the
  // parent AssetScreen). Swaps the "..." menu for a small spinner and dims
  // the card so there's visible feedback while waiting on the server,
  // instead of the menu just silently doing nothing if tapped again --
  // same pattern as GoalCard/goals_screen.
  final bool busy;

  const AssetCard({
    super.key,
    required this.asset,
    this.onEdit,
    this.onDelete,
    this.busy = false,
  });

  /// Cycling accent palette for the per-asset avatar. Built from the theme
  /// so it follows light/dark mode -- pink and teal have no direct
  /// semantic-color equivalent, so they fall back to the closest available
  /// categorical accents ([AppSemanticColors.violet] / `.orange`).
  List<Color> _palette(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    return [
      colorScheme.primary, // indigo
      semantic.profit, // green
      semantic.info, // blue
      semantic.warning, // amber
      semantic.violet, // pink
      semantic.orange, // teal
    ];
  }

  Color _color(BuildContext context) {
    final palette = _palette(context);
    final sum = asset.symbol.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[sum % palette.length];
  }

  String get _initials {
    final letters = asset.symbol.replaceAll(RegExp(r'[^A-Za-z]'), '');
    final base = letters.isNotEmpty ? letters : asset.symbol;
    return base.length <= 2 ? base.toUpperCase() : base.substring(0, 2).toUpperCase();
  }

  String _formatContractSize(double v) {
    final s = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
    // Simple thousands separator -- avoids pulling in intl's NumberFormat
    // for what's otherwise a plain integer most of the time.
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _color(context);

    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _initials,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      asset.contractSize != null
                          ? '${_formatContractSize(asset.contractSize!)} / lot'
                          : 'Contract size not set',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            busy
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
