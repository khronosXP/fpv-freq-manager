import 'package:flutter/material.dart';
import '../providers/frequency_manager_provider.dart';
import 'board_counter_card.dart';

class ExtendedBandsSection extends StatelessWidget {
  final FrequencyManagerState state;
  final FrequencyManagerNotifier notifier;

  const ExtendedBandsSection({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: state.useExtendedBands
                  ? colorScheme.secondary.withValues(alpha: 0.4)
                  : colorScheme.outlineVariant.withValues(alpha: 0.25),
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
                onChanged: notifier.toggleExtendedBands,
                activeThumbColor: colorScheme.primary,
              ),
            ],
          ),
        ),
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
                limitMessage: state.lowbandCount >= 8
                    ? 'Максимум 8 каналів L1–L8'
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
                limitMessage: state.xBandCount >= 8
                    ? 'Максимум 8 каналів X1–X8'
                    : null,
                onIncrement: notifier.incrementXBand,
                onDecrement: notifier.decrementXBand,
                accentColor: colorScheme.tertiary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
