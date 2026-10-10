import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/assigned_board.dart';

class SpectrumPainterHelpers {
  SpectrumPainterHelpers._();

  static void drawBandRegion({
    required Canvas canvas,
    required double width,
    required int startFreq,
    required int endFreq,
    required String label,
    required Color bandColor,
    required int chartMin,
    required int chartMax,
    required TextTheme textTheme,
    required double Function(num, double) freqToX,
  }) {
    if (endFreq < chartMin || startFreq > chartMax) return;
    final clampedStart = math.max(startFreq, chartMin);
    final clampedEnd = math.min(endFreq, chartMax);

    final x1 = freqToX(clampedStart, width);
    final x2 = freqToX(clampedEnd, width);

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

  static void drawImd3Harmonics({
    required Canvas canvas,
    required double width,
    required double baselineY,
    required List<AssignedBoard> boards,
    required int chartMin,
    required int chartMax,
    required ColorScheme colorScheme,
    required double Function(num, double) freqToX,
  }) {
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
      final x = freqToX(f, width);
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

  static void drawSpacingIndicators({
    required Canvas canvas,
    required double width,
    required double baselineY,
    required List<AssignedBoard> boards,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required double Function(num, double) freqToX,
  }) {
    final sorted = List<AssignedBoard>.from(boards)
      ..sort((a, b) => a.channel.frequency.compareTo(b.channel.frequency));

    for (int i = 0; i < sorted.length - 1; i++) {
      final f1 = sorted[i].channel.frequency;
      final f2 = sorted[i + 1].channel.frequency;
      final diff = f2 - f1;

      final x1 = freqToX(f1, width);
      final x2 = freqToX(f2, width);

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
}
