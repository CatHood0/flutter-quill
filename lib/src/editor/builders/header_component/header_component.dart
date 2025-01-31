import 'package:flutter/material.dart';

import '../../../../flutter_quill.dart';
import '../../../document/nodes/container.dart';
import '../component_context.dart';
import '../component_node_builder.dart';
import '../component_node_widget.dart';
import '../component_widget_builder.dart';

class HeaderComponent extends QuillComponentBuilder {
  @override
  bool validate(QuillContainer<Node?> node) =>
      node.style.attributes.containsKey(Attribute.header.key);

  @override
  QuillComponentWidget build(QuillComponentContext componentContext) {
    return HeaderComponentWidget(
      node: componentContext.node,
      componentContext: componentContext,
    );
  }
}

class HeaderComponentWidget extends QuillComponentStatefulWidget {
  const HeaderComponentWidget({
    required this.componentContext,
    required super.node,
    super.key,
  });
  final QuillComponentContext componentContext;

  @override
  State<HeaderComponentWidget> createState() => _HeaderComponentState();
}

class _HeaderComponentState extends State<HeaderComponentWidget> {
  QuillContainer<Node?> get node => widget.node;

  @override
  Widget build(BuildContext context) {
    final textDirection = calculateDirectionality();
    final child = Container(
      width: double.infinity,
      alignment: align,
      child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: node.childCount,
          itemBuilder: (context, index) {
            final line = node.children.elementAt(index) as Line;
            return QuillRichText(
              key: widget.node.key,
              node: line,
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
              horizontalSpacing:
                  widget.componentContext.extra.horizontalSpacing,
              verticalSpacing: widget.componentContext.extra.verticalSpacing,
            );
          }),
    );

    return Padding(
      padding: padding(),
      child: child,
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
