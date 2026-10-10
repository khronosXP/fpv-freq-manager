import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/fleet_provider.dart';

class FleetActionBar extends ConsumerWidget {
  const FleetActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(fleetProvider);
    final notifier = ref.read(fleetProvider.notifier);

    final total = state.totalBoards;
    final isCalculating = state.isCalculating;
    final hasCollisions = state.hasConflicts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isCalculating
                    ? null
                    : notifier.calculateOptimalFleet,
                icon: isCalculating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.bolt, size: 20),
                label: Text(
                  isCalculating
                      ? 'Розрахунок сітки...'
                      : 'Розрахувати сітку ($total ${total == 1 ? 'борт' : (total < 5 ? 'борти' : 'бортів')})',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Скинути до стандартних 2 бортів',
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: isCalculating ? null : notifier.resetFleet,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Стан чистоти ефіру
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hasCollisions
                ? colorScheme.errorContainer.withValues(alpha: 0.2)
                : colorScheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasCollisions
                  ? colorScheme.error.withValues(alpha: 0.4)
                  : colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasCollisions
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user,
                size: 16,
                color: hasCollisions ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasCollisions
                      ? 'УВАГА: Виявлено колізії частот або IMD3'
                      : 'СІТКА БЕЗПЕЧНА • Δf ≥ 40 MHz • IMD3 ≥ 10 MHz',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: hasCollisions
                        ? colorScheme.error
                        : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (state.lastStatusMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              state.lastStatusMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
