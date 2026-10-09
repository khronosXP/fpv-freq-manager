import 'package:flutter/material.dart';
import '../../../core/models/board_type.dart';
import '../../../core/models/fpv_channel.dart';
import '../../../core/models/manual_drone_slot.dart';
import 'channel_picker_sheet.dart';

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

    final borderColor = hasConflict
        ? colorScheme.error
        : (slot.isLocked
              ? colorScheme.secondary
              : colorScheme.outlineVariant.withValues(alpha: 0.35));

    final cardBg = hasConflict
        ? colorScheme.errorContainer.withValues(alpha: 0.15)
        : (slot.isLocked
              ? colorScheme.secondaryContainer.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45));

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: borderColor,
          width: hasConflict || slot.isLocked ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderRow(context, colorScheme, theme),
            const SizedBox(height: 10),
            _buildChannelSelector(context, colorScheme, theme),
            if (hasConflict) ...[
              const SizedBox(height: 10),
              _buildConflictAlert(colorScheme, theme),
            ],
            if (suggestions.isNotEmpty && !slot.isLocked) ...[
              const SizedBox(height: 8),
              _buildSuggestionsRow(colorScheme, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Row(
      children: [
        // Board badge
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
            'Борт ${slot.boardNumber}',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Board Type Dropdown/Button
        _buildTypeBadge(context, colorScheme, theme),
        const Spacer(),
        // Lock button
        IconButton(
          tooltip: slot.isLocked ? 'Розблокувати канал' : 'Зафіксувати канал',
          icon: Icon(
            slot.isLocked ? Icons.lock : Icons.lock_open,
            color: slot.isLocked
                ? colorScheme.secondary
                : colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: onToggleLock,
          visualDensity: VisualDensity.compact,
        ),
        // Remove button
        IconButton(
          tooltip: 'Видалити борт',
          icon: Icon(
            Icons.close,
            color: canRemove
                ? colorScheme.outline
                : colorScheme.outline.withValues(alpha: 0.3),
            size: 20,
          ),
          onPressed: canRemove ? onRemove : null,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildTypeBadge(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return PopupMenuButton<BoardType>(
      tooltip: 'Змінити тип борту',
      initialValue: slot.boardType,
      onSelected: onTypeChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.boardType.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 14, color: colorScheme.primary),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: BoardType.standard,
          child: Text('Стандартний (5.8G)'),
        ),
        const PopupMenuItem(
          value: BoardType.lowband,
          child: Text('Lowband (5.3-5.6G)'),
        ),
        const PopupMenuItem(
          value: BoardType.xBand,
          child: Text('X-Band (4.9-5.2G)'),
        ),
      ],
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasConflict
                ? colorScheme.error.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
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
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              'Змінити',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
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
                Icon(Icons.warning_amber, size: 14, color: colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.error,
                      fontFamily: 'monospace',
                      fontSize: 11,
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

  Widget _buildSuggestionsRow(ColorScheme colorScheme, ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.lightbulb_outline, size: 14, color: colorScheme.secondary),
        const SizedBox(width: 6),
        Text(
          'Заміни:',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((candidate) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '${candidate.code} (${candidate.frequency})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    onPressed: () => onChannelChanged(candidate),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
