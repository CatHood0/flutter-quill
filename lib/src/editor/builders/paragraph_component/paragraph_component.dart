import 'package:flutter/material.dart';

import '../../../../flutter_quill.dart';
import '../../../document/nodes/container.dart';
import '../../selection/default_inline_selection_implementation.dart';
import '../../selection/selectable_mixin.dart';
import '../../selection/widgets/selectable_node_widget.dart';
import '../component_context.dart';
import '../component_node_builder.dart';
import '../component_node_widget.dart';
import '../component_widget_builder.dart';

class ParagraphComponent extends QuillComponentBuilder {
  @override
  bool validate(QuillContainer<Node?> node) =>
      (node is! Embed ||
          node.style.attributes.containsKey('placeholder') ||
          node.children.any((child) => child is Embed) ||
          (node is Line ||
              node is Block &&
                  node.style.attributes.containsKey(Attribute.align.key))) &&
      !node.style.attributes.containsKey(Attribute.header.key);

  @override
  QuillComponentWidget build(QuillComponentContext componentContext) {
    return ParagraphComponentWidget(
      node: componentContext.node,
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

class _ParagraphComponentState extends State<ParagraphComponentWidget>
    with
        SelectableMixin<ParagraphComponentWidget>,
        DefaultSelectableMixin<ParagraphComponentWidget> {
  @override
  QuillContainer<Node?> get node => widget.node;

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  // Should be used when a component will be wrapped by a padding (it modifies the offset)
  @override
  GlobalKey<State<StatefulWidget>> get componentKey => GlobalKey();

  // Note:
  // As you can see, we creates a forwardKey that will be passed as the key of QuillRichText
  // making this, we can ref directly the implementation into QuillRichText and use the methods
  // without accesing to it
  @override
  GlobalKey<State<StatefulWidget>> get forwardKey => GlobalKey();

  @override
  Widget build(BuildContext context) {
    final textDirection = calculateDirectionality();
    final Widget child = Container(
      width: double.infinity,
      alignment: align,
      child: Padding(
        key: componentKey,
        padding: padding(),
        child: QuillRichText(
          key: widget.node.key,
          node: widget.node,
          delegate: this,
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

    return SelectableNodeWidget(
      selection: widget.componentContext.extra.controller.listenableSelection,
      delegate: this,
      container: node,
      cursorCont: widget.componentContext.extra.cursorCont,
      hasFocus: widget.componentContext.extra.isFocusedEditor,
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
