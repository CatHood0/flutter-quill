import 'package:flutter/material.dart';
import 'selectable_mixin.dart';

mixin DefaultSelectableMixin<T extends StatefulWidget>
    implements SelectableMixin<T> {
  /// this is the key of the entire component
  @override
  GlobalKey get containerKey;

  /// this is the key of a component that modifies the offset of QuillRichText
  @override
  GlobalKey get componentKey;

  /// this is the key of the references to the implementation of QuillRichText
  @override
  GlobalKey get forwardKey;

  @override
  void computeCaretPrototype() => forward?.computeCaretPrototype();

  SelectableMixin<StatefulWidget>? get forward {
    final state = forwardKey.currentState;
    if (state is SelectableMixin<StatefulWidget>) {
      return state;
    }
    return null;
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
  double get preferredLineHeight => forward?.preferredLineHeight ?? 4.0;

  @override
  double preferredLineHeightByPosition(TextPosition position) {
    return forward?.preferredLineHeight ?? 4.0;
  }

  @override
  Offset getOffsetForCaretByPosition(TextPosition position) {
    return forward?.getOffsetForCaret(position, caretPrototype!) ?? Offset.zero;
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    return forward?.getPositionForOffset(offset) ??
        const TextPosition(offset: -1, affinity: TextAffinity.downstream);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return forward?.getWordBoundary(position) ??
        const TextRange(start: -1, end: -1);
  }

  @override
  List<TextBox> getBoxesForSelection(TextSelection textSelection) {
    return forward?.getBoxesForSelection(textSelection) ?? [];
  }

  @override
  double? getFullHeightForCaret(TextPosition position) {
    return forward?.getFullHeightForCaret(position);
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    return forward?.getOffsetForCaret(
          position,
          caretPrototype,
        ) ??
        Offset.zero;
  }

  @override
  TextPosition globalToLocalPosition(TextPosition position) {
    return forward?.globalToLocalPosition(position) ??
        const TextPosition(offset: -1, affinity: TextAffinity.downstream);
  }

  @override
  Rect getCaretPrototype(TextPosition position) {
    return forward?.getCaretPrototype(position) ?? Rect.zero;
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    return forward?.getLocalRectForCaret(position) ?? Rect.zero;
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    return forward?.getLineBoundary(position) ??
        const TextRange(start: -1, end: -1);
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection) {
    return forward?.getBaseEndpointForSelection(textSelection) ??
        const TextSelectionPoint(Offset.zero, TextDirection.ltr);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(
      TextSelection textSelection) {
    return forward?.getExtentEndpointForSelection(textSelection) ??
        const TextSelectionPoint(Offset.zero, TextDirection.ltr);
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    return forward?.getPositionAbove(position) ??
        const TextPosition(offset: -1, affinity: TextAffinity.downstream);
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    return forward?.getPositionBelow(position) ??
        const TextPosition(offset: -1, affinity: TextAffinity.downstream);
  }
}
