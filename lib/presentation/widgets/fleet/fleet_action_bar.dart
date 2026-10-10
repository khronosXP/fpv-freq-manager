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

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isCalculating ? null : notifier.calculateOptimalFleet,
            icon: isCalculating
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(Icons.tune, size: 20, color: colorScheme.onPrimary),
            label: Text(
              isCalculating
                  ? 'Розрахунок сітки...'
                  : 'Розрахувати сітку ($total ${total == 1 ? 'борт' : (total < 5 ? 'борти' : 'бортів')})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colorScheme.onPrimary,
                letterSpacing: 0.4,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 2,
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
    );
  }
}
