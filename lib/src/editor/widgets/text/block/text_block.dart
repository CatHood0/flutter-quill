import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../../flutter_quill.dart';
import '../../../../common/utils/font.dart';
import '../../../../delta/delta_diff.dart';
import '../../../../document/nodes/container.dart';
import '../../../../editor_toolbar_shared/color.dart';
import '../../../selection/selectable_mixin.dart';
import '../../../selection/widgets/selectable_node_widget.dart';
import '../../box.dart';
import '../../default_leading_components/leading_components.dart';
import '../../delegate.dart';
import '../inline/text_line.dart';
import '../text_selection.dart';

const List<int> arabianRomanNumbers = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];

const List<String> romanNumbers = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];

class TextBlock extends StatefulWidget {
  const TextBlock({
    required this.block,
    required this.controller,
    required this.textDirection,
    required this.scrollBottomInset,
    required this.horizontalSpacing,
    required this.verticalSpacing,
    required this.textSelection,
    required this.color,
    required this.styles,
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.contentPadding,
    required this.embedBuilder,
    required this.linkActionPicker,
    required this.cursorCont,
    required this.indentLevelCounts,
    required this.clearIndents,
    required this.onCheckboxTap,
    required this.readOnly,
    required this.customRecognizerBuilder,
    required this.composingRange,
    this.checkBoxReadOnly,
    this.onLaunchUrl,
    this.customStyleBuilder,
    this.customLinkPrefixes = const <String>[],
    this.customLeadingBlockBuilder,
    super.key,
  });

  final Block block;
  final QuillController controller;
  final TextDirection textDirection;
  final double scrollBottomInset;
  final HorizontalSpacing horizontalSpacing;
  final VerticalSpacing verticalSpacing;
  final TextSelection textSelection;
  final Color color;
  final DefaultStyles? styles;
  final LeadingBlockNodeBuilder? customLeadingBlockBuilder;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final EdgeInsets? contentPadding;
  final EmbedsBuilder embedBuilder;
  final LinkActionPicker linkActionPicker;
  final ValueChanged<String>? onLaunchUrl;
  final CustomRecognizerBuilder? customRecognizerBuilder;
  final CustomStyleBuilder? customStyleBuilder;
  final CursorCont cursorCont;
  final Map<int, int> indentLevelCounts;
  final bool clearIndents;
  final Function(int, bool) onCheckboxTap;
  final bool readOnly;
  final bool? checkBoxReadOnly;
  final List<String> customLinkPrefixes;
  final TextRange composingRange;

  @override
  State<TextBlock> createState() => _EditableTextBlockState();
}

class _EditableTextBlockState extends State<TextBlock> with SelectableMixin<TextBlock> {
  List<Widget> _children = [];

