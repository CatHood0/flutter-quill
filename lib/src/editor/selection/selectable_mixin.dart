import 'package:flutter/material.dart';

import '../../../flutter_quill.dart';
import '../../../internal.dart';
import '../../common/extensions/node_ext.dart';
import '../../document/nodes/container.dart';

mixin SelectableMixin<T extends StatefulWidget> on State<T> {
  Rect? _caretPrototype;
  Rect? get caretPrototype => _caretPrototype;

  /// The node that is being wrapped by the selectable.
  QuillContainer get container;

  GlobalKey get containerKey;

  RenderBox? get renderBox => container.renderBox;

  CursorCont get cursorCont;

  double get cursorHeight =>
      cursorCont.style.height ??
      preferredLineHeightByPosition(
        const TextPosition(offset: 0),
      );

  double get cursorWidth => cursorCont.style.width;

  SelectableMixin<StatefulWidget> get forward =>
      forwardKey.currentState as SelectableMixin;

  // rich text key
  GlobalKey get forwardKey;

  /// Returns preferred line height at specified `position` in text.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  double get preferredLineHeight;

  // TODO: This is no longer producing the highest-fidelity caret
  // heights for Android, especially when non-alphabetic languages
  // are involved. The current implementation overrides the height set
  // here with the full measured height of the text on Android which looks
  // superior (subjectively and in terms of fidelity) in _paintCaret. We
  // should rework this properly to once again match the platform. The constant
  // _kCaretHeightOffset scales poorly for small font sizes.
  //
  /// Gives the correct values to the caretPrototype that is used to calculate
  /// the Rect for caret
  ///
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

  /// Returns a point for the base selection handle used on touch-oriented
  /// devices.
  ///
  /// The `selection` parameter is expected to be in local offsets to this
  /// render object's [node].
  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection);

  /// Returns a Rect for [Embed] nodes
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    final parentBox = renderBox;
    final childBox = forwardKey.currentContext?.findRenderObject();
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

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  ///
  /// Valid only after [layout].
  List<TextBox> getBoxesForSelection(TextSelection textSelection);

  /// Returns the [Rect] of the caret prototype at the given text
  /// position. [Rect] starts at origin.
  Rect getCaretPrototype(TextPosition position);

  /// Returns a point for the extent selection handle used on touch-oriented
  /// devices.
  ///
  /// The `selection` parameter is expected to be in local offsets to this
  /// render object's [node].
  TextSelectionPoint getExtentEndpointForSelection(TextSelection textSelection);

  /// Returns the height value for the caret
  double? getFullHeightForCaret(TextPosition position);

  TextRange getLineBoundary(TextPosition position);

  /// Returns the [Rect] in local coordinates for the caret at the given text
  /// position.
  Rect getLocalRectForCaret(TextPosition position);

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype);

  /// Returns the offset at which to paint the caret.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  ///
  /// Valid only after [layout].
  Offset getOffsetForCaretByPosition(TextPosition position);

  /// Returns the position within the text which is on the line above the given
  /// `position`.
  ///
  /// The `position` parameter must be relative to the [node] content.
  ///
  /// Primarily used with multi-line or soft-wrapping text.
  ///
  /// Can return `null` which indicates that the `position` is at the topmost
  /// line in the text already.
  TextPosition? getPositionAbove(TextPosition position);

  /// Returns the position within the text which is on the line below the given
  /// `position`.
  ///
  /// The `position` parameter must be relative to the [node] content.
  ///
  /// Primarily used with multi-line or soft-wrapping text.
  ///
  /// Can return `null` which indicates that the `position` is at the bottommost
  /// line in the text already.
  TextPosition? getPositionBelow(TextPosition position);

  /// Returns the position within the text for the given pixel offset.
  ///
  /// The `offset` parameter must be local to this box coordinate system.
  ///
  /// Valid only after [layout].
  TextPosition getPositionForOffset(Offset offset);

  /// Returns the text range of the word at the given offset. Characters not
  /// part of a word, such as spaces, symbols, and punctuation, have word breaks
  /// on both sides. In such cases, this method will return a text range that
  /// contains the given text position.
  ///
  /// Word boundaries are defined more precisely in Unicode Standard Annex #29
  /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  ///
  /// Valid only after [layout].
  TextRange getWordBoundary(TextPosition position);

  /// Returns the position relative to the [node] content
  ///
  /// The `position` must be within the [node] content
  TextPosition globalToLocalPosition(TextPosition position);

  /// Returns preferred line height at specified `position` in text.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  double preferredLineHeightByPosition(TextPosition position);
}
