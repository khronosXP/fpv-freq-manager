import 'package:flutter/material.dart';
import 'quadcopter_logo.dart';

class CalculatorHeaderBanner extends StatelessWidget {
  const CalculatorHeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isLight
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: isLight ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        children: [
          QuadcopterLogo(size: 32, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Розрахунок сітки частот без завад та інтермодуляції',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
