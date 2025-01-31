import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../flutter_quill.dart';
import '../../../document/nodes/container.dart';
import '../../widgets/text/text_selection.dart';
import '../painter/selection_area_painter.dart';
import '../selectable_mixin.dart';

/// This is the encharged to paint all the rects
class SelectionAreaForNodeWidget extends StatefulWidget {
  const SelectionAreaForNodeWidget({
    required this.selection,
    required this.delegate,
    required this.cursorCont,
    required this.container,
    required this.hasFocus,
    super.key,
  });

  final QuillContainer container;
  final bool hasFocus;
  final ValueNotifier<TextSelection> selection;
  final SelectableMixin delegate;
  final CursorCont cursorCont;

  @override
  State<SelectionAreaForNodeWidget> createState() =>
      _SelectionAreaForNodeWidgetState();
}

class _SelectionAreaForNodeWidgetState
    extends State<SelectionAreaForNodeWidget> {
  // keep the previous cursor rect to avoid unnecessary rebuild
  Rect? prevCursorRect;
  // keep the previous selection rects to avoid unnecessary rebuild
  List<Rect>? prevSelectionRects;
  // keep the previous block rects to avoid unnecessary rebuild
  Rect? prevBlockRect;

  bool _containsCursor = false;

  // we use these vars to avoid unnecessary rebuild
  TextSelection? oldSelection;
  // old version of node
  Node? oldNodeV;

  @override
  void initState() {
    widget.delegate.computeCaretPrototype();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _updateSelectionRectsIfNeeded();
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void updateUI() {}

  bool _containsTextSelection(TextSelection current) {
    return widget.container.documentOffset <= current.end &&
        current.start <=
            widget.container.documentOffset + widget.container.length - 1;
  }

  bool containsCursor(TextSelection selection) {
    if (widget.cursorCont.isFloatingCursorActive) {
      _containsCursor = widget.container.containsOffset(
        widget.cursorCont.floatingCursorTextPosition.value!.offset,
      );
    } else {
      _containsCursor = selection.isCollapsed &&
          widget.container.containsOffset(
            selection.baseOffset,
          );
    }
    return _containsCursor;
  }

  // Get the local position of the caret
  TextPosition _getLocalPositionOfCaret(TextSelection selection) {
    return widget.cursorCont.isFloatingCursorActive
        ? TextPosition(
            offset: widget.cursorCont.floatingCursorTextPosition.value!.offset -
                widget.container.documentOffset,
            affinity:
                widget.cursorCont.floatingCursorTextPosition.value!.affinity,
          )
        : TextPosition(
            offset: selection.extentOffset - widget.container.documentOffset,
            affinity: selection.base.affinity,
          );
  }

  @override
  Widget build(BuildContext context) {
    const sizedBox = SizedBox.shrink();
    return ValueListenableBuilder(
      key: ValueKey(widget.container.key.toString()),
      valueListenable: widget.selection,
      builder: (ctx, value, child) {
        if (!_containsTextSelection(value)) {
          return sizedBox;
        }
        _updateSelectionRectsIfNeeded();
        if (isEmbed) {
          if (prevBlockRect == null) {
            return sizedBox;
          }
          return Positioned.fromRect(
            rect: prevBlockRect!,
            child: Container(
              decoration: BoxDecoration(
                color: widget.cursorCont.style.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }
        if (value.isCollapsed) {
          if (prevCursorRect == null || !containsCursor(value)) {
            return sizedBox;
          }
          return ValueListenableBuilder(
            valueListenable: widget.cursorCont.show,
            builder: (ctx, showValue, child) {
              if (showValue) {
                return ValueListenableBuilder(
                    valueListenable: widget.cursorCont.blink,
                    builder: (context, blink, child) {
                      if (!blink || widget.delegate.renderBox == null)
                        return sizedBox;
                      return CustomPaint(
                        willChange: true,
                        painter: CursorPainter(
                          delegate: widget.delegate,
                          node: widget.delegate.node,
                          // embeds or blocks cannot have embeds
                          lineHasEmbed: widget.container is Line
                              ? (widget.container as Line).hasEmbed
                              : false,
                          position: _getLocalPositionOfCaret(value),
                          style: widget.cursorCont.style,
                          color: widget.cursorCont.color.value,
                          devicePixelRatio:
                              MediaQuery.devicePixelRatioOf(context),
                        ),
                      );
                    });
              }
              return child!;
            },
            child: sizedBox,
          );
        }
        if (prevSelectionRects == null ||
            (prevSelectionRects?.isEmpty ?? false)) {
          return sizedBox;
        }
        return SelectionAreaPaint(
          rects: prevSelectionRects ?? [],
          selectionColor: Colors.blue.withAlpha(
            (255.0 * 0.50).round(),
          ),
        );
      },
    );
  }

  void _updateSelectionRectsIfNeeded([TextSelection? current]) {
    final selection = current ?? widget.selection.value;
    // avoid rebuiling since CursorCont is updated always internally
    // by the timer
    if (oldNodeV != widget.delegate.node) {
      oldNodeV = widget.delegate.node;
      prevBlockRect = null;
      prevCursorRect = null;
      prevSelectionRects = null;
    }
    void changeSelection() {
      if (!widget.hasFocus) {
        prevCursorRect = null;
        prevSelectionRects = null;
        prevBlockRect = null;
        return;
      }
      if (isEmbed) {
        // set to nullable all values to avoid any unexpected rect
        if (!widget.container.containsOffset(selection.baseOffset)) {
          if (prevBlockRect != null) {
            prevBlockRect = null;
            prevCursorRect = null;
            prevSelectionRects = null;
          }
        } else {
          final rect = widget.delegate.getBoxesForSelection(selection).firstOrNull?.toRect();
          if (prevBlockRect != rect) {
            prevBlockRect = rect;
            prevCursorRect = null;
            prevSelectionRects = null;
          }
        }
      } else if (selection.isCollapsed) {
        prevSelectionRects = null;
        prevBlockRect = null;
        if (!widget.hasFocus) {
          return;
        }
        final box = widget.delegate
            .getLocalRectForCaret(TextPosition(offset: selection.baseOffset));
        if (box != prevCursorRect || prevCursorRect == null) {
          prevCursorRect = box;
        }
      } else {
        prevCursorRect = null;
        prevBlockRect = null;
        // check if the current selected part, is not exactly local
        //
        // Text [part --------|
        // that are being ----| We are looking, if the selection, looks like this
        // selected] In ------|
        // this example
        final localNodeoffset = widget.container.offset;
        // the offset of the node but adding the children node len
        final realOffsetOfNode =
            widget.container.documentOffset + widget.container.length - 1;
        // the offset of the node without add the children node len
        final partialGlobalOffset = widget.container.documentOffset;
        final isOutOfNodeRange =
            (selection.start >= 0 && selection.start < realOffsetOfNode) &&
                (selection.end <= realOffsetOfNode);
        if (!isOutOfNodeRange &&
            (partialGlobalOffset <= selection.end &&
                selection.start <= realOffsetOfNode)) {
          final local = localSelection(widget.container, selection, true);
          prevSelectionRects = widget.delegate
              .getBoxesForSelection(
                local,
              )
              .map((e) => e.toRect())
              .toList();
          // check if the current selected part is not exactly local
          // but also is selecting empty nodes
          //
          // Text [part --------|
          //  ------------------| We are looking, if the selection, looks like this
          //  ------------------|
          // selected] In ------|
          // this example
          if (widget.container.isEmpty &&
              selection.baseOffset <= localNodeoffset &&
              selection.extentOffset > localNodeoffset) {
            // Paint a small rect at the start of empty lines that
            // are contained by the selection.
            final lineHeight = widget.delegate.preferredLineHeightByPosition(
              TextPosition(
                offset: widget.container.offset,
              ),
            );
            prevSelectionRects?.add(TextBox.fromLTRBD(
              0,
              0,
              3,
              lineHeight,
              Directionality.of(context),
            ).toRect());
          }
        } else {
          final rects = widget.delegate
              .getBoxesForSelection(selection)
              .map(
                (e) => e.toRect(),
              )
              .toList();
          if (prevSelectionRects == null ||
              !listEquals(rects, prevSelectionRects)) {
            prevSelectionRects = rects;
          }
        }
      }
    }

    if (mounted) {
      setState(changeSelection);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        changeSelection();
      });
    }
  }

  bool get isEmbed =>
      widget.delegate.node is Embed ||
      widget.delegate.node.children.length == 1 &&
          (widget.delegate.node is Block
              ? false
              : (widget.delegate.node as Line).hasEmbed);
}
