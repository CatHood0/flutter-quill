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

class BlockquoteComponent extends QuillComponentBuilder {
  @override
  bool validate(QuillContainer<Node?> node) =>
      node.style.attributes.containsKey(Attribute.blockQuote.key);

  @override
  QuillComponentWidget build(QuillComponentContext componentContext) {
    return BlockquoteComponentWidget(
      key: componentContext.node.key,
      node: componentContext.node,
      componentContext: componentContext,
    );
  }
}

class BlockquoteComponentWidget extends QuillComponentStatefulWidget {
  const BlockquoteComponentWidget({
    required this.componentContext,
    required super.node,
    required super.key,
  });

  final QuillComponentContext componentContext;

  @override
  State<BlockquoteComponentWidget> createState() => _BlockquoteComponentState();
}

class _BlockquoteComponentState extends State<BlockquoteComponentWidget>
    with
        SelectableMixin<BlockquoteComponentWidget>,
        DefaultSelectableMixin<BlockquoteComponentWidget> {
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
    Widget child = Directionality(
      textDirection: textDirection,
      child: Container(
        width: double.infinity,
        alignment: align,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            textDirection: textDirection,
            children: [
              // lacks icon builder
              if (widget.componentContext.extra.leading != null)
                widget.componentContext.extra.leading!,
              Flexible(
                child: QuillRichText(
                  key: forwardKey,
                  node: widget.node,
                  delegate: this,
                  embedBuilder:
                      widget.componentContext.extra.editorConfigs.embedBuilder,
                  styles: widget.componentContext.extra.defaultStyles,
                  readOnly: widget.componentContext.extra.controller.readOnly,
                  controller: widget.componentContext.extra.controller,
                  onLaunchUrl: widget.componentContext.extra.onLaunchUrl,
                  linkActionPicker:
                      widget.componentContext.extra.linkActionPicker,
                  composingRange: widget.componentContext.extra.composingRange,
                  cursorCont: widget.componentContext.extra.cursorCont,
                  hasFocus: widget.componentContext.extra.isFocusedEditor,
                  textDirection: textDirection,
                  horizontalSpacing:
                      widget.componentContext.extra.horizontalSpacing,
                  verticalSpacing:
                      widget.componentContext.extra.verticalSpacing,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // if has padding add it
    child = Container(
      decoration: getDecorationForBlock(
        widget.node as Block,
        widget.componentContext.extra.defaultStyles,
      ),
      child: Padding(
        key: componentKey,
        padding: padding(),
        child: child,
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
