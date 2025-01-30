import 'package:flutter/material.dart';
import '../../../flutter_quill.dart';
import '../../document/nodes/container.dart';
import 'component_context.dart';
import 'component_node_widget.dart';

abstract class QuillComponentBuilder with QuillComponentSelectable {
  QuillComponentBuilder();

  /// validate the node.
  ///
  /// return true if the node is valid.
  /// return false if the node is invalid,
  bool validate(QuillContainer node) => true;

  QuillComponentWidget build(QuillComponentContext componentContext);
}

mixin QuillComponentSelectable<T extends QuillComponentBuilder> {
  /// the start position of the block component.
  ///
  /// For the text block component, the start position is always 0.
  TextRange start(Node node) => TextRange.collapsed(node.documentOffset);

  /// the end position of the block component.
  ///
  /// For the text block component, the end position is always the length of the text.
  TextRange end(Node node) => TextRange(
        start: node.documentOffset,
        end: node.documentOffset + node.offset,
      );
}
