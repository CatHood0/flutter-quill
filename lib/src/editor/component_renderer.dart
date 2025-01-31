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
    _cachedNodes.clear();
    _builders.add(builder);
  }

  @override
  void registerAll(Iterable<QuillComponentBuilder> builders) {
    _cachedNodes.clear();
    builders.forEach(register);
  }

  @override
  void unRegister(QuillComponentBuilder builder) {
    _cachedNodes.clear();
    _builders.remove(builder);
  }

  // we use this to cache the nodes widget to avoid unnecessary rebuilds
  final Map<int, Widget> _cachedNodes = {};

  @override
  Widget build(BuildContext buildContext, QuillContainer node,
      QuillComponentContext componentContext) {
    if (_cachedNodes[node.hashCode] != null) {
      print('Passing cached node(${node.hashCode})');
      return _cachedNodes[node.hashCode] as Widget;
    }
    for (final builder in _builders) {
      if (builder.validate(node)) {
        print('Validated node with builder type: ${builder.runtimeType}');
        print('Validated Node: $node');
        final child = QuillComponentContainer(
          node: node,
          builder: (ctx) {
            return builder.build(componentContext);
          },
        );
        _cachedNodes[node.hashCode] = child;
        return child;
      }
    }
    return const SizedBox.shrink();
  }
}
