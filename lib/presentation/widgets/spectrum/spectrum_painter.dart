import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/assigned_board.dart';
import '../../../core/models/board_type.dart';

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
    _drawBandRegion(
      canvas,
      width,
      4990,
      5200,
      'X-BAND (4.9G)',
      colorScheme.tertiary,
    );
    _drawBandRegion(
      canvas,
      width,
      5333,
      5613,
      'LOWBAND (5.3G)',
      colorScheme.secondary,
    );
    _drawBandRegion(
      canvas,
      width,
      5645,
      5945,
      'STANDARD (5.8G)',
      colorScheme.primary,
    );

    // 3. IMD3 Harmonics
    _drawImd3Harmonics(canvas, width, baselineY);

    // 4. Spacing Indicators
    _drawSpacingIndicators(canvas, width, baselineY);

    // 5. Active Channel Peaks
    for (final board in boards) {
      _drawChannelPeak(canvas, width, baselineY, board);
    }
  }

  void _drawBandRegion(
    Canvas canvas,
    double width,
    int startFreq,
    int endFreq,
    String label,
    Color bandColor,
  ) {
    if (endFreq < chartMin || startFreq > chartMax) return;
    final clampedStart = math.max(startFreq, chartMin);
    final clampedEnd = math.min(endFreq, chartMax);

    final x1 = _freqToX(clampedStart, width);
    final x2 = _freqToX(clampedEnd, width);

    final rect = Rect.fromLTRB(x1, 2, x2, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = bandColor.withValues(alpha: 0.08),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = bandColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    if ((x2 - x1) > 40) {
      final span = TextSpan(
        text: label,
        style: textTheme.labelSmall?.copyWith(
          color: bandColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(x1 + (x2 - x1 - tp.width) / 2, 4));
    }
  }

  void _drawImd3Harmonics(Canvas canvas, double width, double baselineY) {
    final imdFreqs = <int>{};
    final freqs = boards.map((b) => b.channel.frequency).toList();

    for (int i = 0; i < freqs.length; i++) {
      for (int j = 0; j < freqs.length; j++) {
        if (i == j) continue;
        final fImd = 2 * freqs[i] - freqs[j];
        if (fImd >= chartMin && fImd <= chartMax) {
          imdFreqs.add(fImd);
        }
      }
    }

    final imdPaint = Paint()
      ..color = colorScheme.error.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;

    for (final f in imdFreqs) {
      final x = _freqToX(f, width);
      const topY = 75.0;

      double curY = baselineY;
      while (curY > topY) {
        final nextY = math.max(curY - 4.0, topY);
        canvas.drawLine(Offset(x, curY), Offset(x, nextY), imdPaint);
        curY -= 7.0;
      }

      canvas.drawCircle(
        Offset(x, topY),
        1.5,
        Paint()..color = colorScheme.error.withValues(alpha: 0.6),
      );
    }
  }

  void _drawSpacingIndicators(Canvas canvas, double width, double baselineY) {
    final sorted = List<AssignedBoard>.from(boards)
      ..sort((a, b) => a.channel.frequency.compareTo(b.channel.frequency));

    for (int i = 0; i < sorted.length - 1; i++) {
      final f1 = sorted[i].channel.frequency;
      final f2 = sorted[i + 1].channel.frequency;
      final diff = f2 - f1;

      final x1 = _freqToX(f1, width);
      final x2 = _freqToX(f2, width);

      if ((x2 - x1) < 22) continue;

      const lineY = 136.0;
      final arrowPaint = Paint()
        ..color = colorScheme.tertiary.withValues(alpha: 0.6)
        ..strokeWidth = 1.0;

      canvas.drawLine(Offset(x1 + 6, lineY), Offset(x2 - 6, lineY), arrowPaint);

      final span = TextSpan(
        text: '+$diff',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.tertiary,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset((x1 + x2 - tp.width) / 2, lineY - 10));
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
