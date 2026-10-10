import 'package:flutter/material.dart';
import '../../core/models/assigned_board.dart';
import '../../core/models/board_type.dart';
import 'result_clipboard_helper.dart';

class ResultCheatSheet extends StatelessWidget {
  final List<AssignedBoard> boards;
  final int? selectedBoardNumber;
  final ValueChanged<int?>? onSelectBoard;
  final VoidCallback onReset;

  const ResultCheatSheet({
    super.key,
    required this.boards,
    this.selectedBoardNumber,
    this.onSelectBoard,
    required this.onReset,
  });

  Color _getBadgeColor(BuildContext context, BoardType type) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case BoardType.standard:
        return scheme.primary;
      case BoardType.lowband:
        return scheme.secondary;
      case BoardType.xBand:
        return scheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'СІТКА ЧАСТОТ (${boards.length} ${ResultClipboardHelper.pluralBoards(boards.length)})',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Копіювати'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(110, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onPressed: () =>
                  ResultClipboardHelper.copyToClipboard(context, boards),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // List of boards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: boards.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final board = boards[index];
            final isSelected = board.boardNumber == selectedBoardNumber;
            final badgeColor = _getBadgeColor(context, board.boardType);

            return InkWell(
              onTap: () =>
                  onSelectBoard?.call(isSelected ? null : board.boardNumber),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? badgeColor.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? badgeColor
                        : badgeColor.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Board number & type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'Борт ${board.boardNumber}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Text(
                      board.boardType.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const Spacer(),

                    // Channel code & Frequency
                    Text(
                      board.channel.code,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Text(
                        '${board.channel.frequency} МГц',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Info notice: RHCP & IMD3 protected
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.verified, size: 18, color: colorScheme.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ВЕРИФІКОВАНО: Δf ≥ 40 MHz • IMD3 ≥ 10 MHz • RHCP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 11,
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
