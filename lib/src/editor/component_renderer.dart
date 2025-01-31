import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../flutter_quill.dart';
import '../document/nodes/container.dart';
import 'builders/component_container.dart';
import 'builders/component_context.dart';
import 'builders/component_node_builder.dart';

abstract class QuillComponentRendererService {
  void register(QuillComponentBuilder builder);
  void registerAll(Iterable<QuillComponentBuilder> builders);
  void unRegister(QuillComponentBuilder builder);

  /// Build a widget for the specified [node].
  ///
  /// the widget is embedded in a [BlockComponentContainer] widget.
  ///
  /// the header and the footer only works for the root node.
  @mustBeOverridden
  Widget build(
    BuildContext buildContext,
    QuillContainer node,
    QuillComponentContext componentContext,
  );

  @mustCallSuper
  List<Widget> buildList(
    BuildContext buildContext,
    Iterable<Node> nodes,
    QuillComponentContext componentContext,
  ) {
    return nodes
        .map((node) => build(
              buildContext,
              node as QuillContainer,
              componentContext,
            ))
        .toList(growable: false);
  }
}

class QuillComponentRenderer extends QuillComponentRendererService {
  QuillComponentRenderer({required List<QuillComponentBuilder> builders}) {
    registerAll(builders);
  }
  final Set<QuillComponentBuilder> _builders = {};
  @override
  void register(QuillComponentBuilder builder) {
    _builders.add(builder);
  }

  @override
  void registerAll(Iterable<QuillComponentBuilder> builders) {
    builders.forEach(register);
  }

  @override
  void unRegister(QuillComponentBuilder builder) {
    _builders.remove(builder);
  }

  @override
  Widget build(BuildContext buildContext, QuillContainer node,
      QuillComponentContext componentContext) {
    for (final builder in _builders) {
      if (builder.validate(node)) {
        final child = QuillComponentContainer(
          node: node,
          builder: (ctx) {
            return builder.build(componentContext);
          },
        );
        return child;
      }
    }
    return const SizedBox.shrink();
  }
}
