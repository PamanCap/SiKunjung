import 'dart:math';

import 'package:flutter/material.dart';

/// Gambar kompas
class CompassWidget extends StatelessWidget {
  final double? heading;
  final double size;

  const CompassWidget({super.key, required this.heading, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompassPainter(
          heading: heading ?? 0,
          aktif: heading != null,
          ring: scheme.outline,
          teks: scheme.onSurface,
          latar: scheme.surfaceContainerHighest,
          utara: scheme.error,
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;
  final bool aktif;
  final Color ring;
  final Color teks;
  final Color latar;
  final Color utara;

  _CompassPainter({
    required this.heading,
    required this.aktif,
    required this.ring,
    required this.teks,
    required this.latar,
    required this.utara,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    canvas.drawCircle(c, r, Paint()..color = latar);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Dial berputar berlawanan arah heading.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-heading * pi / 180);

    const labels = ['U', 'T', 'S', 'B'];
    for (var i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: i == 0 ? utara : teks,
            fontSize: size.width * 0.11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.rotate(angle);
      canvas.translate(0, -r + size.width * 0.14);
      canvas.rotate(-angle + heading * pi / 180);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    // Garis skala tiap 30 derajat.
    final tick = Paint()
      ..color = ring
      ..strokeWidth = 1.5;
    for (var d = 0; d < 360; d += 30) {
      final a = d * pi / 180;
      canvas.drawLine(
        Offset(sin(a) * (r - 4), -cos(a) * (r - 4)),
        Offset(sin(a) * (r - 12), -cos(a) * (r - 12)),
        tick,
      );
    }
    canvas.restore();

    // Jarum penunjuk arah
    final jarum = Path()
      ..moveTo(c.dx, c.dy - r * 0.55)
      ..lineTo(c.dx - 9, c.dy + 6)
      ..lineTo(c.dx + 9, c.dy + 6)
      ..close();
    canvas.drawPath(jarum, Paint()..color = aktif ? utara : ring);
    canvas.drawCircle(c, 5, Paint()..color = teks);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.heading != heading || old.aktif != aktif || old.latar != latar;
}
