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

class CheckBoxComponent extends QuillComponentBuilder {
  @override
  bool validate(QuillContainer<Node?> node) =>
      node.style.attributes.containsKey(Attribute.list.key) &&
      (node.style.attributes.containsValue(Attribute.unchecked) &&
          node.style.attributes.containsValue(Attribute.checked));

  @override
  QuillComponentWidget build(QuillComponentContext componentContext) {
    return CheckBoxComponentWidget(
      key: componentContext.node.key,
      node: componentContext.node,
      componentContext: componentContext,
    );
  }
}

class CheckBoxComponentWidget extends QuillComponentStatefulWidget {
  const CheckBoxComponentWidget({
    required this.componentContext,
    required super.node,
    required super.key,
  });

  final QuillComponentContext componentContext;

  @override
  State<CheckBoxComponentWidget> createState() => _CheckBoxComponentState();
}

class _CheckBoxComponentState extends State<CheckBoxComponentWidget>
    with
        SelectableMixin<CheckBoxComponentWidget>,
        DefaultSelectableMixin<CheckBoxComponentWidget> {
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
    Widget child = Container(
      width: double.infinity,
      alignment: align,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          textDirection: textDirection,
          children: [
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
                verticalSpacing: widget.componentContext.extra.verticalSpacing,
              ),
            ),
          ],
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
    return defaultStyles?.lists?.decoration;
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
