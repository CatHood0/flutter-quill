import 'package:flutter/material.dart';

import '../../../../flutter_quill.dart';
import '../../../common/utils/font.dart';
import '../../../document/nodes/container.dart';
import '../../../editor_toolbar_shared/color.dart';
import '../../widgets/default_leading_components/leading_components.dart';
import '../component_context.dart';
import '../component_node_builder.dart';
import '../component_node_widget.dart';
import '../component_widget_builder.dart';

class BlockquoteComponent extends QuillComponentBuilder {
  @override
  bool validate(QuillContainer<Node?> node) =>
      node.style.attributes.containsKey(Attribute.blockQuote.key);

  @override
  QuillComponentWidget build(QuillComponentContext componentContext) {
    return BlockquoteComponentWidget(
      node: componentContext.node,
      componentContext: componentContext,
    );
  }
}

class BlockquoteComponentWidget extends QuillComponentStatefulWidget {
  const BlockquoteComponentWidget({
    required this.componentContext,
    required super.node,
    super.key,
  });

  final QuillComponentContext componentContext;

  @override
  State<BlockquoteComponentWidget> createState() => _BlockquoteComponentState();
}

class _BlockquoteComponentState extends State<BlockquoteComponentWidget> {
  QuillContainer<Node?> get node => widget.node;

