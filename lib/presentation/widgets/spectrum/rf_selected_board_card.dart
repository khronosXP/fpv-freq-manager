import 'package:flutter/material.dart';
import '../../../core/models/assigned_board.dart';
import '../../../core/models/board_type.dart';

class RfSelectedBoardCard extends StatelessWidget {
  final AssignedBoard board;
  final List<AssignedBoard> allBoards;

  const RfSelectedBoardCard({
    super.key,
    required this.board,
    required this.allBoards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final sorted = List<AssignedBoard>.from(allBoards)
      ..sort((a, b) => a.channel.frequency.compareTo(b.channel.frequency));
    final idx = sorted.indexWhere((b) => b.boardNumber == board.boardNumber);

    final prevDiff = idx > 0
        ? board.channel.frequency - sorted[idx - 1].channel.frequency
        : null;
    final nextDiff = idx < sorted.length - 1
        ? sorted[idx + 1].channel.frequency - board.channel.frequency
        : null;

    final badgeColor = board.boardType == BoardType.standard
        ? colorScheme.primary
        : (board.boardType == BoardType.lowband
              ? colorScheme.secondary
              : colorScheme.tertiary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Борт ${board.boardNumber}',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${board.channel.code} (${board.channel.frequency} МГц)',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prevDiff != null)
                Text(
                  '← $prevDiff МГц ',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              if (nextDiff != null)
                Text(
                  ' $nextDiff МГц →',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
