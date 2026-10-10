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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isLight
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight
              ? colorScheme.outlineVariant
              : colorScheme.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          QuadcopterLogo(size: 32, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Розрахунок сітки частот без завад та інтермодуляції',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Δf ≥ 40 MHz • IMD3 ≥ 10 MHz • RHCP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary.withValues(alpha: 0.9),
                    fontFamily: 'monospace',
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
