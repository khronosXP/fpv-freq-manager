import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/assigned_board.dart';
import 'spectrum/rf_selected_board_card.dart';
import 'spectrum/rf_spectrum_legend.dart';
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
    final isLight = theme.brightness == Brightness.light;

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
      elevation: isLight ? 1 : 0,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: isLight ? 1.2 : 1.0,
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
              RfSelectedBoardCard(
                board: selectedBoard,
                allBoards: widget.boards,
              ),
            const SizedBox(height: 8),
            RfSpectrumLegend(boards: widget.boards),
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
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                'Δf ≥ 40 MHz • IMD3 ≥ 12 MHz',
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
}
