import 'dart:math';
import 'package:flutter/material.dart';

class WheelPainter extends CustomPainter {
  final List<String> letters;

  WheelPainter({required this.letters});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    final sweep = (2 * pi) / letters.length;

    for (int i = 0; i < letters.length; i++) {
      final startAngle = i * sweep;

      paint.color = colors[i % colors.length];

      final path = Path();

      path.moveTo(center.dx, center.dy);

      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
      );

      path.close();

      canvas.drawShadow(path, Colors.black, 4, false);

      canvas.drawPath(path, paint);

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white
          ..strokeWidth = 2,
      );
      // Harfin açısını hesapla
      final textAngle = (i * sweep) + (sweep / 2);

      // Harfin konumu
      final textRadius = radius - 55;

      final dx = center.dx + cos(textAngle) * textRadius;
      final dy = center.dy + sin(textAngle) * textRadius;

      // Yazı hazırlığı
      final textPainter = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Canvas'ı kaydet
      canvas.save();

      // Harfi döndür
      canvas.translate(dx, dy);
      canvas.rotate(textAngle + pi / 2);

      // Harfi çiz
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      // Canvas'ı eski haline getir
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
