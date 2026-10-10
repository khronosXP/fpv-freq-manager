import 'package:flutter/material.dart';
import '../../../core/models/assigned_board.dart';
import '../../../core/models/board_type.dart';

class RfSpectrumLegend extends StatelessWidget {
  final List<AssignedBoard> boards;

  const RfSpectrumLegend({super.key, required this.boards});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendItem(
          colorScheme.primary,
          'Стандарт 5.8G',
          colorScheme,
          textTheme,
        ),
        if (boards.any((b) => b.boardType == BoardType.lowband))
          _legendItem(
            colorScheme.secondary,
            'Lowband 5.3G',
            colorScheme,
            textTheme,
          ),
        if (boards.any((b) => b.boardType == BoardType.xBand))
          _legendItem(
            colorScheme.tertiary,
            'X-band 4.9G',
            colorScheme,
            textTheme,
          ),
        _legendItem(
          colorScheme.tertiary,
          '↔ Рознос ≥40МГц',
          colorScheme,
          textTheme,
        ),
        _legendItem(
          colorScheme.error.withValues(alpha: 0.7),
          '┆ Гармоніки IMD3',
          colorScheme,
          textTheme,
          isDashed: true,
        ),
      ],
    );
  }

  Widget _legendItem(
    Color color,
    String label,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isDashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isDashed ? color.withValues(alpha: 0) : color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
