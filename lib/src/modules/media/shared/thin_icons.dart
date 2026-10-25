/// Single-stroke media icons — Material outlined glyphs double the stroke.
library;

import 'package:flutter/widgets.dart';

/// Download mark drawn as one continuous outline (arrow + tray).
class ConsonaThinDownloadIcon extends StatelessWidget {
  const ConsonaThinDownloadIcon({
    super.key,
    this.size = 20.0,
    this.color,
    this.strokeWidth = 1.4,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ThinDownloadPainter(
          color: resolved,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _ThinDownloadPainter extends CustomPainter {
  const _ThinDownloadPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Shaft
    final top = h * 0.18;
    final tip = h * 0.58;
    final midX = w * 0.5;
    canvas.drawLine(Offset(midX, top), Offset(midX, tip), paint);

    // Arrow head
    final head = w * 0.22;
    canvas.drawLine(Offset(midX, tip), Offset(midX - head, tip - head), paint);
    canvas.drawLine(Offset(midX, tip), Offset(midX + head, tip - head), paint);

    // Tray
    final trayTop = h * 0.68;
    final trayBottom = h * 0.86;
    final trayInset = w * 0.18;
    final path = Path()
      ..moveTo(trayInset, trayTop)
      ..lineTo(trayInset, trayBottom)
      ..lineTo(w - trayInset, trayBottom)
      ..lineTo(w - trayInset, trayTop);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ThinDownloadPainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}
