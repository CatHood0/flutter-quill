import 'package:flutter/material.dart';

import '../../../../flutter_quill.dart';
import '../../../document/nodes/container.dart';
import '../component_context.dart';
import '../component_node_builder.dart';
import '../component_node_widget.dart';
import '../component_widget_builder.dart';

class ParagraphComponent extends QuillComponentBuilder {
  @override
  bool validate(Node node) =>
      node is Line && !node.style.attributes.containsKey(Attribute.header.key);

  @override
  QuillComponentWidget build(QuillComponentContext componentContext) {
    return ParagraphComponentWidget(
      node: componentContext.node as Line,
      componentContext: componentContext,
    );
  }
}

class ParagraphComponentWidget extends QuillComponentStatefulWidget {
  const ParagraphComponentWidget({
    required this.componentContext,
    required super.node,
    super.key,
  });
  final QuillComponentContext componentContext;

  @override
  State<ParagraphComponentWidget> createState() => _ParagraphComponentState();
}

class _ParagraphComponentState extends State<ParagraphComponentWidget> {
  QuillContainer<Node?> get node => widget.node;

  @override
  Widget build(BuildContext context) {
    final textDirection = calculateDirectionality();
    return Container(
      width: double.infinity,
      alignment: align,
      child: Padding(
        padding: padding(),
        child: QuillRichText(
          key: widget.node.key,
          node: node as Line,
          embedBuilder:
              widget.componentContext.extra.editorConfigs.embedBuilder,
          styles: widget.componentContext.extra.defaultStyles,
          readOnly: widget.componentContext.extra.controller.readOnly,
          controller: widget.componentContext.extra.controller,
          onLaunchUrl: widget.componentContext.extra.onLaunchUrl,
          linkActionPicker: widget.componentContext.extra.linkActionPicker,
          composingRange: widget.componentContext.extra.composingRange,
          cursorCont: widget.componentContext.extra.cursorCont,
          hasFocus: widget.componentContext.extra.isFocusedEditor,
          textDirection: textDirection,
          horizontalSpacing: widget.componentContext.extra.horizontalSpacing,
          verticalSpacing: widget.componentContext.extra.verticalSpacing,
        ),
      ),
    );
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
