import 'package:flutter/material.dart';

class InDevelopment extends StatelessWidget{
  const InDevelopment({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(Icons.construction_rounded, size: 48, color: colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          "Under Development",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "This section will be available in a future update.",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}