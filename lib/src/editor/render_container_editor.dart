import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../flutter_quill.dart';
import '../common/extensions/node_ext.dart';
import '../document/nodes/container.dart' as container_node;
import 'selection/selectable_mixin.dart';

class EditableContainerParentData extends ContainerBoxParentData<RenderBox> {}

/// Multi-child render box of editable content.
///
/// Common ancestor for [RenderEditor] and [RenderEditableTextBlock].
class RenderEditableContainerBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, EditableContainerParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            EditableContainerParentData> {
  RenderEditableContainerBox({
    required this.container,
    required this.textDirection,
    required this.scrollBottomInset,
    required EdgeInsetsGeometry padding,
    List<RenderBox>? children,
  })  : assert(padding.isNonNegative),
        _padding = padding {
    addAll(children);
  }

  container_node.QuillContainer container;

  TextDirection textDirection;
  EdgeInsetsGeometry _padding;
  double scrollBottomInset;
  EdgeInsets? _resolvedPadding;

  EdgeInsets? get resolvedPadding => _resolvedPadding;

  SelectableMixin? childAtPosition(TextPosition position) {
    assert(firstChild != null);
    final targetNode = container.queryChild(position.offset, false).node;
    SelectableMixin? targetChild;
    for (final node in container.children) {
      if (targetNode == node) {
        targetChild = node.selectable;
      }
    }
    return targetChild;
  }

  /// We create a basic implementation (alternative) to childAfter and childBefore
  /// since that methods always throws asserts error (idk why)
  /// But, at least, this resolves the issue
  SelectableMixin? childAfterNode(Node before) {
    assert(firstChild != null);
    SelectableMixin? targetChild;
    for (var i = 0; i < container.childCount; i++) {
      final node = container.children.elementAtOrNull(i);
      if (before.renderBox == node?.renderBox) {
        targetChild = container.children.elementAtOrNull(i + 1)?.selectable;
      }
    }
    return targetChild ?? container.children.lastOrNull?.selectable;
  }

  /// We create a basic implementation (alternative) to childAfter and childBefore
  /// since that methods always throws asserts error (idk why)
  /// But, at least, this resolves the issue
  SelectableMixin? childBeforeNode(Node before) {
    assert(firstChild != null);
    SelectableMixin? targetChild;
    for (var i = container.childCount - 1; i > 0; i--) {
      final node = container.children.elementAtOrNull(i);
      if (before.renderBox == node?.renderBox) {
        targetChild = container.children.elementAtOrNull(i - 1)?.selectable;
      }
    }
    return targetChild ?? container.children.firstOrNull?.selectable;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    resolvePadding();
    return defaultComputeDistanceToFirstActualBaseline(baseline)! +
        _resolvedPadding!.top;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    resolvePadding();
    return _getIntrinsicMainAxis((child) {
      final childWidth = math.max<double>(
          0, width - _resolvedPadding!.left + _resolvedPadding!.right);
      return child.getMaxIntrinsicHeight(childWidth) +
          _resolvedPadding!.top +
          _resolvedPadding!.bottom;
    });
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    resolvePadding();
    return _getIntrinsicCrossAxis((child) {
      final childHeight = math.max<double>(
          0, height - _resolvedPadding!.top + _resolvedPadding!.bottom);
      return child.getMaxIntrinsicWidth(childHeight) +
          _resolvedPadding!.left +
          _resolvedPadding!.right;
    });
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    resolvePadding();
    return _getIntrinsicMainAxis((child) {
      final childWidth = math.max<double>(
          0, width - _resolvedPadding!.left + _resolvedPadding!.right);
      return child.getMinIntrinsicHeight(childWidth) +
          _resolvedPadding!.top +
          _resolvedPadding!.bottom;
    });
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    resolvePadding();
    return _getIntrinsicCrossAxis((child) {
      final childHeight = math.max<double>(
          0, height - _resolvedPadding!.top + _resolvedPadding!.bottom);
      return child.getMinIntrinsicWidth(childHeight) +
          _resolvedPadding!.left +
          _resolvedPadding!.right;
    });
  }

  EdgeInsetsGeometry getPadding() => _padding;

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    resolvePadding();
    assert(_resolvedPadding != null);

    var mainAxisExtent = _resolvedPadding!.top;
    var child = firstChild;
    final innerConstraints =
        BoxConstraints.tightFor(width: constraints.maxWidth)
            .deflate(_resolvedPadding!);
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final childParentData = (child.parentData as EditableContainerParentData)
        ..offset = Offset(_resolvedPadding!.left, mainAxisExtent);
      mainAxisExtent += child.size.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    mainAxisExtent += _resolvedPadding!.bottom;
    size = constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));

    assert(size.isFinite);
  }

  void resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }
    _resolvedPadding = _padding.resolve(textDirection);
    _resolvedPadding = _resolvedPadding!.copyWith(left: _resolvedPadding!.left);

    assert(_resolvedPadding!.isNonNegative);
  }

  void setContainer(container_node.QuillContainer c) {
    if (container == c) {
      return;
    }
    container = c;
    markNeedsLayout();
  }

  void setPadding(EdgeInsetsGeometry value) {
    assert(value.isNonNegative);
    if (_padding == value) {
      return;
    }
    _padding = value;
    _markNeedsPaddingResolution();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is EditableContainerParentData) {
      return;
    }

    child.parentData = EditableContainerParentData();
  }

  double _getIntrinsicCrossAxis(double Function(RenderBox child) childSize) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      final childParentData = child.parentData as EditableContainerParentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(double Function(RenderBox child) childSize) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent += childSize(child);
      final childParentData = child.parentData as EditableContainerParentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  void _markNeedsPaddingResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }
}
