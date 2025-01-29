import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class AnimatedSelectionAreaPainter extends CustomPainter {
  const AnimatedSelectionAreaPainter({
    required this.rects,
    required this.colors,
    required this.animation,
  });

  final List<Rect> rects;
  final List<Color> colors;
  final double animation;

  @override
  void paint(Canvas canvas, Size size) {
    for (final rect in rects) {
      final paint = Paint()
        ..shader = LinearGradient(
          colors: colors,
          transform: GradientRotation(animation * 2 * math.pi),
        ).createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedSelectionAreaPainter oldDelegate) {
    return animation != oldDelegate.animation ||
        !const DeepCollectionEquality().equals(colors, oldDelegate.colors) ||
        !const DeepCollectionEquality().equals(rects, oldDelegate.rects);
  }
}
