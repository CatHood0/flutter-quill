import 'package:flutter/material.dart';

import '../../../flutter_quill.dart';
import '../../../internal.dart';
import '../../common/extensions/node_ext.dart';
import '../../document/nodes/container.dart';

mixin SelectableMixin<T extends StatefulWidget> on State<T> {
  // rich text key
  GlobalKey get forwardKey;
  GlobalKey get containerKey;

  SelectableMixin<StatefulWidget> get forward => forwardKey.currentState as SelectableMixin;

  CursorCont get cursorCont;

  Rect? _caretPrototype;
  Rect? get caretPrototype => _caretPrototype;

  QuillContainer get container;

  double get preferredLineHeight;

  Offset getOffsetForCaretByPosition(TextPosition position);

  TextPosition getPositionForOffset(Offset offset);

  double? getFullHeightForCaret(TextPosition position);

  TextRange getWordBoundary(TextPosition position);

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype);

  /// Returns the [Rect] of the caret prototype at the given text
  /// position. [Rect] starts at origin.
  Rect getCaretPrototype(TextPosition position);

  /// Returns the [Rect] in local coordinates for the caret at the given text
  /// position.
  Rect getLocalRectForCaret(TextPosition position);

  /// Returns the position relative to the [node] content
  ///
  /// The `position` must be within the [node] content
  TextPosition globalToLocalPosition(TextPosition position);

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  ///
  /// Valid only after [layout]
  List<TextBox> getBoxesForSelection(TextSelection textSelection);

  TextDirection textDirection() => TextDirection.ltr;

  /// Returns preferred line height at specified `position` in text.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  double preferredLineHeightByPosition(TextPosition position);

  TextPosition? getPositionAbove(TextPosition position);

  TextPosition? getPositionBelow(TextPosition position);

  TextRange getLineBoundary(TextPosition position);

  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection);

  TextSelectionPoint getExtentEndpointForSelection(TextSelection textSelection);

  // start default implementations
  //
  /// only used on embeds
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    final box = renderBox;
    if (box is RenderBox) {
      final offset = box.localToGlobal(Offset.zero, ancestor: box);
      final size = box.size;
      if (shiftWithBaseOffset) {
        return offset & (size - offset as Size);
      }
      return Offset.zero & (size - offset as Size);
    }
    return Rect.zero;
  }

  RenderBox? get renderBox => container.renderBox;

  // TODO: This is no longer producing the highest-fidelity caret
  // heights for Android, especially when non-alphabetic languages
  // are involved. The current implementation overrides the height set
  // here with the full measured height of the text on Android which looks
  // superior (subjectively and in terms of fidelity) in _paintCaret. We
  // should rework this properly to once again match the platform. The constant
  // _kCaretHeightOffset scales poorly for small font sizes.
  //
  /// On iOS, the cursor is taller than the cursor on Android. The height
  /// of the cursor for iOS is approximate and obtained through an eyeball
  /// comparison.
  void computeCaretPrototype() {
    if (isIos) {
      _caretPrototype = Rect.fromLTWH(0, 0, cursorWidth, cursorHeight + 2);
    } else {
      _caretPrototype = Rect.fromLTWH(0, 2, cursorWidth, cursorHeight - 4.0);
    }
  }

  double get cursorWidth => cursorCont.style.width;

  double get cursorHeight =>
      cursorCont.style.height ??
      preferredLineHeightByPosition(
        const TextPosition(offset: 0),
      );
}
