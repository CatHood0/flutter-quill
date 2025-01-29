import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../flutter_quill.dart';
import '../../../document/nodes/container.dart';
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
  State<SelectionAreaForNodeWidget> createState() => _SelectionAreaForNodeWidgetState();
}

class _SelectionAreaForNodeWidgetState extends State<SelectionAreaForNodeWidget> {
  // keep the previous cursor rect to avoid unnecessary rebuild
  Rect? prevCursorRect;
  // keep the previous selection rects to avoid unnecessary rebuild
  List<Rect>? prevSelectionRects;

  Rect? prevBlockRect;

  @override
  void initState() {
    widget.delegate.computeCaretPrototype();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => updateSelectionRectsIfNeeded(),
    );
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cachedOffset = null;
      getEffectiveOffset();
      updateSelectionRectsIfNeeded();
    });
  }

  bool _containsCursor = false;

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

  TextPosition _getPosition(TextSelection selection) {
    return widget.cursorCont.isFloatingCursorActive
        ? TextPosition(
            offset: widget.cursorCont.floatingCursorTextPosition.value!.offset - widget.container.documentOffset,
            affinity: widget.cursorCont.floatingCursorTextPosition.value!.affinity,
          )
        : TextPosition(
            offset: selection.extentOffset - widget.container.documentOffset,
            affinity: selection.base.affinity,
          );
  }

  // get the offset of this area
  Offset localToGlobalOffset() {
    if (context.mounted) {
      return widget.delegate.renderBox!.localToGlobal(Offset.zero);
    }
    return const Offset(0, 0);
  }

  Offset? _cachedOffset;

  Offset getEffectiveOffset() {
    _cachedOffset = localToGlobalOffset() + (widget.delegate.renderBox!.parentData as BoxParentData).offset;
    return _cachedOffset!;
  }

  void updateSelectionRectsIfNeeded([TextSelection? current]) {
    setState(() {
      if (!widget.hasFocus) {
        prevCursorRect = null;
        prevSelectionRects = null;
        prevBlockRect = null;
        return;
      }
      if (isEmbed) {
        // set to nullable all values to avoid any unexpected rect
        if (!widget.container.containsOffset((current ?? widget.selection.value).baseOffset)) {
          if (prevBlockRect != null) {
            setState(() {
              prevBlockRect = null;
              prevCursorRect = null;
              prevSelectionRects = null;
            });
          }
        } else {
          final rect = widget.delegate.getBlockRect();
          if (prevBlockRect != rect) {
            setState(() {
              prevBlockRect = rect;
              prevCursorRect = null;
              prevSelectionRects = null;
            });
          }
        }
      } else if ((current ?? widget.selection.value).isCollapsed) {
        prevSelectionRects = null;
        prevBlockRect = null;
        final box = widget.delegate.getLocalRectForCaret(TextPosition(
            offset: (current ?? widget.selection.value).baseOffset + widget.container.documentOffset));
        final rect = Rect.fromLTRB(
          box.left,
          box.top,
          box.right,
          box.bottom,
        );
        if (rect != prevCursorRect || prevCursorRect == null) {
          prevCursorRect = rect;
        }
      } else {
        prevCursorRect = null;
        prevBlockRect = null;
        final rects = widget.delegate
            .getBoxesForSelection(current ?? widget.selection.value)
            .map(
              (e) => Rect.fromLTRB(e.left, e.top, e.right, e.bottom),
            )
            .toList();
        if (!listEquals(rects, prevSelectionRects)) {
          prevSelectionRects = rects;
        }
      }
    });
  }

  bool get isEmbed =>
      widget.delegate.container is Embed ||
      widget.delegate.container.children.length == 1 &&
          ((widget.delegate.container.first as QuillText?)?.parent?.hasEmbed ?? false);

  @override
  Widget build(BuildContext context) {
    const sizedBox = SizedBox.shrink();
    return ValueListenableBuilder(
        key: ValueKey(widget.container.key.toString()),
        valueListenable: widget.selection,
        builder: (ctx, value, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            updateSelectionRectsIfNeeded();
          });
          if (isEmbed) {
            if (!widget.hasFocus && !widget.cursorCont.show.value || !containsCursor(value)) {
              return sizedBox;
            }
            final isIntoRangeOfNode = widget.container.containsOffset(
              value.baseOffset,
            );
            if (!isIntoRangeOfNode || prevBlockRect == null) {
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
            if (prevCursorRect == null) return sizedBox;
            return ValueListenableBuilder(
              valueListenable: widget.cursorCont.show,
              builder: (ctx, showValue, child) {
                if (showValue) {
                  return CustomPaint(
                    willChange: true,
                    painter: CursorPainter(
                      delegate: widget.delegate,
                      offset: _cachedOffset ?? getEffectiveOffset(),
                      // embeds or blocks cannot have embeds
                      lineHasEmbed: widget.container is Line ? (widget.container as Line).hasEmbed : false,
                      position: _getPosition(value),
                      style: widget.cursorCont.style,
                      color: widget.cursorCont.color.value,
                      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                    ),
                  );
                }
                return child!;
              },
              child: sizedBox,
            );
          }
          if (prevSelectionRects == null || (prevSelectionRects?.isEmpty ?? false)) {
            return sizedBox;
          }
          return SelectionAreaPaint(
            rects: prevSelectionRects ?? [],
            selectionColor: Colors.blue.withAlpha(
              (255.0 * 0.50).round(),
            ),
          );
        });
  }
}
