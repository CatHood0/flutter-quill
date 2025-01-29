import 'package:flutter/material.dart';

import '../../../flutter_quill.dart';
import '../../editor/selection/selectable_mixin.dart';
import 'unwrap_ext.dart';

extension NodeExtensions on Node {
  RenderBox? get renderBox =>
      key.currentContext?.findRenderObject()?.unwrapOrNull<RenderBox>();

  BuildContext? get context => key.currentContext;
  SelectableMixin? get selectable =>
      key.currentState?.unwrapOrNull<SelectableMixin>();

  Rect get rect {
    if (renderBox != null) {
      final boxOffset = renderBox!.localToGlobal(Offset.zero);
      return boxOffset & renderBox!.size;
    }
    return Rect.zero;
  }
}
