import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/sound_service.dart';
import '../../utils/responsive.dart';
import 'wheel_pointer.dart';

class WheelWidget extends StatefulWidget {
  final Function(String) onLetterSelected;
  final Set<String> usedLetters;
  final String currentWord;

  const WheelWidget({
    super.key,
    required this.onLetterSelected,
    required this.usedLetters,
    required this.currentWord,
  });

  @override
  State<WheelWidget> createState() => _WheelWidgetState();
}

class _WheelWidgetState extends State<WheelWidget>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _lightController;
  late final AnimationController _resultController;

  late Animation<double> _spinAnimation;

  final Random random = Random();

  double _currentAngle = 0;

  final List<String> letters = [
    "A",
    "B",
    "C",
    "Ç",
    "D",
    "E",
    "F",
    "G",
    "Ğ",
    "H",
    "I",
    "İ",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "Ö",
    "P",
    "R",
    "S",
    "Ş",
    "T",
    "U",
    "Ü",
    "V",
    "Y",
    "Z",
  ];

  String selectedLetter = "";
  String statusMessage = "";

  Color statusColor = Colors.white70;

  bool spinning = false;

  Color? resultRingColor;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _lightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _spinAnimation = AlwaysStoppedAnimation<double>(_currentAngle);
  }

  @override
  void dispose() {
    SoundService.stopWheel();

    _spinController.dispose();
    _lightController.dispose();
    _resultController.dispose();

    super.dispose();
  }

  void spinWheel() {
    if (spinning) return;

    _resultController.stop();
    _resultController.reset();

    setState(() {
      spinning = true;
      selectedLetter = "";
      statusMessage = "";
      resultRingColor = null;
    });

    SoundService.playWheel();

    final double letterAngle = (2 * pi) / letters.length;

    final int selectedIndex = random.nextInt(letters.length);

    final String finalLetter = letters[selectedIndex];

    final double exactStopAngle =
        (2 * pi - (selectedIndex * letterAngle)) % (2 * pi);

    final double currentNormalized = _currentAngle % (2 * pi);

    double angleDifference = exactStopAngle - currentNormalized;

    if (angleDifference < 0) {
      angleDifference += 2 * pi;
    }

    const int fullRotations = 2;

    final double target =
        _currentAngle + (fullRotations * 2 * pi) + angleDifference;

    _spinAnimation = Tween<double>(begin: _currentAngle, end: target).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );

    void animationListener() {
      if (!mounted) return;

      setState(() {});
    }

    void statusListener(AnimationStatus status) {
      if (status != AnimationStatus.completed) {
        return;
      }

      _currentAngle = target;

      SoundService.stopWheel();

      final bool found = widget.currentWord.contains(finalLetter);

      if (!mounted) return;

      setState(() {
        selectedLetter = finalLetter;
        spinning = false;

        if (found) {
          statusMessage = "✅ Harf bulundu";
          statusColor = Colors.green;
          resultRingColor = Colors.green;

          SoundService.playCorrect();
        } else {
          statusMessage = "❌ Harf bulunamadı";
          statusColor = Colors.red;
          resultRingColor = Colors.red;

          SoundService.playWrong();
        }
      });

      _resultController.repeat(reverse: true);

      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;

        _resultController.stop();

        _resultController.reset();

        setState(() {
          resultRingColor = null;
        });
      });

      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;

        widget.onLetterSelected(finalLetter);
      });

      _spinAnimation.removeListener(animationListener);

      _spinController.removeStatusListener(statusListener);
    }

    _spinAnimation.addListener(animationListener);

    _spinController.addStatusListener(statusListener);

    _spinController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    final double angle = _spinController.isAnimating
        ? _spinAnimation.value
        : _currentAngle;

    final double wheelSize = responsive.clampWidth(0.84, min: 260, max: 360);

    final double buttonSize = wheelSize * 0.43;

    final double letterFontSize = responsive.font(
      20,
      minScale: 0.80,
      maxScale: 1.10,
    );

    final double selectedLetterFontSize = responsive.font(
      42,
      minScale: 0.80,
      maxScale: 1.10,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: selectedLetter.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.only(bottom: responsive.smallGap),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Seçilen Harf",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: responsive.font(15),
                        ),
                      ),

                      SizedBox(height: responsive.smallGap),

                      Text(
                        selectedLetter,
                        style: TextStyle(
                          color: widget.currentWord.contains(selectedLetter)
                              ? Colors.green
                              : Colors.red,
                          fontSize: selectedLetterFontSize,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),

                      SizedBox(height: responsive.smallGap),

                      Text(
                        statusMessage,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: responsive.font(15),
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        AnimatedBuilder(
          animation: Listenable.merge([_lightController, _resultController]),
          builder: (context, child) {
            final double resultValue = _resultController.value;

            return SizedBox(
              width: wheelSize + 24,
              height: wheelSize + 24,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (resultRingColor != null)
                    Container(
                      width: wheelSize + 20 + (resultValue * 8),
                      height: wheelSize + 20 + (resultValue * 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: resultRingColor!.withValues(
                            alpha: 0.30 + (resultValue * 0.70),
                          ),
                          width: 4 + (resultValue * 3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: resultRingColor!.withValues(
                              alpha: 0.20 + (resultValue * 0.55),
                            ),
                            blurRadius: 10 + (resultValue * 24),
                            spreadRadius: 2 + (resultValue * 7),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    width: wheelSize + 12,
                    height: wheelSize + 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFC107),
                        width: 4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FFC107),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: wheelSize + 3,
                    height: wheelSize + 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                        width: 2,
                      ),
                    ),
                  ),

                  ...List.generate(18, (index) {
                    final double lightAngle = (2 * pi / 18) * index;

                    final double pulse =
                        (sin((_lightController.value * 2 * pi) + lightAngle) +
                            1) /
                        2;

                    final double radius = (wheelSize / 2) + 6;

                    return Transform.translate(
                      offset: Offset(
                        cos(lightAngle) * radius,
                        sin(lightAngle) * radius,
                      ),
                      child: Container(
                        width: 5 + (pulse * 3),
                        height: 5 + (pulse * 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(
                            alpha: 0.35 + (pulse * 0.65),
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: pulse),
                              blurRadius: 3 + (pulse * 8),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  Transform.rotate(
                    angle: angle,
                    child: CustomPaint(
                      size: Size.square(wheelSize),
                      painter: _WheelPainter(
                        letters: letters,
                        letterFontSize: letterFontSize,
                      ),
                    ),
                  ),

                  const WheelPointer(),

                  Container(
                    width: buttonSize + 18,
                    height: buttonSize + 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF111827),
                      border: Border.all(color: Colors.amber, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FFC107),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: buttonSize + 7,
                    height: buttonSize + 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                        width: 2,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: buttonSize,
                    height: buttonSize,
                    child: ElevatedButton(
                      onPressed: spinning ? null : spinWheel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        disabledBackgroundColor: Colors.white70,
                        foregroundColor: const Color(0xFF0F172A),
                        shape: const CircleBorder(),
                        elevation: 12,
                        shadowColor: Colors.black,
                        padding: EdgeInsets.zero,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            spinning ? "DÖNÜYOR" : "DÖNDÜR",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: responsive.font(22),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> letters;
  final double letterFontSize;

  const _WheelPainter({required this.letters, required this.letterFontSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final double radius = size.width / 2;

    final double sweepAngle = (2 * pi) / letters.length;

    final Rect wheelRect = Rect.fromCircle(center: center, radius: radius - 5);

    final Paint slicePaint = Paint()..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final Paint innerRingPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int index = 0; index < letters.length; index++) {
      final double startAngle =
          (-pi / 2) - (sweepAngle / 2) + (index * sweepAngle);

      slicePaint.color = index.isEven
          ? const Color(0xFF172554)
          : const Color(0xFF4C1D95);

      canvas.drawArc(wheelRect, startAngle, sweepAngle, true, slicePaint);

      final double lineAngle = startAngle + sweepAngle;

      final Offset lineEnd = Offset(
        center.dx + cos(lineAngle) * (radius - 5),
        center.dy + sin(lineAngle) * (radius - 5),
      );

      canvas.drawLine(center, lineEnd, linePaint);

      final double textAngle = startAngle + (sweepAngle / 2);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: letters[index],
          style: TextStyle(
            color: Colors.white,
            fontSize: letterFontSize,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 5, offset: Offset(0, 2)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      final double textRadius = radius * 0.84;

      final Offset textCenter = Offset(
        center.dx + cos(textAngle) * textRadius,
        center.dy + sin(textAngle) * textRadius,
      );

      canvas.save();

      canvas.translate(textCenter.dx, textCenter.dy);

      canvas.rotate(textAngle + (pi / 2));

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    canvas.drawCircle(center, radius * 0.50, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.letters != letters ||
        oldDelegate.letterFontSize != letterFontSize;
  }
}