  @override
  Widget build(BuildContext context) {
    final textDirection = calculateDirectionality();
    final numberPointWidthBuilder = widget.componentContext.extra.defaultStyles
            .lists?.numberPointWidthBuilder ??
        TextBlockUtils.defaultNumberPointWidthBuilder;
    final indentWidthBuilder =
        widget.componentContext.extra.defaultStyles.lists?.indentWidthBuilder ??
            TextBlockUtils.defaultIndentWidthBuilder;
    final child = Directionality(
      textDirection: textDirection,
      child: Container(
        width: double.infinity,
        alignment: align,
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.node.childCount,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final line = node.children.elementAt(index) as Line;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              textDirection: textDirection,
              children: [
                _buildLeading(
                  context: context,
                  line: line,
                  index: index,
                  indentLevelCounts: widget.componentContext.indentLevelCounts,
                  count: widget.node.childCount,
                )!,
                Flexible(
                  child: QuillRichText(
                    key: widget.node.key,
                    node: line,
                    embedBuilder: widget
                        .componentContext.extra.editorConfigs.embedBuilder,
                    styles: widget.componentContext.extra.defaultStyles,
                    readOnly: widget.componentContext.extra.controller.readOnly,
                    controller: widget.componentContext.extra.controller,
                    onLaunchUrl: widget.componentContext.extra.onLaunchUrl,
                    linkActionPicker:
                        widget.componentContext.extra.linkActionPicker,
                    composingRange:
                        widget.componentContext.extra.composingRange,
                    cursorCont: widget.componentContext.extra.cursorCont,
                    hasFocus: widget.componentContext.extra.isFocusedEditor,
                    textDirection: textDirection,
                    horizontalSpacing:
                        widget.componentContext.extra.horizontalSpacing +
                            indentWidthBuilder(
                              widget.node as Block,
                              context,
                              index,
                              numberPointWidthBuilder,
                            ),
                    verticalSpacing:
                        widget.componentContext.extra.verticalSpacing +
                            _getSpacingForLine(
                              line,
                              index,
                              node.childCount,
                            ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    // if has padding add it
    return Container(
      decoration: getDecorationForBlock(
        widget.node as Block,
        widget.componentContext.extra.defaultStyles,
      ),
      child: Padding(
        padding: padding(),
        child: child,
      ),
    );
  }

  Widget? _buildLeading({
    required BuildContext context,
    required Line line,
    required int index,
    required Map<int, int> indentLevelCounts,
    required int count,
  }) {
    final defaultStyles = QuillStyles.getStyles(context, true) ??
        DefaultStyles.getInstance(context);
    final fontSize = defaultStyles.paragraph?.style.fontSize ?? 16;
    final attrs = line.style.attributes;
    final numberPointWidthBuilder =
        defaultStyles.lists?.numberPointWidthBuilder ??
            TextBlockUtils.defaultNumberPointWidthBuilder;

    // Of the color button
    final fontColor =
        line.toDelta().operations.first.attributes?[Attribute.color.key] != null
            ? hexToColor(
                line
                    .toDelta()
                    .operations
                    .first
                    .attributes?[Attribute.color.key],
              )
            : null;

    // Of the size button
    final size =
        line.toDelta().operations.first.attributes?[Attribute.size.key] != null
            ? getFontSizeAsDouble(
                line.toDelta().operations.first.attributes?[Attribute.size.key],
                defaultStyles: defaultStyles,
              )
            : null;

    // Of the alignment buttons
    // final textAlign = line.style.attributes[Attribute.align.key]?.value != null
    //     ? getTextAlign(line.style.attributes[Attribute.align.key]?.value)
    //     : null;
    final attribute =
        attrs[Attribute.list.key] ?? attrs[Attribute.codeBlock.key];
    final isUnordered = attribute == Attribute.ul;
    final isOrdered = attribute == Attribute.ol;
    final isCheck =
        attribute == Attribute.checked || attribute == Attribute.unchecked;
    final isCodeBlock = attrs.containsKey(Attribute.codeBlock.key);
    if (attribute == null) return null;
    final leadingConfig = LeadingConfig(
      attribute: attribute,
      attrs: attrs,
      indentLevelCounts: indentLevelCounts,
      index: isOrdered || isCodeBlock ? index : null,
      count: count,
      //enabled: !isCheck ? null : !(widget.config.checkBoxReadOnly ?? controller.readOnly),
      enabled: null,
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
      onCheckboxTap: !isCheck
          ? (value) {}
          : (value) => widget.componentContext.extra.onTapCheckBoxFun
              ?.call(line.documentOffset, value),
    );
    if (widget.componentContext.extra.editorConfigs.customLeadingBuilder !=
        null) {
      final leadingBlockNodeBuilder = widget
          .componentContext.extra.editorConfigs.customLeadingBuilder
          ?.call(
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
  ) {
    var top = 0.0, bottom = 0.0;
    final styles = widget.componentContext.extra.defaultStyles;

    final attrs = node.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      final level = attrs[Attribute.header.key]!.value;
      switch (level) {
        case 1:
          top = styles.h1!.verticalSpacing.top;
          bottom = styles.h1!.verticalSpacing.bottom;
          break;
        case 2:
          top = styles.h2!.verticalSpacing.top;
          bottom = styles.h2!.verticalSpacing.bottom;
          break;
        case 3:
          top = styles.h3!.verticalSpacing.top;
          bottom = styles.h3!.verticalSpacing.bottom;
          break;
        case 4:
          top = styles.h4!.verticalSpacing.top;
          bottom = styles.h4!.verticalSpacing.bottom;
          break;
        case 5:
          top = styles.h5!.verticalSpacing.top;
          bottom = styles.h5!.verticalSpacing.bottom;
          break;
        case 6:
          top = styles.h6!.verticalSpacing.top;
          bottom = styles.h6!.verticalSpacing.bottom;
          break;
        default:
          throw ArgumentError('Invalid level $level');
      }
    } else {
      final VerticalSpacing lineSpacing;
      if (attrs.containsKey(Attribute.blockQuote.key)) {
        lineSpacing = styles.quote!.lineSpacing;
      } else if (attrs.containsKey(Attribute.indent.key)) {
        lineSpacing = styles.indent!.lineSpacing;
      } else if (attrs.containsKey(Attribute.list.key)) {
        lineSpacing = styles.lists!.lineSpacing;
      } else if (attrs.containsKey(Attribute.codeBlock.key)) {
        lineSpacing = styles.code!.lineSpacing;
      } else if (attrs.containsKey(Attribute.align.key)) {
        lineSpacing = styles.align!.lineSpacing;
      } else {
        // use paragraph linespacing as a default
        lineSpacing = styles.paragraph!.lineSpacing;
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

  BoxDecoration? getDecorationForBlock(
      Block node, DefaultStyles? defaultStyles) {
    // Verify if the direction is RTL and avoid passing the decoration
    // to the left when need to be on right side
    if (calculateDirectionality() == TextDirection.rtl) {
      return defaultStyles!.quote!.decoration?.copyWith(
        border: Border(
          right: BorderSide(width: 4, color: Colors.grey.shade300),
        ),
      );
    }
    return defaultStyles!.quote!.decoration;
  }

  EdgeInsets padding() => EdgeInsets.only(
        left: widget.componentContext.extra.horizontalSpacing.left,
        right: widget.componentContext.extra.horizontalSpacing.right,
        top: widget.componentContext.extra.verticalSpacing.top,
        bottom: widget.componentContext.extra.verticalSpacing.bottom,
      );

  TextDirection get directionality => Directionality.of(context);

  TextDirection calculateDirectionality() {
    if (node.style.attributes[Attribute.direction.key] == null) {
      return directionality;
    }
    return TextDirection.rtl;
  }

  Alignment? get align {
    if (node.style.attributes[Attribute.align.key] == null) {
      return null;
    }
    final align = node.style.attributes[Attribute.align.key] as String;
    switch (align) {
      case 'right':
        return Alignment.centerRight;
      case 'center':
        return Alignment.center;
      default:
        return Alignment.centerLeft;
    }
  }
}
