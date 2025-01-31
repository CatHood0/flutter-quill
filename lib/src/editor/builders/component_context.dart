import 'package:flutter/material.dart';
import '../../../flutter_quill.dart';
import '../../document/nodes/container.dart';
import '../widgets/delegate.dart';

class QuillComponentContext {
  const QuillComponentContext({
    required this.buildContext,
    required this.node,
    required this.styles,
    required this.indentLevelCounts,
    required this.extra,
  });

  final BuildContext buildContext;
  final QuillContainer node;
  final Style styles;

  /// Represents the indentation levels
  ///
  /// Key: the indent level
  /// Value: the item index
  ///
  /// Is used commonly with list items
  /// because them can be Nested
  final Map<int, int> indentLevelCounts;
  final QuillWidgetParams extra;
}

class QuillWidgetParams {
  QuillWidgetParams({
    required this.horizontalSpacing,
    required this.verticalSpacing,
    required this.direction,
    required this.composingRange,
    required this.linksPrefixes,
    required this.onLaunchUrl,
    required this.controller,
    required this.editorConfigs,
    required this.defaultStyles,
    required this.isFocusedEditor,
    required this.enabledInteractions,
    required this.cursorCont,
    required this.linkActionPicker,
    required this.customStyleBuilder,
    required this.customRecognizerBuilder,
    required this.scrollBottomInset,
    required this.onTapCheckBoxFun,
  });

  final double scrollBottomInset;
  final LinkActionPicker linkActionPicker;
  final CustomStyleBuilder? customStyleBuilder;
  final CustomRecognizerBuilder? customRecognizerBuilder;
  final CursorCont cursorCont;
  final bool enabledInteractions;
  final bool isFocusedEditor;
  final DefaultStyles defaultStyles;
  final QuillRawEditorConfig editorConfigs;
  final QuillController controller;
  final HorizontalSpacing horizontalSpacing;
  final VerticalSpacing verticalSpacing;
  final TextDirection direction;
  final TextRange composingRange;
  final List<String> linksPrefixes;
  final void Function(String)? onLaunchUrl;
  final void Function(int offset, bool value)? onTapCheckBoxFun;
}
