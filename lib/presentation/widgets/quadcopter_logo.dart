import 'dart:math' as math;
import 'package:flutter/material.dart';

class QuadcopterLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const QuadcopterLogo({super.key, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _QuadcopterPainter(color: effectiveColor)),
    );
  }
}

class _QuadcopterPainter extends CustomPainter {
  final Color color;

  const _QuadcopterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final s = size.width / 100.0;

    final armPaint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.8, 3.2 * s)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final motorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final propPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = math.max(1.2, 2.0 * s)
      ..style = PaintingStyle.stroke;

    final armLen = 28.0 * s;
    final motorRadius = 4.2 * s;
    final propRadius = 10.0 * s;

    // 4 diagonal arms (45, 135, 225, 315 deg)
    const angles = [
      math.pi / 4,
      3 * math.pi / 4,
      5 * math.pi / 4,
      7 * math.pi / 4,
    ];

    for (final a in angles) {
      final mx = cx + armLen * math.cos(a);
      final my = cy + armLen * math.sin(a);

      // Arm line
      canvas.drawLine(Offset(cx, cy), Offset(mx, my), armPaint);

      // Motor bell
      canvas.drawCircle(Offset(mx, my), motorRadius, motorPaint);

      // Propeller sweep circles/arcs
      canvas.drawCircle(Offset(mx, my), propRadius, propPaint);
    }

    // Fuselage / center body
    final bodyRadius = 11.0 * s;
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: bodyRadius * 2,
        height: bodyRadius * 2,
      ),
      Radius.circular(3.5 * s),
    );
    canvas.drawRRect(bodyRRect, motorPaint);

    // Center camera aperture (hollow circle)
    final camPaint = Paint()
      ..color = const Color(0x00000000)
      ..blendMode = BlendMode.clear;
    canvas.drawCircle(Offset(cx, cy), 4.5 * s, camPaint);

    // Front orientation indicator (small arrow at the top)
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(cx, cy - bodyRadius - 5.0 * s)
      ..lineTo(cx - 3.2 * s, cy - bodyRadius)
      ..lineTo(cx + 3.2 * s, cy - bodyRadius)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _QuadcopterPainter oldDelegate) =>
      oldDelegate.color != color;
}
