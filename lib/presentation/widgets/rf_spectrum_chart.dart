import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/assigned_board.dart';
import '../../core/models/board_type.dart';
import 'spectrum/spectrum_painter.dart';

class RfSpectrumChart extends StatefulWidget {
  final List<AssignedBoard> boards;
  final int? selectedBoardNumber;
  final ValueChanged<int?> onSelectBoard;

  const RfSpectrumChart({
    super.key,
    required this.boards,
    required this.selectedBoardNumber,
    required this.onSelectBoard,
  });

  @override
  State<RfSpectrumChart> createState() => _RfSpectrumChartState();
}

class _RfSpectrumChartState extends State<RfSpectrumChart> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.boards.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final freqs = widget.boards.map((b) => b.channel.frequency).toList();
    final minFreq = freqs.reduce(math.min);
    final int chartMin = minFreq < 5250 ? 4900 : (minFreq < 5600 ? 5300 : 5600);
    const int chartMax = 6000;

    final selectedBoard = widget.selectedBoardNumber != null
        ? widget.boards.cast<AssignedBoard?>().firstWhere(
            (b) => b?.boardNumber == widget.selectedBoardNumber,
            orElse: () => null,
          )
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme, colorScheme),
            const SizedBox(height: 12),
            _buildCanvas(context, colorScheme, theme, chartMin, chartMax),
            const SizedBox(height: 10),
            if (selectedBoard != null)
              _buildSelectedCard(selectedBoard, colorScheme, theme.textTheme),
            const SizedBox(height: 8),
            _buildLegend(colorScheme, theme.textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'РАДІОСПЕКТР & IMD3',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Скрол ↔',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Δf ≥ 40 MHz • IMD3 ≥ 10 MHz',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCanvas(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    int chartMin,
    int chartMax,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minContentWidth = (chartMax - chartMin) > 600 ? 950.0 : 750.0;
        final width = math.max(constraints.maxWidth, minContentWidth);
        const height = 180.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: colorScheme.surface,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: GestureDetector(
                    onTapUp: (details) {
                      final tapX = details.localPosition.dx;
                      AssignedBoard? closest;
                      double minDistance = double.infinity;

                      for (final b in widget.boards) {
                        final bx =
                            ((b.channel.frequency - chartMin) /
                                (chartMax - chartMin)) *
                            width;
                        final dist = (bx - tapX).abs();
                        if (dist < 36 && dist < minDistance) {
                          minDistance = dist;
                          closest = b;
                        }
                      }

                      if (closest != null) {
                        widget.onSelectBoard(
                          closest.boardNumber == widget.selectedBoardNumber
                              ? null
                              : closest.boardNumber,
                        );
                      } else {
                        widget.onSelectBoard(null);
                      }
                    },
                    child: CustomPaint(
                      size: Size(width, height),
                      painter: SpectrumPainter(
                        boards: widget.boards,
                        selectedBoardNumber: widget.selectedBoardNumber,
                        chartMin: chartMin,
                        chartMax: chartMax,
                        colorScheme: colorScheme,
                        textTheme: theme.textTheme,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedCard(
    AssignedBoard board,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final sorted = List<AssignedBoard>.from(widget.boards)
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

  Widget _buildLegend(ColorScheme colorScheme, TextTheme textTheme) {
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
        if (widget.boards.any((b) => b.boardType == BoardType.lowband))
          _legendItem(
            colorScheme.secondary,
            'Lowband 5.3G',
            colorScheme,
            textTheme,
          ),
        if (widget.boards.any((b) => b.boardType == BoardType.xBand))
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
            color: isDashed ? Colors.transparent : color,
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
