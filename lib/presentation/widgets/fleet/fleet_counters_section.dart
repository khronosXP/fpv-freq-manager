import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../board_counter_card.dart';
import '../../providers/fleet_provider.dart';

class FleetCountersSection extends ConsumerWidget {
  const FleetCountersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(fleetProvider);
    final notifier = ref.read(fleetProvider.notifier);

    final isLight = theme.brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Стандартні борти 5.8 GHz
        BoardCounterCard(
          title: 'Стандартні борти (A, B, E, F, R)',
          subtitle: '5.8 GHz • 5645–5945 MHz',
          count: state.standardCount,
          canIncrement: state.canIncrementStandard,
          canDecrement: state.canDecrementStandard,
          monospaceSubtitle: true,
          limitMessage: state.isStandardAtLimit
              ? 'Ліміт 5.8 GHz: макс. 5 без завад'
              : null,
          onIncrement: notifier.incrementStandard,
          onDecrement: notifier.decrementStandard,
          accentColor: colorScheme.primary,
        ),

        // 2. Блок перемикання розширених діапазонів
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isLight
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: state.useExtendedBands
                  ? colorScheme.secondary.withValues(alpha: 0.6)
                  : colorScheme.outlineVariant,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Розширені діапазони',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Lowband 5.3 GHz • X-band 4.9 GHz',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.useExtendedBands,
                onChanged: (_) => notifier.toggleExtendedBands(),
                activeThumbColor: colorScheme.primary,
              ),
            ],
          ),
        ),

        // 3. Розкривні лічильники Lowband та X-band
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: state.useExtendedBands
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              BoardCounterCard(
                title: 'Борти Lowband',
                subtitle: 'L1–L8 • 5333–5613 MHz',
                count: state.lowbandCount,
                canIncrement: state.canIncrementLowband,
                canDecrement: state.canDecrementLowband,
                monospaceSubtitle: true,
                limitMessage: state.lowbandCount >= FleetState.maxLowbandBoards
                    ? 'Фізичний ліміт: макс. 4 без завад'
                    : null,
                onIncrement: notifier.incrementLowband,
                onDecrement: notifier.decrementLowband,
                accentColor: colorScheme.secondary,
              ),
              BoardCounterCard(
                title: 'Борти X-band',
                subtitle: 'X1–X8 • 4990–5200 MHz',
                count: state.xBandCount,
                canIncrement: state.canIncrementXBand,
                canDecrement: state.canDecrementXBand,
                monospaceSubtitle: true,
                limitMessage: state.xBandCount >= FleetState.maxXBandBoards
                    ? 'Фізичний ліміт: макс. 3 без завад'
                    : null,
                onIncrement: notifier.incrementXBand,
                onDecrement: notifier.decrementXBand,
                accentColor: colorScheme.tertiary,
              ),
            ],
          ),
        ),

        // 4. Єдиний глобальний ліміт флоту (12 бортів)
        if (state.isTotalAtLimit)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Досягнуто загальний ліміт: 12 бортів у повітрі',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
