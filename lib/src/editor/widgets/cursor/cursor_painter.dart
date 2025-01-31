import 'package:flutter/material.dart';

import '../../../../flutter_quill.dart';
import '../../../../internal.dart';
import '../../selection/selectable_mixin.dart';

/// Paints the editing cursor.
class CursorPainter extends CustomPainter {
  const CursorPainter({
    required this.delegate,
    required this.style,
    required this.color,
    required this.devicePixelRatio,
    required this.position,
    required this.lineHasEmbed,
    required this.node,
  });

  final TextPosition position;
  final bool lineHasEmbed;
  final SelectableMixin delegate;
  final CursorStyle style;
  final Color color;
  final Node node;
  final double devicePixelRatio;

  /// Paints cursor on [canvas] at specified [position].
  /// [offset] is global top left (x, y) of text line
  /// [position] is relative (x) in text line
  @override
  void paint(Canvas canvas, Size size) {
    // relative (x, y) to global offset
    var caretOffset = delegate.getOffsetForCaretByPosition(position);
    if (lineHasEmbed && caretOffset == Offset.zero) {
      caretOffset = delegate.getOffsetForCaret(
          TextPosition(
              offset: position.offset - 1, affinity: position.affinity),
          delegate.caretPrototype!);
      // Hardcoded 6 as estimate of the width of a character
      caretOffset = Offset(caretOffset.dx + 6, caretOffset.dy);
    }

    var caretRect = (delegate.caretPrototype ?? Rect.zero).shift(caretOffset);
    if (style.offset != null) {
      caretRect = caretRect.shift(style.offset!);
    }

    if (caretRect.left < 0.0) {
      // For iOS the cursor may get clipped by the scroll view when
      // it's located at a beginning of a line. We ensure that this
      // does not happen here. This may result in the cursor being painted
      // closer to the character on the right, but it's arguably better
      // then painting clipped cursor (or even cursor completely hidden).
      caretRect = caretRect.shift(Offset(-caretRect.left, 0));
    }

    final caretHeight = delegate.getFullHeightForCaret(position);
    if (caretHeight != null) {
      if (isAppleOSApp) {
        // Center the caret vertically along the text.
        caretRect = Rect.fromLTWH(
          caretRect.left,
          caretRect.top + (caretHeight - caretRect.height) / 2,
          caretRect.width,
          caretRect.height,
        );
      } else {
        // Override the height to take the full height of the glyph at the
        // TextPosition when not on iOS. iOS has special handling that
        // creates a taller caret.
        caretRect = Rect.fromLTWH(
          caretRect.left,
          caretRect.top - 2.0,
          caretRect.width,
          caretHeight,
        );
      }
    }

    final caretPosition = delegate.renderBox!.localToGlobal(caretRect.topLeft);
    final pixelMultiple = 1.0 / devicePixelRatio;

    final pixelPerfectOffsetX = caretPosition.dx.isFinite
        ? (caretPosition.dx / pixelMultiple).round() * pixelMultiple -
            caretPosition.dx
        : caretPosition.dx;
    final pixelPerfectOffsetY = caretPosition.dy.isFinite
        ? (caretPosition.dy / pixelMultiple).round() * pixelMultiple -
            caretPosition.dy
        : caretPosition.dy;

    final pixelPerfectOffset = Offset(pixelPerfectOffsetX, pixelPerfectOffsetY);
    if (!pixelPerfectOffset.isFinite) {
      return;
    }

    caretRect = caretRect.shift(pixelPerfectOffset);

    final paint = Paint()..color = color;
    if (style.radius == null) {
      canvas.drawRect(caretRect, paint);
    } else {
      final caretRRect = RRect.fromRectAndRadius(caretRect, style.radius!);
      canvas.drawRRect(caretRRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CursorPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.node.hashCode != node.hashCode ||
      // if the style change obviusly we will need to listen that changes
      oldDelegate.node.style != node.style ||
      oldDelegate.color != color ||
      oldDelegate.style != style;
}
