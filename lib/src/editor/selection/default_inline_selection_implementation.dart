import 'package:flutter/material.dart';
import 'selectable_mixin.dart';

mixin DefaultSelectableMixin<T extends StatefulWidget>
    implements SelectableMixin<T> {
  /// this is the key of the entire component
  GlobalKey get containerKey;

  /// this is the key of a component that modifies the offset of QuillRichText
  GlobalKey get componentKey;

  @override

  /// this is the key of the references to the implementation of QuillRichText
  GlobalKey get forwardKey;

  SelectableMixin<StatefulWidget> get forward {
    if (forwardKey.currentState?.mounted ?? false) {
      return forwardKey.currentState as SelectableMixin;
    }
    throw Exception('Not founded a current state usable for selectables');
  }

  /// Returns a Rect for [Embed] nodes
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    final parentBox = containerKey.currentContext?.findRenderObject();
    final childBox = componentKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && childBox is RenderBox) {
      final offset = childBox.localToGlobal(Offset.zero, ancestor: parentBox);
      final size = parentBox.size;
      if (shiftWithBaseOffset) {
        return offset & (size - offset as Size);
      }
      return Offset.zero & (size - offset as Size);
    }
    return Rect.zero;
  }

  @override
  double get preferredLineHeight => forward.preferredLineHeight;

  @override
  double preferredLineHeightByPosition(TextPosition position) {
    return forward.preferredLineHeight;
  }

  @override
  Offset getOffsetForCaretByPosition(TextPosition position) {
    return forward.getOffsetForCaret(position, caretPrototype!);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    return forward.getPositionForOffset(offset);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return forward.getWordBoundary(position);
  }

  @override
  List<TextBox> getBoxesForSelection(TextSelection textSelection) {
    return forward.getBoxesForSelection(textSelection);
  }

  @override
  double? getFullHeightForCaret(TextPosition position) {
    return forward.getFullHeightForCaret(position);
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    return forward.getOffsetForCaret(
      position,
      caretPrototype,
    );
  }

  @override
  TextPosition globalToLocalPosition(TextPosition position) {
    return forward.globalToLocalPosition(position);
  }

  @override
  Rect getCaretPrototype(TextPosition position) {
    return forward.getCaretPrototype(position);
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    return forward.getLocalRectForCaret(position);
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    return forward.getLineBoundary(position);
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection) {
    return forward.getBaseEndpointForSelection(textSelection);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(
      TextSelection textSelection) {
    return forward.getExtentEndpointForSelection(textSelection);
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    return forward.getPositionAbove(position);
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    return forward.getPositionBelow(position);
  }
}
