import 'package:flutter/material.dart';

class CalculatorFooter extends StatelessWidget {
  const CalculatorFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          Text(
            'FPV FREQ MANAGER • СИСТЕМА ЗАХИСТУ ВІД ІНТЕРМОДУЛЯЦІЇ IMD3',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Команда Дизармерів Ф-22',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
