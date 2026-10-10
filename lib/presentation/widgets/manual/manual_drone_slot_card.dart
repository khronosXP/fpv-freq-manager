import 'package:flutter/material.dart';
import '../../../core/models/board_type.dart';
import '../../../core/models/fpv_channel.dart';
import '../../../core/models/manual_drone_slot.dart';
import 'channel_picker_sheet.dart';
import 'manual_slot_header.dart';
import 'manual_slot_suggestions.dart';

class ManualDroneSlotCard extends StatelessWidget {
  final ManualDroneSlot slot;
  final List<ManualDroneSlot> allSlots;
  final bool hasConflict;
  final List<String> conflictReasons;
  final List<FpvChannel> suggestions;
  final bool canRemove;
  final ValueChanged<FpvChannel> onChannelChanged;
  final ValueChanged<BoardType> onTypeChanged;
  final VoidCallback onToggleLock;
  final VoidCallback onRemove;

  const ManualDroneSlotCard({
    super.key,
    required this.slot,
    required this.allSlots,
    required this.hasConflict,
    required this.conflictReasons,
    required this.suggestions,
    required this.canRemove,
    required this.onChannelChanged,
    required this.onTypeChanged,
    required this.onToggleLock,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    final borderColor = hasConflict
        ? colorScheme.error
        : (slot.isLocked ? colorScheme.secondary : colorScheme.outlineVariant);

    final cardBg = hasConflict
        ? colorScheme.errorContainer.withValues(alpha: isLight ? 0.35 : 0.15)
        : (slot.isLocked
              ? colorScheme.secondaryContainer.withValues(
                  alpha: isLight ? 0.35 : 0.15,
                )
              : (isLight
                    ? colorScheme.surface
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      )));

    return Card(
      elevation: isLight ? 1 : 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: hasConflict || slot.isLocked ? 1.5 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ManualSlotHeader(
              slot: slot,
              canRemove: canRemove,
              onTypeChanged: onTypeChanged,
              onToggleLock: onToggleLock,
              onRemove: onRemove,
            ),
            const SizedBox(height: 10),
            _buildChannelSelector(context, colorScheme, theme),
            if (hasConflict) ...[
              const SizedBox(height: 10),
              _buildConflictAlert(colorScheme, theme),
            ],
            if (suggestions.isNotEmpty && !slot.isLocked) ...[
              const SizedBox(height: 8),
              ManualSlotSuggestions(
                suggestions: suggestions,
                onSelectSuggestion: onChannelChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSelector(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final ch = slot.channel;
    return InkWell(
      onTap: () {
        ChannelPickerSheet.show(
          context: context,
          targetSlot: slot,
          otherSlots: allSlots,
          onSelectChannel: onChannelChanged,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasConflict
                ? colorScheme.error.withValues(alpha: 0.5)
                : colorScheme.outlineVariant,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ch?.code ?? '--',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              ch != null ? '${ch.frequency} MHz' : 'Не призначено',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              'Змінити',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictAlert(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: conflictReasons.map((reason) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, size: 15, color: colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.error,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
