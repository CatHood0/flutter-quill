import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../common/extensions/node_ext.dart';
import '../../document/nodes/container.dart';

mixin SelectableMixin<T extends StatefulWidget> on State<T> {
  Rect? _caretPrototype;
  Rect? get caretPrototype => _caretPrototype;

  @internal
  set setCaretPrototype(Rect caret) => _caretPrototype = caret;

  void computeCaretPrototype();

  /// this is the key of the entire component
  GlobalKey get containerKey;

  /// this is the key of a component that modifies the offset of QuillRichText
  GlobalKey get componentKey;

  /// this is the key of the references to the implementation of QuillRichText
  GlobalKey get forwardKey;

  /// The node that is being wrapped by the selectable.
  QuillContainer get node;

  RenderBox? get renderBox => node.renderBox;

  /// Returns preferred line height at specified `position` in text.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  double get preferredLineHeight;

  /// Returns a point for the base selection handle used on touch-oriented
  /// devices.
  ///
  /// The `selection` parameter is expected to be in local offsets to this
  /// render object's [node].
  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection);

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
