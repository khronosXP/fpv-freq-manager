import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/assigned_board.dart';
import '../../core/models/board_type.dart';
import '../../core/models/manual_drone_slot.dart';
import '../../core/math/conflict_analyzer.dart';
import '../providers/frequency_manager_provider.dart';
import '../providers/manual_config_provider.dart';
import '../widgets/manual/collision_detail_dialog.dart';
import '../widgets/manual/collision_summary_banner.dart';
import '../widgets/manual/manual_drone_slot_card.dart';
import '../widgets/rf_spectrum_chart.dart';

class ManualConfiguratorView extends ConsumerWidget {
  const ManualConfiguratorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(manualConfigProvider);
    final notifier = ref.read(manualConfigProvider.notifier);
    final autoState = ref.watch(frequencyManagerProvider);

    final assignedBoards = state.slots
        .where((s) => s.isAssigned)
        .map(
          (s) => AssignedBoard(
            boardNumber: s.boardNumber,
            boardType: s.boardType,
            channel: s.channel!,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(context, state, notifier, autoState, colorScheme, theme),
        if (state.lastStatusMessage != null)
          _buildStatusMessage(state.lastStatusMessage!, colorScheme, theme),
        CollisionSummaryBanner(
          report: state.conflictReport,
          isResolving: state.isResolving,
          onAutoResolve: notifier.autoResolveConflicts,
          onShowDetails: () =>
              CollisionDetailDialog.show(context, state.conflictReport),
        ),
        if (assignedBoards.isNotEmpty)
          RfSpectrumChart(
            boards: assignedBoards,
            selectedBoardNumber: state.selectedSlotId,
            onSelectBoard: notifier.selectSlot,
          ),
        const SizedBox(height: 8),
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
            canRemove: state.canRemoveSlot,
            onChannelChanged: (ch) => notifier.setSlotChannel(slot.id, ch),
            onTypeChanged: (type) => notifier.changeSlotType(slot.id, type),
            onToggleLock: () => notifier.toggleSlotLock(slot.id),
            onRemove: () => notifier.removeSlot(slot.id),
          );
        }),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    ManualConfigState state,
    ManualConfigNotifier notifier,
    FrequencyManagerState autoState,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final hasAutoResult =
        autoState.hasGenerated &&
        autoState.result != null &&
        autoState.result!.isSuccess &&
        autoState.result!.boards.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add drone popup button
            _buildAddDroneButton(state, notifier, colorScheme, theme),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: notifier.resetToCleanPair,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
              child: const Text('Скинути'),
            ),
            if (hasAutoResult) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    notifier.importFromAllocation(autoState.result!.boards),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                icon: const Icon(Icons.download, size: 14),
                label: Text(
                  'З розрахунку (${autoState.result!.boards.length})',
                ),
              ),
            ],
            const SizedBox(width: 12),
            // Slot count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${state.slots.length} / ${ManualConfigState.maxTotalBoards} бортів',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddDroneButton(
    ManualConfigState state,
    ManualConfigNotifier notifier,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return PopupMenuButton<BoardType>(
      enabled: state.canAddSlot,
      tooltip: 'Додати борт',
      onSelected: notifier.addSlot,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: state.canAddSlot
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: colorScheme.onPrimary),
            const SizedBox(width: 4),
            Text(
              'Додати борт',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: colorScheme.onPrimary),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: BoardType.standard,
          child: Text('+ Стандартний (5.8G)'),
        ),
        const PopupMenuItem(
          value: BoardType.lowband,
          child: Text('+ Lowband (5.3-5.6G)'),
        ),
        const PopupMenuItem(
          value: BoardType.xBand,
          child: Text('+ X-Band (4.9-5.2G)'),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(
    String msg,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getConflictReasons(
    ManualDroneSlot slot,
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

    return reasons;
  }
}
