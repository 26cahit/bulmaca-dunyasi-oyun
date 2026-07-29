import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class WheelPointer extends StatelessWidget {
  const WheelPointer({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    final pointerSize = responsive.clampWidth(0.10, min: 34, max: 46);

    return Positioned(
      top: -2,
      child: IgnorePointer(
        child: Container(
          width: pointerSize,
          height: pointerSize * 0.72,
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107),
            borderRadius: BorderRadius.circular(pointerSize * 0.18),
            border: Border.all(color: const Color(0xFFFFE082), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_drop_down_rounded,
            color: Colors.white,
            size: pointerSize * 0.75,
          ),
        ),
      ),
    );
  }
}
