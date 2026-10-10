import 'package:flutter/material.dart';
import '../../../core/models/assigned_board.dart';
import '../../../core/models/board_type.dart';
import 'spectrum_painter_helpers.dart';

class SpectrumPainter extends CustomPainter {
  final List<AssignedBoard> boards;
  final int? selectedBoardNumber;
  final int chartMin;
  final int chartMax;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  SpectrumPainter({
    required this.boards,
    required this.selectedBoardNumber,
    required this.chartMin,
    required this.chartMax,
    required this.colorScheme,
    required this.textTheme,
  });

  double _freqToX(num freq, double width) {
    return ((freq - chartMin) / (chartMax - chartMin)) * width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    const baselineY = 145.0;

    // 1. Grid & Baseline
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    final baselinePaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      const Offset(0, baselineY),
      Offset(width, baselineY),
      baselinePaint,
    );

    final step = (chartMax - chartMin) > 600 ? 200 : 100;
    final firstTick = ((chartMin / step).ceil()) * step;

    for (int f = firstTick; f <= chartMax; f += step) {
      final x = _freqToX(f, width);
      canvas.drawLine(Offset(x, 18), Offset(x, baselineY), gridPaint);

      final textSpan = TextSpan(
        text: '$f',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 9,
          fontFamily: 'monospace',
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, baselineY + 4));
    }

    // 2. Band Regions
    SpectrumPainterHelpers.drawBandRegion(
      canvas: canvas,
      width: width,
      startFreq: 4990,
      endFreq: 5200,
      label: 'X-BAND (4.9G)',
      bandColor: colorScheme.tertiary,
      chartMin: chartMin,
      chartMax: chartMax,
      textTheme: textTheme,
      freqToX: _freqToX,
    );
    SpectrumPainterHelpers.drawBandRegion(
      canvas: canvas,
      width: width,
      startFreq: 5333,
      endFreq: 5613,
      label: 'LOWBAND (5.3G)',
      bandColor: colorScheme.secondary,
      chartMin: chartMin,
      chartMax: chartMax,
      textTheme: textTheme,
      freqToX: _freqToX,
    );
    SpectrumPainterHelpers.drawBandRegion(
      canvas: canvas,
      width: width,
      startFreq: 5645,
      endFreq: 5945,
      label: 'STANDARD (5.8G)',
      bandColor: colorScheme.primary,
      chartMin: chartMin,
      chartMax: chartMax,
      textTheme: textTheme,
      freqToX: _freqToX,
    );

    // 3. IMD3 Harmonics
    SpectrumPainterHelpers.drawImd3Harmonics(
      canvas: canvas,
      width: width,
      baselineY: baselineY,
      boards: boards,
      chartMin: chartMin,
      chartMax: chartMax,
      colorScheme: colorScheme,
      freqToX: _freqToX,
    );

    // 4. Spacing Indicators
    SpectrumPainterHelpers.drawSpacingIndicators(
      canvas: canvas,
      width: width,
      baselineY: baselineY,
      boards: boards,
      colorScheme: colorScheme,
      textTheme: textTheme,
      freqToX: _freqToX,
    );

    // 5. Active Channel Peaks
    for (final board in boards) {
      _drawChannelPeak(canvas, width, baselineY, board);
    }
  }

  void _drawChannelPeak(
    Canvas canvas,
    double width,
    double baselineY,
    AssignedBoard board,
  ) {
    final freq = board.channel.frequency;
    final centerX = _freqToX(freq, width);
    const peakHeight = 85.0;
    const peakTopY = 48.0;

    final isSelected = board.boardNumber == selectedBoardNumber;

    Color badgeColor;
    switch (board.boardType) {
      case BoardType.standard:
        badgeColor = colorScheme.primary;
        break;
      case BoardType.lowband:
        badgeColor = colorScheme.secondary;
        break;
      case BoardType.xBand:
        badgeColor = colorScheme.tertiary;
        break;
    }

    final path = Path();
    const halfWidthFreq = 16.0;
    final xLeft = _freqToX(freq - halfWidthFreq, width);
    final xRight = _freqToX(freq + halfWidthFreq, width);

    path.moveTo(xLeft, baselineY);

    final cp1X = centerX - (centerX - xLeft) * 0.45;
    final cp2X = centerX + (xRight - centerX) * 0.45;

    path.cubicTo(
      cp1X,
      baselineY - peakHeight * 0.15,
      centerX - (centerX - xLeft) * 0.15,
      peakTopY,
      centerX,
      peakTopY,
    );

    path.cubicTo(
      centerX + (xRight - centerX) * 0.15,
      peakTopY,
      cp2X,
      baselineY - peakHeight * 0.15,
      xRight,
      baselineY,
    );

    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          badgeColor.withValues(alpha: isSelected ? 0.55 : 0.32),
          badgeColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTRB(xLeft, peakTopY, xRight, baselineY))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = isSelected
          ? colorScheme.onSurface
          : badgeColor.withValues(alpha: 0.9)
      ..strokeWidth = isSelected ? 2.2 : 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, strokePaint);

    final centerLinePaint = Paint()
      ..color = badgeColor.withValues(alpha: isSelected ? 0.9 : 0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(centerX, peakTopY),
      Offset(centerX, baselineY),
      centerLinePaint,
    );

    canvas.drawCircle(
      Offset(centerX, peakTopY),
      isSelected ? 4.5 : 3.0,
      Paint()..color = isSelected ? colorScheme.onSurface : badgeColor,
    );

    final labelSpan = TextSpan(
      children: [
        TextSpan(
          text: 'Б${board.boardNumber} ',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 9,
            color: isSelected ? colorScheme.onSurface : badgeColor,
          ),
        ),
        TextSpan(
          text: board.channel.code,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 9,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );

    final labelTp = TextPainter(
      text: labelSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final labelX = (centerX - labelTp.width / 2).clamp(
      2.0,
      width - labelTp.width - 2.0,
    );
    labelTp.paint(canvas, Offset(labelX, peakTopY - 14));
  }

  @override
  bool shouldRepaint(covariant SpectrumPainter oldDelegate) {
    return oldDelegate.boards != boards ||
        oldDelegate.selectedBoardNumber != selectedBoardNumber ||
        oldDelegate.chartMin != chartMin ||
        oldDelegate.chartMax != chartMax ||
        oldDelegate.colorScheme != colorScheme;
  }
}
