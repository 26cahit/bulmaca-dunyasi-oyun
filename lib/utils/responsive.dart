import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;

  Responsive(this.context);

  Size get screenSize => MediaQuery.sizeOf(context);

  double get width => screenSize.width;

  double get height => screenSize.height;

  double get safeHeight =>
      height -
      MediaQuery.paddingOf(context).top -
      MediaQuery.paddingOf(context).bottom;

  bool get isSmallPhone => width < 360;

  bool get isMediumPhone => width >= 360 && width < 430;

  bool get isLargePhone => width >= 430;

  double wp(double percent) {
    return width * percent;
  }

  double hp(double percent) {
    return safeHeight * percent;
  }

  double clampWidth(
    double percent, {
    required double min,
    required double max,
  }) {
    return wp(percent).clamp(min, max).toDouble();
  }

  double clampHeight(
    double percent, {
    required double min,
    required double max,
  }) {
    return hp(percent).clamp(min, max).toDouble();
  }

  double font(double size, {double minScale = 0.85, double maxScale = 1.15}) {
    final scale = width / 390;

    return (size * scale.clamp(minScale, maxScale)).toDouble();
  }

  double get horizontalPadding {
    return clampWidth(0.045, min: 12, max: 24);
  }

  double get smallGap {
    return clampHeight(0.008, min: 4, max: 8);
  }

  double get mediumGap {
    return clampHeight(0.015, min: 8, max: 14);
  }

  double get largeGap {
    return clampHeight(0.025, min: 12, max: 22);
  }
}
