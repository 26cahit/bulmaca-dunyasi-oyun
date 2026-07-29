import 'dart:math' as math;

import 'package:flutter/material.dart';

class GameCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (widget.title == 'Kelime Dünyası') {
          return _buildAnimatedBook();
        }

        if (widget.title == 'Zeka Dünyası') {
          return _buildAnimatedBrain();
        }

        if (widget.title == 'Bilgi Dünyası') {
          return Transform.rotate(
            angle: _animationController.value * math.pi * 2,
            child: Icon(widget.icon, color: Colors.amber, size: 38),
          );
        }

        if (widget.title == 'Çok Oyunculu') {
          final double scale =
              1.0 + math.sin(_animationController.value * math.pi * 2) * 0.08;

          return Transform.scale(
            scale: scale,
            child: Icon(widget.icon, color: Colors.amber, size: 38),
          );
        }

        return Icon(widget.icon, color: Colors.amber, size: 38);
      },
    );
  }

  Widget _buildAnimatedBook() {
    final double progress =
        (math.sin(_animationController.value * math.pi * 2) + 1) / 2;

    return SizedBox(
      width: 58,
      height: 52,
      child: CustomPaint(painter: _AnimatedBookPainter(progress: progress)),
    );
  }

  Widget _buildAnimatedBrain() {
    final double headAngle =
        math.sin(_animationController.value * math.pi * 2) * 0.12;

    return Transform.rotate(
      angle: headAngle,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.psychology, color: Colors.amber, size: 46),
            Positioned(
              top: 10,
              right: 7,
              child: Transform.rotate(
                angle: _animationController.value * math.pi * 4,
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF0F172A),
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E293B),
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: Center(child: _buildAnimatedIcon()),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBookPainter extends CustomPainter {
  final double progress;

  _AnimatedBookPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pagePaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final double centerX = size.width / 2;
    final double bottomY = size.height - 5;

    final double opening = 4 + (progress * 7);
    final double pageLift = progress * 8;

    // SOL SAYFA
    final Path leftPage = Path();

    leftPage.moveTo(centerX - 1, bottomY);

    leftPage.cubicTo(
      centerX - 8,
      bottomY - 7,
      centerX - 19 - opening,
      bottomY - 3,
      4,
      bottomY - 9,
    );

    leftPage.lineTo(4, 13 + pageLift);

    leftPage.cubicTo(10, 5 + pageLift, centerX - 11, 5, centerX - 1, 13);

    leftPage.close();

    // SAĞ SAYFA
    final Path rightPage = Path();

    rightPage.moveTo(centerX + 1, bottomY);

    rightPage.cubicTo(
      centerX + 8,
      bottomY - 7,
      centerX + 19 + opening,
      bottomY - 3,
      size.width - 4,
      bottomY - 9,
    );

    rightPage.lineTo(size.width - 4, 13 + pageLift);

    rightPage.cubicTo(
      size.width - 10,
      5 + pageLift,
      centerX + 11,
      5,
      centerX + 1,
      13,
    );

    rightPage.close();

    canvas.drawPath(leftPage, pagePaint);

    canvas.drawPath(rightPage, pagePaint);

    // ORTA KİTAP ÇİZGİSİ
    final Path centerLine = Path();

    centerLine.moveTo(centerX, 13);

    centerLine.quadraticBezierTo(centerX, 29, centerX, bottomY);

    canvas.drawPath(centerLine, linePaint);

    // SOL SAYFA ÇİZGİLERİ
    final Path leftLine1 = Path();

    leftLine1.moveTo(centerX - 6, 21);

    leftLine1.quadraticBezierTo(centerX - 15, 16 + pageLift, 10, 20 + pageLift);

    canvas.drawPath(leftLine1, linePaint);

    final Path leftLine2 = Path();

    leftLine2.moveTo(centerX - 6, 28);

    leftLine2.quadraticBezierTo(centerX - 15, 23 + pageLift, 10, 27 + pageLift);

    canvas.drawPath(leftLine2, linePaint);

    // SAĞ SAYFA ÇİZGİLERİ
    final Path rightLine1 = Path();

    rightLine1.moveTo(centerX + 6, 21);

    rightLine1.quadraticBezierTo(
      centerX + 15,
      16 + pageLift,
      size.width - 10,
      20 + pageLift,
    );

    canvas.drawPath(rightLine1, linePaint);

    final Path rightLine2 = Path();

    rightLine2.moveTo(centerX + 6, 28);

    rightLine2.quadraticBezierTo(
      centerX + 15,
      23 + pageLift,
      size.width - 10,
      27 + pageLift,
    );

    canvas.drawPath(rightLine2, linePaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBookPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
