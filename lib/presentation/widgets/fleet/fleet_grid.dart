import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/math/conflict_analyzer.dart';
import '../../../core/models/fleet_drone_slot.dart';
import '../../providers/fleet_provider.dart';
import '../manual/manual_drone_slot_card.dart';
import '../result_clipboard_helper.dart';

class FleetGrid extends ConsumerWidget {
  final VoidCallback? onShowSpectrum;

  const FleetGrid({super.key, this.onShowSpectrum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(fleetProvider);
    final notifier = ref.read(fleetProvider.notifier);
    final count = state.slots.length;
    final hasAssigned = state.assignedBoards.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Заголовок єдиного переліку бортів з діями спектра та швидкого копіювання
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.table_chart, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'СІТКА ЧАСТОТ ($count ${ResultClipboardHelper.pluralBoards(count)})',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (hasAssigned)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onShowSpectrum != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.graphic_eq, size: 18),
                      label: const Text('Радіоспектр'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(110, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onPressed: onShowSpectrum,
                    ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Копіювати'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(100, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => ResultClipboardHelper.copyToClipboard(
                      context,
                      state.assignedBoards,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),

        ...state.slots.map((slot) {
          final hasConflict = state.conflictReport.conflictedSlotIds.contains(
            slot.id,
          );
          final reasons = _getConflictReasons(slot, state.conflictReport);
          final suggestions =
              state.conflictReport.suggestionsBySlotId[slot.id] ?? const [];

          return ManualDroneSlotCard(
            key: ValueKey(slot.id),
            slot: slot,
            allSlots: state.slots,
            hasConflict: hasConflict,
            conflictReasons: reasons,
            suggestions: suggestions,
            canRemove: state.slots.length > 1,
            onChannelChanged: (ch) => notifier.assignChannel(slot.id, ch),
            onTypeChanged: (type) => notifier.changeSlotType(slot.id, type),
            onToggleLock: () => notifier.toggleLock(slot.id),
            onRemove: () => notifier.removeSlot(slot.id),
          );
        }),
      ],
    );
  }

  static List<String> _getConflictReasons(
    FleetDroneSlot slot,
    ConflictReport report,
  ) {
    final reasons = <String>[];

    for (final dir in report.directCollisions) {
      if (dir.slotA.id == slot.id) {
        reasons.add(
          'Прямий конфлікт із Бортом ${dir.slotB.boardNumber} (${dir.slotB.channel?.code}): зазор ${dir.delta} МГц < 40 МГц',
        );
      } else if (dir.slotB.id == slot.id) {
        reasons.add(
          'Прямий конфлікт із Бортом ${dir.slotA.boardNumber} (${dir.slotA.channel?.code}): зазор ${dir.delta} МГц < 40 МГц',
        );
      }
    }

    for (final imd in report.imdCollisions) {
      if (imd.victim.id == slot.id) {
        reasons.add(
          'Глушиться комбінацією 2×Б${imd.transmitter1.boardNumber} - Б${imd.transmitter2.boardNumber} (зазор ${imd.distance} МГц < ${imd.threshold} МГц)',
        );
      } else if (imd.transmitter1.id == slot.id ||
          imd.transmitter2.id == slot.id) {
        reasons.add(
          'Створює IMD3 заваду на Борт ${imd.victim.boardNumber} (зазор ${imd.distance} МГц < ${imd.threshold} МГц)',
        );
      }
    }

    for (final tb in report.tripleBeatCollisions) {
      if (tb.victim.id == slot.id) {
        reasons.add(
          'Triple-Beat резонанс від Б${tb.transmitter1.boardNumber}+Б${tb.transmitter2.boardNumber}-Б${tb.transmitter3.boardNumber} (зазор ${tb.distance} МГц < ${tb.threshold} МГц)',
        );
      } else if (tb.transmitter1.id == slot.id ||
          tb.transmitter2.id == slot.id ||
          tb.transmitter3.id == slot.id) {
        reasons.add(
          'Створює Triple-Beat заваду на Борт ${tb.victim.boardNumber} (зазор ${tb.distance} МГц < ${tb.threshold} МГц)',
        );
      }
    }

    return reasons;
  }
}
