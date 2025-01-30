import 'package:flutter/foundation.dart' show immutable;

@immutable
class HorizontalSpacing {
  const HorizontalSpacing(
    this.left,
    this.right,
  );

  final double left;
  final double right;

  static const zero = HorizontalSpacing(0, 0);

  HorizontalSpacing operator +(covariant HorizontalSpacing other) {
    return HorizontalSpacing(left + other.left, right + other.right);
  }
}
