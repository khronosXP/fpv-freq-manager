import 'package:flutter/material.dart';
import '../../../core/models/board_type.dart';
import '../../../core/models/manual_drone_slot.dart';

class ManualSlotHeader extends StatelessWidget {
  final ManualDroneSlot slot;
  final bool canRemove;
  final ValueChanged<BoardType> onTypeChanged;
  final VoidCallback onToggleLock;
  final VoidCallback onRemove;

  const ManualSlotHeader({
    super.key,
    required this.slot,
    required this.canRemove,
    required this.onTypeChanged,
    required this.onToggleLock,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Board badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
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

        // Lock button (tactile touch target >= 44x44)
        IconButton(
          tooltip: slot.isLocked ? 'Розблокувати канал' : 'Зафіксувати канал',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: Icon(
            slot.isLocked ? Icons.lock : Icons.lock_open,
            color: slot.isLocked
                ? colorScheme.secondary
                : colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: onToggleLock,
        ),

        // Remove button (tactile touch target >= 44x44)
        IconButton(
          tooltip: 'Видалити борт',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: Icon(
            Icons.close,
            color: canRemove
                ? colorScheme.outline
                : colorScheme.outline.withValues(alpha: 0.3),
            size: 20,
          ),
          onPressed: canRemove ? onRemove : null,
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
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
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
            Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.primary),
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
}
