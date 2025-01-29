import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'selectable_mixin.dart';

mixin DefaultTextSelectionMixinImplementation<T extends StatefulWidget> implements SelectableMixin<T> {
  TextPainter get prototypePainter;
  // component with selectable mixin implementation
  @override
  SelectableMixin<StatefulWidget> get forward;
  @override
  GlobalKey<State<StatefulWidget>> get forwardKey;

  RenderParagraph? get paragraph;

  @override
  double get preferredLineHeight => prototypePainter.preferredLineHeight;

  @override
  double preferredLineHeightByPosition(TextPosition position) {
    return preferredLineHeight;
  }

  @override
  Offset getOffsetForCaretByPosition(TextPosition position) {
    return getOffsetForCaret(position, caretPrototype!) + (renderBox!.parentData as BoxParentData).offset;
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    return paragraph?.getPositionForOffset(offset - (renderBox!.parentData as BoxParentData).offset) ??
        const TextPosition(offset: 0);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return paragraph?.getWordBoundary(position) ?? const TextRange(start: 0, end: 0);
  }

  @override
  List<TextBox> getBoxesForSelection(TextSelection textSelection) {
    return paragraph?.getBoxesForSelection(textSelection) ?? [];
  }

  @override
  double? getFullHeightForCaret(TextPosition position) {
    return paragraph?.getFullHeightForCaret(position) ?? 0;
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    return (paragraph?.getOffsetForCaret(
              position,
              caretPrototype,
            ) ??
            const Offset(0, 0)) +
        (renderBox!.parentData as BoxParentData).offset;
  }

  @override
  TextPosition globalToLocalPosition(TextPosition position) {
    assert(container.containsOffset(position.offset), 'The provided text position is not in the current node');
    return TextPosition(
      offset: position.offset - container.documentOffset,
      affinity: position.affinity,
    );
  }

  @override
  Rect getCaretPrototype(TextPosition position) {
    if (caretPrototype == null) computeCaretPrototype();
    return caretPrototype!;
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    final caretOffset = getOffsetForCaret(position, caretPrototype ?? getCaretPrototype(position));
    var rect = Rect.fromLTWH(
      0,
      0,
      cursorWidth,
      cursorHeight,
    ).shift(caretOffset);
    final cursorOffset = cursorCont.style.offset;
    // Add additional cursor offset (generally only if on iOS).
    if (cursorOffset != null) rect = rect.shift(cursorOffset);
    return rect;
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    final lineDy = getOffsetForCaretByPosition(position)
        .translate(
          0,
          0.5 *
              preferredLineHeightByPosition(
                position,
              ),
        )
        .dy;
    final lineBoxes = getBoxes(
      TextSelection(baseOffset: 0, extentOffset: container.length - 1),
    )
        .where(
          (element) => element.top < lineDy && element.bottom > lineDy,
        )
        .toList(growable: false);
    return TextRange(
        start: getPositionForOffset(
          Offset(lineBoxes.first.left, lineDy),
        ).offset,
        end: getPositionForOffset(
          Offset(lineBoxes.last.right, lineDy),
        ).offset);
  }

  List<TextBox> getBoxes(TextSelection textSelection) {
    // this is the parent key
    final parentData = renderBox!.parentData as BoxParentData?;
    return getBoxesForSelection(textSelection).map((box) {
      return TextBox.fromLTRBD(
        box.left + parentData!.offset.dx,
        box.top + parentData.offset.dy,
        box.right + parentData.offset.dx,
        box.bottom + parentData.offset.dy,
        box.direction,
      );
    }).toList(growable: false);
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection) {
    return _getEndpointForSelection(textSelection, true);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(TextSelection textSelection) {
    return _getEndpointForSelection(
      textSelection,
      false,
    );
  }

  TextSelectionPoint _getEndpointForSelection(
    TextSelection textSelection,
    bool first,
  ) {
    if (textSelection.isCollapsed) {
      return TextSelectionPoint(
        Offset(0, preferredLineHeight) +
            getOffsetForCaretByPosition(
              textSelection.extent,
            ),
        textDirection(),
      );
    }
    final boxes = getBoxes(textSelection);
    assert(boxes.isNotEmpty);
    final targetBox = first ? boxes.first : boxes.last;
    return TextSelectionPoint(
      Offset(first ? targetBox.start : targetBox.end, targetBox.bottom),
      targetBox.direction,
    );
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    double? maxOffset;
    double limit() => maxOffset ??=
        context.findRenderObject()!.semanticBounds.height / preferredLineHeightByPosition(position) + 1;
    bool checkLimit(double offset) => offset < 4.0 ? false : offset > limit();

    /// Move up by fraction of the default font height, larger font sizes need larger offset, embed images need larger offset
    for (var offset = 0.5;; offset += offset < 4 ? 0.25 : 1.0) {
      final pos = _getPosition(position, -offset);
      if (pos?.offset != position.offset || checkLimit(offset)) {
        return pos;
      }
    }
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    return _getPosition(position, 1.5);
  }

  TextPosition? _getPosition(TextPosition textPosition, double dyScale) {
    assert(textPosition.offset < container.length);
    final body = context.findRenderObject();
    final offset = getOffsetForCaretByPosition(textPosition)
        .translate(0, dyScale * preferredLineHeightByPosition(textPosition));
    if ((body! as RenderBox).size.contains(offset - (body.parentData as BoxParentData).offset)) {
      return getPositionForOffset(offset);
    }
    return null;
  }
}
