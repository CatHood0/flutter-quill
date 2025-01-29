import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class SelectionAreaPaint extends StatelessWidget {
  const SelectionAreaPaint({
    required this.rects,
    required this.selectionColor,
    super.key,
  });

  final List<Rect> rects;
  final Color selectionColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SelectionAreaPainter(
        rects: rects,
        selectionColor: selectionColor,
      ),
    );
  }
}

class SelectionAreaPainter extends CustomPainter {
  SelectionAreaPainter({
    required this.rects,
    required this.selectionColor,
  });

  final List<Rect> rects;
  final Color selectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = selectionColor
      ..style = PaintingStyle.fill;

    for (var rect in rects) {
      // if rect.width is 0, we draw a small rect to indicate the selection area
      if (rect.width <= 0) {
        rect = Rect.fromLTWH(rect.left, rect.top, 8.0, rect.height);
      }
      canvas.drawRect(
        rect,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SelectionAreaPainter oldDelegate) {
    return selectionColor != oldDelegate.selectionColor ||
        !const DeepCollectionEquality().equals(rects, oldDelegate.rects);
  }
}
