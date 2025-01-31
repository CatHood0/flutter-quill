import 'package:flutter/material.dart';

import '../../../flutter_quill.dart';

/// QuillComponentContainer is a wrapper of block component
///
/// 1. used to update the child widget when node is changed
/// 2. used to add the layer link to the child widget
class QuillComponentContainer extends StatelessWidget {
  const QuillComponentContainer({
    required this.builder,
    required this.node,
    super.key,
  });

  final Node node;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: calculateDirectionality(context),
      child: CompositedTransformTarget(
        link: node.link,
        child: builder(context),
      ),
    );
  }

  TextDirection calculateDirectionality(BuildContext context) {
    if (node.style.attributes[Attribute.direction.key] == null) {
      return Directionality.of(context);
    }
    return TextDirection.rtl;
  }
}
