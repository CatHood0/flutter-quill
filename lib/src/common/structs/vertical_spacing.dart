import 'package:flutter/foundation.dart' show immutable;

@immutable
class VerticalSpacing {
  const VerticalSpacing(
    this.top,
    this.bottom,
  );

  final double top;
  final double bottom;

  static const zero = VerticalSpacing(0, 0);

  VerticalSpacing operator +(covariant VerticalSpacing other) {
    return VerticalSpacing(top + other.top, bottom + other.bottom);
  }
}
