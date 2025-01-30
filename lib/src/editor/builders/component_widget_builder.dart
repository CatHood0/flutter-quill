import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../document/nodes/container.dart';
import 'component_node_widget.dart';

class QuillComponentStatelessWidget extends StatelessWidget
    implements QuillComponentWidget {
  const QuillComponentStatelessWidget({
    required this.node,
    super.key,
  });

  @override
  final QuillContainer node;

  @override
  @mustBeOverridden
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class QuillComponentStatefulWidget extends StatefulWidget
    implements QuillComponentWidget {
  const QuillComponentStatefulWidget({
    required this.node,
    super.key,
  });

  @override
  final QuillContainer node;

  @override
  @mustBeOverridden
  State<QuillComponentStatefulWidget> createState() =>
      _QuillComponentStatefulWidgetState();
}

class _QuillComponentStatefulWidgetState
    extends State<QuillComponentStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
