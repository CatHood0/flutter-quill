import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../flutter_quill.dart';
import '../../../internal.dart';
import '../widgets/delegate.dart';

/// Default implementation of gestures detector in Flutter Quill
//TODO: make a more exact implementation for every platform
class QuillEditorSelectionGestureDetectorBuilder
    extends EditorTextSelectionGestureDetectorBuilder {
  QuillEditorSelectionGestureDetectorBuilder(
    this._state,
    this._detectWordBoundary,
  ) : super(
          delegate: _state,
          detectWordBoundary: _detectWordBoundary,
        );

  final QuillEditorState _state;
  final bool _detectWordBoundary;

  @override
  void onForcePressStart(ForcePressDetails details) {
    super.onForcePressStart(details);
    if (delegate.selectionEnabled && shouldShowSelectionToolbar) {
      editor!.showToolbar();
    }
  }

  @override
  void onForcePressEnd(ForcePressDetails details) {}

  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_state.configurations.onSingleLongTapMoveUpdate != null) {
      if (renderEditor != null &&
          _state.configurations.onSingleLongTapMoveUpdate!(
            details,
            renderEditor!.getPositionForOffset,
          )) {
        return;
      }
    }
    if (!delegate.selectionEnabled) {
      return;
    }

    if (Theme.of(_state.context).isCupertino) {
      renderEditor!.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    } else {
      renderEditor!.selectWordsInRange(
        details.globalPosition - details.offsetFromOrigin,
        details.globalPosition,
        SelectionChangedCause.longPress,
      );
    }
  }

  bool _isPositionSelected(TapUpDetails details) {
    if (_state.controller.document.isEmpty()) {
      return false;
    }
    final pos = renderEditor!.getPositionForOffset(details.globalPosition);
    if (pos.offset <= -1) return false;
    final result =
        editor!.widget.controller.document.querySegmentLeafNode(pos.offset);
    final line = result.line;
    if (line == null) {
      return false;
    }
    final segmentLeaf = result.leaf;
    if (segmentLeaf == null && line.length == 1) {
      editor!.widget.controller.updateSelection(
        TextSelection.collapsed(offset: pos.offset),
        ChangeSource.local,
      );
      return true;
    }
    return false;
  }

  @override
  void onTapDown(TapDownDetails details) {
    if (_state.configurations.onTapDown != null) {
      if (renderEditor != null &&
          _state.configurations.onTapDown!(
            details,
            renderEditor!.getPositionForOffset,
          )) {
        return;
      }
    }
    super.onTapDown(details);
  }

  bool isShiftClick(PointerDeviceKind deviceKind) {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    return deviceKind == PointerDeviceKind.mouse &&
        (pressed.contains(LogicalKeyboardKey.shiftLeft) ||
            pressed.contains(LogicalKeyboardKey.shiftRight));
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    if (_state.configurations.onTapUp != null &&
        renderEditor != null &&
        _state.configurations.onTapUp!(
          details,
          renderEditor!.getPositionForOffset,
        )) {
      return;
    }

    editor!.hideToolbar();

    try {
      if (delegate.selectionEnabled && !_isPositionSelected(details)) {
        if (isAppleOS || isDesktop) {
          // added isDesktop() to enable extend selection in Windows platform
          switch (details.kind) {
            case PointerDeviceKind.mouse:
            case PointerDeviceKind.stylus:
            case PointerDeviceKind.invertedStylus:
              // Precise devices should place the cursor at a precise position.
              // If `Shift` key is pressed then
              // extend current selection instead.
              if (isShiftClick(details.kind)) {
                renderEditor!
                  ..extendSelection(details.globalPosition,
                      cause: SelectionChangedCause.tap)
                  ..onSelectionCompleted();
              } else {
                renderEditor!
                  ..selectPosition(cause: SelectionChangedCause.tap)
                  ..onSelectionCompleted();
              }

              break;
            case PointerDeviceKind.touch:
            case PointerDeviceKind.unknown:
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge
              // of the word.
              if (_detectWordBoundary) {
                renderEditor!
                  ..selectWordEdge(SelectionChangedCause.tap)
                  ..onSelectionCompleted();
              } else {
                renderEditor!
                  ..selectPosition(cause: SelectionChangedCause.tap)
                  ..onSelectionCompleted();
              }
              break;
            case PointerDeviceKind.trackpad:
              // TODO: Handle this case.
              break;
          }
        } else {
          renderEditor!
            ..selectPosition(cause: SelectionChangedCause.tap)
            ..onSelectionCompleted();
        }
      }
    } finally {
      _state.requestKeyboard();
    }
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (_state.configurations.onSingleLongTapStart != null) {
      if (renderEditor != null &&
          _state.configurations.onSingleLongTapStart!(
            details,
            renderEditor!.getPositionForOffset,
          )) {
        return;
      }
    }

    if (delegate.selectionEnabled) {
      if (Theme.of(_state.context).isCupertino) {
        renderEditor!.selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
        );
      } else {
        renderEditor!.selectWord(SelectionChangedCause.longPress);
        Feedback.forLongPress(_state.context);
      }
    }
  }

  @override
  void onSingleLongTapEnd(LongPressEndDetails details) {
    if (_state.configurations.onSingleLongTapEnd != null) {
      if (renderEditor != null) {
        if (_state.configurations.onSingleLongTapEnd!(
          details,
          renderEditor!.getPositionForOffset,
        )) {
          return;
        }

        if (delegate.selectionEnabled) {
          renderEditor!.onSelectionCompleted();
        }
      }
    }
    super.onSingleLongTapEnd(details);
  }
}