  @override
  void initState() {
    computeCaretPrototype();
    ensureToGenerateChildren();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.hashCode != oldWidget.block.hashCode) {
      ensureToGenerateChildren();
    }
  }

  void ensureToGenerateChildren() {
    _children = _buildChildren(
      context,
      widget.indentLevelCounts,
      widget.clearIndents,
    );
  }

  EdgeInsets _padding() => EdgeInsets.only(
        left: widget.horizontalSpacing.left,
        right: widget.horizontalSpacing.right,
        top: widget.verticalSpacing.top,
        bottom: widget.verticalSpacing.bottom,
      );

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final defaultStyles = QuillStyles.getStyles(context, false);
    final child = Padding(
      padding: widget.contentPadding ?? EdgeInsets.zero,
      child: Container(
        padding: _padding(),
        decoration: _getDecorationForBlock(widget.block, defaultStyles) ?? const BoxDecoration(),
        child: Column(
          textDirection: widget.textDirection,
          mainAxisSize: MainAxisSize.min,
          children: _children,
        ),
      ),
    );
    return SelectableNodeWidget(
      key: ValueKey(widget.block.hashCode),
      delegate: this,
      selection: widget.controller.listenableSelection,
      container: widget.block,
      cursorCont: widget.cursorCont,
      hasFocus: widget.hasFocus,
      child: child,
    );
  }

  BoxDecoration? _getDecorationForBlock(Block node, DefaultStyles? defaultStyles) {
    final attrs = widget.block.style.attributes;
    if (attrs.containsKey(Attribute.blockQuote.key)) {
      // Verify if the direction is RTL and avoid passing the decoration
      // to the left when need to be on right side
      if (widget.textDirection == TextDirection.rtl) {
        return defaultStyles!.quote!.decoration?.copyWith(
          border: Border(
            right: BorderSide(width: 4, color: Colors.grey.shade300),
          ),
        );
      }
      return defaultStyles!.quote!.decoration;
    }
    if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.decoration;
    }
    return null;
  }

  List<Widget> _buildChildren(BuildContext context, Map<int, int> indentLevelCounts, bool clearIndents) {
    final defaultStyles = QuillStyles.getStyles(context, false);
    final numberPointWidthBuilder =
        defaultStyles?.lists?.numberPointWidthBuilder ?? TextBlockUtils.defaultNumberPointWidthBuilder;
    final indentWidthBuilder =
        defaultStyles?.lists?.indentWidthBuilder ?? TextBlockUtils.defaultIndentWidthBuilder;

    final count = widget.block.children.length;
    final children = <Widget>[];
    if (clearIndents) {
      indentLevelCounts.clear();
    }
    var index = 0;
    for (final line in Iterable.castFrom<dynamic, Line>(widget.block.children)) {
      index++;
      final textLine = TextLine(
        line: line,
        textDirection: widget.textDirection,
        leading: _buildLeading(
          context: context,
          line: line,
          index: index,
          indentLevelCounts: indentLevelCounts,
          count: count,
        ),
        embedBuilder: widget.embedBuilder,
        customStyleBuilder: widget.customStyleBuilder,
        cursorCont: widget.cursorCont,
        hasFocus: widget.hasFocus,
        horizontalSpacing: indentWidthBuilder(widget.block, context, count, numberPointWidthBuilder),
        verticalSpacing: _getSpacingForLine(line, index, count, defaultStyles),
        styles: widget.styles!,
        readOnly: widget.readOnly,
        controller: widget.controller,
        linkActionPicker: widget.linkActionPicker,
        onLaunchUrl: widget.onLaunchUrl,
        customLinkPrefixes: widget.customLinkPrefixes,
        customRecognizerBuilder: widget.customRecognizerBuilder,
        composingRange: widget.composingRange,
      );
      final nodeTextDirection = getDirectionOfNode(line, widget.textDirection);
      children.add(
        Directionality(
          textDirection: nodeTextDirection,
          child: textLine,
        ),
      );
    }
    return children.toList(growable: false);
  }

  Widget? _buildLeading({
    required BuildContext context,
    required Line line,
    required int index,
    required Map<int, int> indentLevelCounts,
    required int count,
  }) {
    final defaultStyles = QuillStyles.getStyles(context, false)!;
    final fontSize = defaultStyles.paragraph?.style.fontSize ?? 16;
    final attrs = line.style.attributes;
    final numberPointWidthBuilder =
        defaultStyles.lists?.numberPointWidthBuilder ?? TextBlockUtils.defaultNumberPointWidthBuilder;

    // Of the color button
    final fontColor = line.toDelta().operations.first.attributes?[Attribute.color.key] != null
        ? hexToColor(
            line.toDelta().operations.first.attributes?[Attribute.color.key],
          )
        : null;

    // Of the size button
    final size = line.toDelta().operations.first.attributes?[Attribute.size.key] != null
        ? getFontSizeAsDouble(
            line.toDelta().operations.first.attributes?[Attribute.size.key],
            defaultStyles: defaultStyles,
          )
        : null;

    // Of the alignment buttons
    // final textAlign = line.style.attributes[Attribute.align.key]?.value != null
    //     ? getTextAlign(line.style.attributes[Attribute.align.key]?.value)
    //     : null;
    final attribute = attrs[Attribute.list.key] ?? attrs[Attribute.codeBlock.key];
    final isUnordered = attribute == Attribute.ul;
    final isOrdered = attribute == Attribute.ol;
    final isCheck = attribute == Attribute.checked || attribute == Attribute.unchecked;
    final isCodeBlock = attrs.containsKey(Attribute.codeBlock.key);
    if (attribute == null) return null;
    final leadingConfig = LeadingConfig(
      attribute: attribute,
      attrs: attrs,
      indentLevelCounts: indentLevelCounts,
      index: isOrdered || isCodeBlock ? index : null,
      count: count,
      enabled: !isCheck ? null : !(widget.checkBoxReadOnly ?? widget.readOnly),
      style: () {
        if (isOrdered) {
          return defaultStyles.leading!.style.copyWith(
            fontSize: size,
            color: fontColor,
          );
        }
        if (isUnordered) {
          return defaultStyles.leading!.style.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: size,
            color: fontColor,
          );
        }
        if (isCheck) {
          return null;
        }
        return defaultStyles.code!.style.copyWith(
          color: defaultStyles.code!.style.color!.withValues(alpha: 0.4),
        );
      }(),
      width: () {
        if (isOrdered || isCodeBlock) {
          return numberPointWidthBuilder(fontSize, count);
        }
        if (isUnordered) {
          return numberPointWidthBuilder(fontSize, 1); // same as fontSize * 2
        }
        return null;
      }(),
      padding: () {
        if (isOrdered || isUnordered) {
          return fontSize / 2;
        }
        if (isCodeBlock) {
          return fontSize;
        }
        return null;
      }(),
      lineSize: isCheck ? fontSize : null,
      uiBuilder: isCheck ? defaultStyles.lists?.checkboxUIBuilder : null,
      value: attribute == Attribute.checked,
      onCheckboxTap: !isCheck ? (value) {} : (value) => widget.onCheckboxTap(line.documentOffset, value),
    );
    if (widget.customLeadingBlockBuilder != null) {
      final leadingBlockNodeBuilder = widget.customLeadingBlockBuilder?.call(
        line,
        leadingConfig,
      );
      if (leadingBlockNodeBuilder != null) {
        return leadingBlockNodeBuilder;
      }
    }

    if (isOrdered) {
      return numberPointLeading(leadingConfig);
    }

    if (isUnordered) {
      return bulletPointLeading(leadingConfig);
    }

    if (isCheck) {
      return checkboxLeading(leadingConfig);
    }
    if (isCodeBlock) {
      return codeBlockLineNumberLeading(leadingConfig);
    }
    return null;
  }

  VerticalSpacing _getSpacingForLine(
    Line node,
    int index,
    int count,
    DefaultStyles? defaultStyles,
  ) {
    var top = 0.0, bottom = 0.0;

    final attrs = widget.block.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      final level = attrs[Attribute.header.key]!.value;
      switch (level) {
        case 1:
          top = defaultStyles!.h1!.verticalSpacing.top;
          bottom = defaultStyles.h1!.verticalSpacing.bottom;
          break;
        case 2:
          top = defaultStyles!.h2!.verticalSpacing.top;
          bottom = defaultStyles.h2!.verticalSpacing.bottom;
          break;
        case 3:
          top = defaultStyles!.h3!.verticalSpacing.top;
          bottom = defaultStyles.h3!.verticalSpacing.bottom;
          break;
        case 4:
          top = defaultStyles!.h4!.verticalSpacing.top;
          bottom = defaultStyles.h4!.verticalSpacing.bottom;
          break;
        case 5:
          top = defaultStyles!.h5!.verticalSpacing.top;
          bottom = defaultStyles.h5!.verticalSpacing.bottom;
          break;
        case 6:
          top = defaultStyles!.h6!.verticalSpacing.top;
          bottom = defaultStyles.h6!.verticalSpacing.bottom;
          break;
        default:
          throw ArgumentError('Invalid level $level');
      }
    } else {
      final VerticalSpacing lineSpacing;
      if (attrs.containsKey(Attribute.blockQuote.key)) {
        lineSpacing = defaultStyles!.quote!.lineSpacing;
      } else if (attrs.containsKey(Attribute.indent.key)) {
        lineSpacing = defaultStyles!.indent!.lineSpacing;
      } else if (attrs.containsKey(Attribute.list.key)) {
        lineSpacing = defaultStyles!.lists!.lineSpacing;
      } else if (attrs.containsKey(Attribute.codeBlock.key)) {
        lineSpacing = defaultStyles!.code!.lineSpacing;
      } else if (attrs.containsKey(Attribute.align.key)) {
        lineSpacing = defaultStyles!.align!.lineSpacing;
      } else {
        // use paragraph linespacing as a default
        lineSpacing = defaultStyles!.paragraph!.lineSpacing;
      }
      top = lineSpacing.top;
      bottom = lineSpacing.bottom;
    }

    if (index == 1) {
      top = 0.0;
    }

    if (index == count) {
      bottom = 0.0;
    }

    return VerticalSpacing(top, bottom);
  }

  RenderEditableBox? get firstChild => _children.firstOrNull as RenderEditableBox;
  RenderEditableBox? get lastChild => _children.lastOrNull as RenderEditableBox;

  /// The previous child before the given child in the child list.
  RenderEditableBox? childBefore(RenderEditableBox child) {
    final childParentData = child.parentData! as ContainerBoxParentData<RenderEditableBox>;
    return childParentData.previousSibling;
  }

  /// The next child after the given child in the child list.
  RenderEditableBox? childAfter(RenderEditableBox child) {
    final childParentData = child.parentData! as ContainerBoxParentData<RenderEditableBox>;
    return childParentData.nextSibling;
  }

  RenderEditableBox childAtPosition(TextPosition position) {
    assert(firstChild != null);
    final targetNode = container.queryChild(position.offset, false).node;

    var targetChild = firstChild;
    while (targetChild != null) {
      if (targetChild.container == targetNode) {
        break;
      }
      final newChild = childAfter(targetChild);
      if (newChild == null) {
        //  At start of document fails to find the position
        targetChild = childAtOffset(const Offset(0, 0));
        break;
      }
      targetChild = newChild;
    }
    if (targetChild == null) {
      throw 'targetChild should not be null';
    }
    return targetChild;
  }

  EdgeInsets resolvePadding() {
    var resolvedPadding = _padding();
    resolvedPadding = _padding().resolve(widget.textDirection);
    resolvedPadding = resolvedPadding.copyWith(left: resolvedPadding.left);
    assert(resolvedPadding.isNonNegative);
    return resolvedPadding;
  }

  /// Returns child of this container located at the specified local `offset`.
  ///
  /// If `offset` is above this container (offset.dy is negative) returns
  /// the first child. Likewise, if `offset` is below this container then
  /// returns the last child.
  RenderEditableBox childAtOffset(Offset offset) {
    assert(firstChild != null);
    final resolvedPadding = resolvePadding();

    if (offset.dy <= resolvedPadding.top) {
      return firstChild!;
    }
    if (offset.dy >= (context.findRenderObject() as RenderBox).size.height - resolvedPadding.bottom) {
      return lastChild!;
    }

    var child = firstChild;
    final dx = -offset.dx;
    var dy = resolvedPadding.top;
    while (child != null) {
      if (child.size.contains(offset.translate(dx, -dy))) {
        return child;
      }
      dy += child.size.height;
      child = childAfter(child);
    }

    // this case possible, when editor not scrollable,
    // but minHeight > content height and tap was under content
    return lastChild!;
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    final child = childAtPosition(position);
    final rangeInChild = child.getLineBoundary(TextPosition(
      offset: position.offset - child.container.offset,
      affinity: position.affinity,
    ));
    return TextRange(
      start: rangeInChild.start + child.container.offset,
      end: rangeInChild.end + child.container.offset,
    );
  }

  @override
  Offset getOffsetForCaretByPosition(TextPosition position) {
    final child = childAtPosition(position);
    return child.getOffsetForCaret(TextPosition(
          offset: position.offset - child.container.offset,
          affinity: position.affinity,
        )) +
        (child.parentData as BoxParentData).offset;
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    final child = childAtOffset(offset);
    final parentData = child.parentData as BoxParentData;
    final localPosition = child.getPositionForOffset(offset - parentData.offset);
    return TextPosition(
      offset: localPosition.offset + child.container.offset,
      affinity: localPosition.affinity,
    );
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    final child = childAtPosition(position);
    final nodeOffset = child.container.offset;
    final childWord = child.getWordBoundary(TextPosition(offset: position.offset - nodeOffset));
    return TextRange(
      start: childWord.start + nodeOffset,
      end: childWord.end + nodeOffset,
    );
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    assert(position.offset < container.length);

    final child = childAtPosition(position);
    final childLocalPosition = TextPosition(offset: position.offset - child.container.offset);
    final result = child.getPositionAbove(childLocalPosition);
    if (result != null) {
      return TextPosition(offset: result.offset + child.container.offset);
    }

    final sibling = childBefore(child);
    if (sibling == null) {
      return null;
    }

    final caretOffset = child.getOffsetForCaret(childLocalPosition);
    final testPosition = TextPosition(offset: sibling.container.length - 1);
    final testOffset = sibling.getOffsetForCaret(testPosition);
    final finalOffset = Offset(caretOffset.dx, testOffset.dy);
    return TextPosition(offset: sibling.container.offset + sibling.getPositionForOffset(finalOffset).offset);
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    assert(position.offset < container.length);

    final child = childAtPosition(position);
    final childLocalPosition = TextPosition(offset: position.offset - child.container.offset);
    final result = child.getPositionBelow(childLocalPosition);
    if (result != null) {
      return TextPosition(offset: result.offset + child.container.offset);
    }

    final sibling = childAfter(child);
    if (sibling == null) {
      return null;
    }

    final caretOffset = child.getOffsetForCaret(childLocalPosition);
    final testOffset = sibling.getOffsetForCaret(const TextPosition(offset: 0));
    final finalOffset = Offset(caretOffset.dx, testOffset.dy);
    return TextPosition(offset: sibling.container.offset + sibling.getPositionForOffset(finalOffset).offset);
  }

  @override
  double preferredLineHeightByPosition(TextPosition position) {
    final child = childAtPosition(position) as SelectableMixin;
    return child.preferredLineHeightByPosition(TextPosition(offset: position.offset - child.container.offset));
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      return TextSelectionPoint(
        Offset(0, preferredLineHeightByPosition(selection.extent)) + getOffsetForCaretByPosition(selection.extent),
        null,
      );
    }

    final baseNode = container
        .queryChild(
          selection.start,
          false,
        )
        .node;
    var baseChild = firstChild;
    while (baseChild != null) {
      if (baseChild.container == baseNode) {
        break;
      }
      baseChild = childAfter(baseChild);
    }
    assert(baseChild != null);

    final basePoint = baseChild!.getBaseEndpointForSelection(
      localSelection(
        baseChild.container,
        selection,
        true,
      ),
    );
    return TextSelectionPoint(
      basePoint.point + ((baseChild as RenderObject).parentData as BoxParentData).offset,
      basePoint.direction,
    );
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      return TextSelectionPoint(
        Offset(0, preferredLineHeightByPosition(selection.extent)) + getOffsetForCaretByPosition(selection.extent),
        null,
      );
    }

    final extentNode = container.queryChild(selection.end, false).node;

    var extentChild = firstChild;
    while (extentChild != null) {
      if (extentChild.container == extentNode) {
        break;
      }
      extentChild = childAfter(extentChild);
    }
    assert(extentChild != null);

    final extentPoint = extentChild!.getExtentEndpointForSelection(
      localSelection(
        extentChild.container,
        selection,
        true,
      ),
    );
    return TextSelectionPoint(
      extentPoint.point + (extentChild.parentData as BoxParentData).offset,
      extentPoint.direction,
    );
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    // i think that this can throw a error
    final child = childAtPosition(position);
    final localPosition = TextPosition(
      offset: position.offset - child.container.offset,
      affinity: position.affinity,
    );
    final parentData = child.parentData as BoxParentData;
    return child.getLocalRectForCaret(localPosition).shift(parentData.offset);
  }

  @override
  TextPosition globalToLocalPosition(TextPosition position) {
    assert(container.containsOffset(position.offset) || container.length == 0,
        'The provided text position is not in the current node');
    return TextPosition(
      offset: position.offset - container.documentOffset,
      affinity: position.affinity,
    );
  }

  @override
  Rect getCaretPrototype(TextPosition position) {
    final child = childAtPosition(position);
    final localPosition = TextPosition(
      offset: position.offset - child.container.offset,
      affinity: position.affinity,
    );
    return child.getCaretPrototype(localPosition);
  }

  @override
  QuillContainer<Node?> get container => widget.block;

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => GlobalKey();

  @override
  SelectableMixin<StatefulWidget> get forward => this;

  @override
  GlobalKey<State<StatefulWidget>> get forwardKey => GlobalKey();

  // blocks does not need to implement this part
  @override
  List<TextBox> getBoxesForSelection(TextSelection textSelection) => [];

  // blocks does not need to implement this part
  @override
  double? getFullHeightForCaret(TextPosition position) => null;

  @override
  double get preferredLineHeight => 0;

  @override
  TextDirection textDirection() => widget.textDirection;

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    final child = childAtPosition(position);
    final childPosition = child.globalToLocalPosition(position);
    final boxParentData = (child as RenderBox).parentData as BoxParentData;
    final localOffsetForCaret = child.getOffsetForCaret(childPosition);
    return boxParentData.offset + localOffsetForCaret;
  }

  @override
  CursorCont get cursorCont => widget.cursorCont;
}
