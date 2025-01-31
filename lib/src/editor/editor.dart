import 'dart:math' as math;

import 'package:flutter/cupertino.dart'
    show CupertinoTheme, cupertinoTextSelectionControls;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../../flutter_quill.dart';
import '../common/extensions/node_ext.dart';
import '../common/utils/platform.dart';
import '../document/nodes/container.dart' as container_node;
import 'builders/standard_builders/standard_builders.dart';
import 'editor_selection_service.dart';
import 'gestures/quill_gesture_detector.dart';
import 'render_container_editor.dart';
import 'selection/selectable_mixin.dart';
import 'widgets/box.dart';
import 'widgets/delegate.dart';
import 'widgets/float_cursor.dart';
import 'widgets/text/text_selection.dart';

class QuillEditor extends StatefulWidget {
  /// Quick start guide:
  ///
  /// Instantiate a controller:
  /// ```dart
  /// QuillController _controller = QuillController.basic();
  /// ```
  ///
  /// Connect the controller to the `QuillEditor` and `QuillSimpleToolbar` widgets.
  ///
  /// ```dart
  /// QuillSimpleToolbar(
  ///   controller: _controller,
  /// ),
  /// Expanded(
  ///   child: QuillEditor.basic(
  ///     controller: _controller,
  ///   ),
  /// ),
  /// ```
  ///
  QuillEditor({
    required this.focusNode,
    required this.scrollController,
    required this.controller,
    this.config = const QuillEditorConfig(),
    super.key,
  }) {
    // Store editor config in the controller to pass them to the document to
    // support search within embed objects https://github.com/singerdmx/flutter-quill/pull/2090.
    // For internal use only, should not be exposed as a public API.
    controller.editorConfig = config;
  }

  factory QuillEditor.basic({
    required QuillController controller,
    Key? key,
    QuillEditorConfig config = const QuillEditorConfig(),
    FocusNode? focusNode,
    ScrollController? scrollController,
  }) {
    return QuillEditor(
      key: key,
      scrollController: scrollController ?? ScrollController(),
      focusNode: focusNode ?? FocusNode(),
      controller: controller,
      config: config,
    );
  }

  /// Controller object which establishes a link between a rich text document
  /// and this editor.
  final QuillController controller;

  /// The configurations for the editor widget.
  final QuillEditorConfig config;

  /// Controls whether this editor has keyboard focus.
  final FocusNode focusNode;

  /// The [ScrollController] to use when vertically scrolling the contents.
  final ScrollController scrollController;

  @override
  QuillEditorState createState() => QuillEditorState();
}

class QuillEditorState extends State<QuillEditor>
    implements EditorTextSelectionGestureDetectorBuilderDelegate {
  late GlobalKey<EditorState> _editorKey;
  late EditorTextSelectionGestureDetectorBuilder
      _selectionGestureDetectorBuilder;

  QuillController get controller => widget.controller;

  QuillEditorConfig get configurations => widget.config;

  @override
  void initState() {
    super.initState();
    _editorKey = configurations.editorKey ?? GlobalKey<EditorState>();
    _selectionGestureDetectorBuilder =
        QuillEditorSelectionGestureDetectorBuilder(
      this,
      configurations.detectWordBoundary,
    );

    final focusNode = widget.focusNode;

    if (configurations.autoFocus) {
      focusNode.requestFocus();
    }

    // Hide toolbar when the editor loses focus.
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _editorKey.currentState?.hideToolbar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme =
        configurations.textSelectionThemeData ?? TextSelectionTheme.of(context);

    TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset? cursorOffset;
    Color? cursorColor;
    Color selectionColor;
    Radius? cursorRadius;

    if (theme.isCupertino) {
      final cupertinoTheme = CupertinoTheme.of(context);
      textSelectionControls = cupertinoTextSelectionControls;
      paintCursorAboveText = true;
      cursorOpacityAnimates = true;
      cursorColor ??= selectionTheme.cursorColor ?? cupertinoTheme.primaryColor;
      selectionColor = selectionTheme.selectionColor ??
          cupertinoTheme.primaryColor.withValues(alpha: 0.40);
      cursorRadius ??= const Radius.circular(2);
      cursorOffset = Offset(
          iOSHorizontalOffset / MediaQuery.devicePixelRatioOf(context), 0);
    } else {
      textSelectionControls = materialTextSelectionControls;
      paintCursorAboveText = false;
      cursorOpacityAnimates = false;
      cursorColor ??= selectionTheme.cursorColor ?? theme.colorScheme.primary;
      selectionColor = selectionTheme.selectionColor ??
          theme.colorScheme.primary.withValues(alpha: 0.40);
    }

    final showSelectionToolbar = configurations.enableInteractiveSelection &&
        configurations.enableSelectionToolbar;

    final child = QuillRawEditor(
      key: _editorKey,
      controller: controller,
      config: QuillRawEditorConfig(
        characterShortcutEvents: widget.config.characterShortcutEvents,
        builders: widget.config.builders ?? [...standardsBuilders],
        spaceShortcutEvents: widget.config.spaceShortcutEvents,
        onKeyPressed: widget.config.onKeyPressed,
        customLeadingBuilder: widget.config.customLeadingBlockBuilder,
        focusNode: widget.focusNode,
        scrollController: widget.scrollController,
        scrollable: configurations.scrollable,
        enableAlwaysIndentOnTab: configurations.enableAlwaysIndentOnTab,
        scrollBottomInset: configurations.scrollBottomInset,
        padding: configurations.padding,
        readOnly: controller.readOnly,
        checkBoxReadOnly: configurations.checkBoxReadOnly,
        disableClipboard: configurations.disableClipboard,
        placeholder: configurations.placeholder,
        onLaunchUrl: configurations.onLaunchUrl,
        contextMenuBuilder: showSelectionToolbar
            ? (configurations.contextMenuBuilder ??
                QuillRawEditorConfig.defaultContextMenuBuilder)
            : null,
        showSelectionHandles: isMobile,
        showCursor: configurations.showCursor ?? true,
        cursorStyle: CursorStyle(
          color: cursorColor,
          backgroundColor: Colors.grey,
          width: 2,
          radius: cursorRadius,
          offset: cursorOffset,
          paintAboveText:
              configurations.paintCursorAboveText ?? paintCursorAboveText,
          opacityAnimates: cursorOpacityAnimates,
        ),
        textCapitalization: configurations.textCapitalization,
        minHeight: configurations.minHeight,
        maxHeight: configurations.maxHeight,
        maxContentWidth: configurations.maxContentWidth,
        customStyles: configurations.customStyles,
        expands: configurations.expands,
        autoFocus: configurations.autoFocus,
        selectionColor: selectionColor,
        selectionCtrls:
            configurations.textSelectionControls ?? textSelectionControls,
        keyboardAppearance: configurations.keyboardAppearance,
        enableInteractiveSelection: configurations.enableInteractiveSelection,
        scrollPhysics: configurations.scrollPhysics,
        embedBuilder: _getEmbedBuilder,
        linkActionPickerDelegate: configurations.linkActionPickerDelegate,
        customStyleBuilder: configurations.customStyleBuilder,
        customRecognizerBuilder: configurations.customRecognizerBuilder,
        floatingCursorDisabled: configurations.floatingCursorDisabled,
        customShortcuts: configurations.customShortcuts,
        customActions: configurations.customActions,
        customLinkPrefixes: configurations.customLinkPrefixes,
        onTapOutsideEnabled: configurations.onTapOutsideEnabled,
        onTapOutside: configurations.onTapOutside,
        dialogTheme: configurations.dialogTheme,
        contentInsertionConfiguration:
            configurations.contentInsertionConfiguration,
        enableScribble: configurations.enableScribble,
        onScribbleActivated: configurations.onScribbleActivated,
        scribbleAreaInsets: configurations.scribbleAreaInsets,
        readOnlyMouseCursor: configurations.readOnlyMouseCursor,
        textInputAction: configurations.textInputAction,
        onPerformAction: configurations.onPerformAction,
      ),
    );

    final editor = selectionEnabled
        ? _selectionGestureDetectorBuilder.build(
            behavior: HitTestBehavior.translucent,
            detectWordBoundary: configurations.detectWordBoundary,
            child: child,
          )
        : child;

    if (kIsWeb) {
      // Intercept RawKeyEvent on Web to prevent it from propagating to parents
      // that might interfere with the editor key behavior, such as
      // SingleChildScrollView. Thanks to @wliumelb for the workaround.
      // See issue https://github.com/singerdmx/flutter-quill/issues/304
      return KeyboardListener(
        onKeyEvent: (_) {},
        focusNode: FocusNode(
          onKeyEvent: (node, event) => KeyEventResult.skipRemainingHandlers,
        ),
        child: editor,
      );
    }

    return editor;
  }

  EmbedBuilder _getEmbedBuilder(Embed node) {
    final builders = configurations.embedBuilders;

    if (builders != null) {
      for (final builder in builders) {
        if (builder.key == node.value.type) {
          return builder;
        }
      }
    }

    final unknownEmbedBuilder = configurations.unknownEmbedBuilder;
    if (unknownEmbedBuilder != null) {
      return unknownEmbedBuilder;
    }

    throw UnimplementedError(
      'Embeddable type "${node.value.type}" is not supported by supplied '
      'embed builders. You must pass your own builder function to '
      'embedBuilders property of QuillEditor or QuillField widgets or '
      'specify an unknownEmbedBuilder.',
    );
  }

  @override
  GlobalKey<EditorState> get editableTextKey => _editorKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => configurations.enableInteractiveSelection;

  /// Throws [StateError] if [_editorKey] is not connected to [QuillRawEditor] correctly.
  ///
  /// See also: [Flutter currentState docs](https://github.com/flutter/flutter/blob/b8211b3d941f2dcaa2db22e4572b74ede620cced/packages/flutter/lib/src/widgets/framework.dart#L179-L181)
  EditorState get _requireEditorCurrentState {
    final currentState = _editorKey.currentState;
    if (currentState == null) {
      throw StateError(
          'The $EditorState is null, ensure the $_editorKey is associated correctly with $QuillRawEditor.');
    }
    return currentState;
  }

  @internal
  void requestKeyboard() {
    _requireEditorCurrentState.requestKeyboard();
  }
}

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
///
/// Used by [RenderEditor.onSelectionChanged].
typedef TextSelectionChangedHandler = void Function(
    TextSelection selection, SelectionChangedCause cause);

/// Signature for the callback that reports when a selection action is actually
/// completed and ratified. Completion is defined as when the user input has
/// concluded for an entire selection action. For simple taps and keyboard input
/// events that change the selection, this callback is invoked immediately
/// following the TextSelectionChangedHandler. For long taps, the selection is
/// considered complete at the up event of a long tap. For drag selections, the
/// selection completes once the drag/pan event ends or is interrupted.
///
/// Used by [RenderEditor.onSelectionCompleted].
typedef TextSelectionCompletedHandler = void Function();

// The padding applied to text field. Used to determine the bounds when
// moving the floating cursor.
const EdgeInsets _kFloatingCursorAddedMargin = EdgeInsets.fromLTRB(4, 4, 4, 5);

// The additional size on the x and y axis with which to expand the prototype
// cursor to render the floating cursor in pixels.
const EdgeInsets _kFloatingCaretSizeIncrease =
    EdgeInsets.symmetric(horizontal: 0.5, vertical: 1);

/// Displays a document as a vertical list of document segments (lines
/// and blocks).
///
/// Children of [RenderEditor] must be instances of [RenderEditableBox].
class RenderEditor extends RenderEditableContainerBox
    with RelayoutWhenSystemFontsChangeMixin
    implements QuillEditorSelectionService {
  RenderEditor({
    required this.document,
    required super.textDirection,
    required bool hasFocus,
    required this.selection,
    required this.scrollable,
    required LayerLink startHandleLayerLink,
    required LayerLink endHandleLayerLink,
    required super.padding,
    required CursorCont cursorController,
    required this.onSelectionChanged,
    required this.onSelectionCompleted,
    required super.scrollBottomInset,
    required this.floatingCursorDisabled,
    ViewportOffset? offset,
    super.children,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
    double? maxContentWidth,
  })  : _hasFocus = hasFocus,
        _extendSelectionOrigin = selection,
        _startHandleLayerLink = startHandleLayerLink,
        _endHandleLayerLink = endHandleLayerLink,
        _cursorController = cursorController,
        _maxContentWidth = maxContentWidth,
        super(
          container: document.root,
        );

  final CursorCont _cursorController;
  final bool floatingCursorDisabled;
  final bool scrollable;

  Document document;
  TextSelection selection;
  bool _hasFocus = false;
  LayerLink _startHandleLayerLink;
  LayerLink _endHandleLayerLink;

  /// Called when the selection changes.
  TextSelectionChangedHandler onSelectionChanged;
  TextSelectionCompletedHandler onSelectionCompleted;
  final ValueNotifier<bool> _selectionStartInViewport =
      ValueNotifier<bool>(true);

  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;

  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  void _updateSelectionExtentsVisibility(Offset effectiveOffset) {
    final visibleRegion = Offset.zero & size;
    final startPosition =
        TextPosition(offset: selection.start, affinity: selection.affinity);
    final startOffset = _getOffsetForCaret(startPosition);
    if (startOffset.dx == 0 && startOffset.dy == 0) return;
    // TODO(justinmc): https://github.com/flutter/flutter/issues/31495
    // Check if the selection is visible with an approximation because a
    // difference between rounded and unrounded values causes the caret to be
    // reported as having a slightly (< 0.5) negative y offset. This rounding
    // happens in paragraph.cc's layout and TextPainer's
    // _applyFloatingPointHack. Ideally, the rounding mismatch will be fixed and
    // this can be changed to be a strict check instead of an approximation.
    const visibleRegionSlop = 0.5;
    _selectionStartInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(startOffset + effectiveOffset);

    final endPosition =
        TextPosition(offset: selection.end, affinity: selection.affinity);
    final endOffset = _getOffsetForCaret(endPosition);
    _selectionEndInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(endOffset + effectiveOffset);
  }

  // returns offset relative to this at which the caret will be painted
  // given a global TextPosition
  Offset _getOffsetForCaret(TextPosition position) {
    final child = childAtPosition(position);
    if (child == null) return Offset.zero;
    final childPosition = child.globalToLocalPosition(position);
    final localOffsetForCaret =
        child.getOffsetForCaretByPosition(childPosition);
    return localOffsetForCaret;
  }

  void setDocument(Document doc) {
    if (document == doc) {
      return;
    }
    document = doc;
    markNeedsLayout();
  }

  void setHasFocus(bool h) {
    if (_hasFocus == h) {
      return;
    }
    _hasFocus = h;
    markNeedsSemanticsUpdate();
  }

  Offset get _paintOffset => Offset(0, -(offset?.pixels ?? 0.0));

  ViewportOffset? get offset => _offset;
  ViewportOffset? _offset;

  set offset(ViewportOffset? value) {
    if (_offset == value) return;
    if (attached) _offset?.removeListener(markNeedsPaint);
    _offset = value;
    if (attached) _offset?.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  void setSelection(TextSelection t) {
    if (selection == t) {
      return;
    }
    selection = t;
    markNeedsPaint();

    if (!_shiftPressed && !_isDragging) {
      // Only update extend selection origin if Shift key is not pressed and
      // user is not dragging selection.
      _extendSelectionOrigin = selection;
    }
  }

  bool get _shiftPressed =>
      HardwareKeyboard.instance.logicalKeysPressed
          .contains(LogicalKeyboardKey.shiftLeft) ||
      HardwareKeyboard.instance.logicalKeysPressed
          .contains(LogicalKeyboardKey.shiftRight);

  void setStartHandleLayerLink(LayerLink value) {
    if (_startHandleLayerLink == value) {
      return;
    }
    _startHandleLayerLink = value;
    markNeedsPaint();
  }

  void setEndHandleLayerLink(LayerLink value) {
    if (_endHandleLayerLink == value) {
      return;
    }
    _endHandleLayerLink = value;
    markNeedsPaint();
  }

  void setScrollBottomInset(double value) {
    if (scrollBottomInset == value) {
      return;
    }
    scrollBottomInset = value;
    markNeedsPaint();
  }

  double? _maxContentWidth;

  set maxContentWidth(double? value) {
    if (_maxContentWidth == value) return;
    _maxContentWidth = value;
    markNeedsLayout();
  }

  @override
  List<TextSelectionPoint> getEndpointsForSelection(
      TextSelection textSelection) {
    if (textSelection.isCollapsed) {
      final child = childAtPosition(textSelection.extent);
      if (child == null) return [];
      final localPosition = TextPosition(
        offset: textSelection.extentOffset - child.node.offset,
        affinity: textSelection.affinity,
      );
      final localOffset = child.getOffsetForCaretByPosition(localPosition);
      // should we remove it?
      // before it was used to increate the offset of TextSelectionPoint
      // but now it does not do nothing
      // final parentData = child.renderBox!.parentData as BoxParentData;
      return <TextSelectionPoint>[
        TextSelectionPoint(
            Offset(0, child.preferredLineHeightByPosition(localPosition)) +
                localOffset,
            null)
      ];
    }

    final baseNode = container.queryChild(textSelection.start, false).node;

    SelectableMixin? baseChild;
    var baseChildIndex = 0;
    for (final node in container.children) {
      if (node == baseNode) {
        baseChild = node.selectable;
      }
      baseChildIndex++;
    }

    // we return a empty list, because SelectableMixin can be completely
    // null value, since the state of the SelectableMixin implementation
    // couldn't be unmounted yet
    if (baseChild == null) return [];
    final baseParentData = baseChild.renderBox!.parentData as BoxParentData;
    final baseSelection = localSelection(baseChild.node, textSelection, true);
    var basePoint = baseChild.getBaseEndpointForSelection(baseSelection);
    basePoint = TextSelectionPoint(
      basePoint.point + baseParentData.offset,
      basePoint.direction,
    );

    final extentNode = container.queryChild(textSelection.end, false).node;
    SelectableMixin? extentChild = baseChild;

    /// Trap shortening the text of a link which can cause selection to extend off end of line
    if (extentNode == null) {
      while (true) {
        final next = container.children.elementAtOrNull(baseChildIndex);
        if (next == null) {
          break;
        }
        baseChildIndex++;
      }
    } else {
      for (var index = baseChildIndex; index < container.childCount; index++) {
        final node = container.children.elementAtOrNull(index);
        if (node == extentNode) {
          extentChild = node!.selectable;
        }
      }
    }
    // we return a empty list, because SelectableMixin can be completely
    // null value, since the state of the SelectableMixin implementation
    // couldn't be unmounted yet
    if (extentChild == null) return [basePoint];

    final extentParentData = extentChild.renderBox!.parentData as BoxParentData;
    final extentSelection =
        localSelection(extentChild.node, textSelection, true);
    var extentPoint =
        extentChild.getExtentEndpointForSelection(extentSelection);
    extentPoint = TextSelectionPoint(
      extentPoint.point + extentParentData.offset,
      extentPoint.direction,
    );

    return <TextSelectionPoint>[basePoint, extentPoint];
  }

  Offset? _lastTapDownPosition;

  // Used on Desktop (mouse and keyboard enabled platforms) as base offset
  // for extending selection, either with combination of `Shift` + Click or
  // by dragging
  TextSelection? _extendSelectionOrigin;

  @override
  void handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
  }

  bool _isDragging = false;

  void handleDragStart(DragStartDetails details) {
    _isDragging = true;

    final newSelection = selectPositionAt(
      from: details.globalPosition,
      cause: SelectionChangedCause.drag,
    );

    if (newSelection == null) return;
    // Make sure to remember the origin for extend selection.
    _extendSelectionOrigin = newSelection;
  }

  void handleDragEnd(DragEndDetails details) {
    _isDragging = false;
    onSelectionCompleted();
  }

  @override
  void selectWordsInRange(
    Offset from,
    Offset? to,
    SelectionChangedCause cause,
  ) {
    final firstPosition = getPositionForOffset(from);
    if (firstPosition.offset <= -1) return;
    final firstWord = selectWordAtPosition(firstPosition);
    if (firstWord.start <= -1 && firstWord.end <= -1) return;
    final lastWord =
        to == null ? firstWord : selectWordAtPosition(getPositionForOffset(to));

    _handleSelectionChange(
      TextSelection(
        baseOffset: firstWord.base.offset,
        extentOffset: lastWord.extent.offset,
        affinity: firstWord.affinity,
      ),
      cause,
    );
  }

  void _handleSelectionChange(
    TextSelection nextSelection,
    SelectionChangedCause cause,
  ) {
    final focusingEmpty = nextSelection.baseOffset == 0 &&
        nextSelection.extentOffset == 0 &&
        !_hasFocus;
    if (nextSelection == selection &&
        cause != SelectionChangedCause.keyboard &&
        !focusingEmpty) {
      return;
    }
    onSelectionChanged(nextSelection, cause);
  }

  /// Extends current selection to the position closest to specified offset.
  void extendSelection(Offset to, {required SelectionChangedCause cause}) {
    /// The below logic does not exactly match the native version because
    /// we do not allow swapping of base and extent positions.
    assert(_extendSelectionOrigin != null);
    final position = getPositionForOffset(to);
    if (position.offset <= -1) return;
    if (position.offset < _extendSelectionOrigin!.baseOffset) {
      _handleSelectionChange(
        TextSelection(
          baseOffset: position.offset,
          extentOffset: _extendSelectionOrigin!.extentOffset,
          affinity: selection.affinity,
        ),
        cause,
      );
    } else if (position.offset > _extendSelectionOrigin!.extentOffset) {
      _handleSelectionChange(
        TextSelection(
          baseOffset: _extendSelectionOrigin!.baseOffset,
          extentOffset: position.offset,
          affinity: selection.affinity,
        ),
        cause,
      );
    }
  }

  @override
  void selectWordEdge(SelectionChangedCause cause) {
    assert(_lastTapDownPosition != null);
    final position = getPositionForOffset(_lastTapDownPosition!);
    if (position.offset <= -1) return;
    final child = childAtPosition(position);
    if (child == null) return;
    final nodeOffset = child.node.offset;
    final localPosition = TextPosition(
      offset: position.offset - nodeOffset,
      affinity: position.affinity,
    );
    final localWord = child.getWordBoundary(localPosition);
    if (localWord.start <= -1 || localWord.end <= -1) return;
    final word = TextRange(
      start: localWord.start + nodeOffset,
      end: localWord.end + nodeOffset,
    );

    // Don't change selection if the selected word is a placeholder.
    if (child.node.style.attributes.containsKey(Attribute.placeholder.key)) {
      return;
    }

    if (position.offset - word.start <= 1 && word.end != position.offset) {
      _handleSelectionChange(
        TextSelection.collapsed(offset: word.start),
        cause,
      );
    } else {
      _handleSelectionChange(
        TextSelection.collapsed(
            offset: word.end, affinity: TextAffinity.upstream),
        cause,
      );
    }
  }

  @override
  TextSelection? selectPositionAt({
    required Offset from,
    required SelectionChangedCause cause,
    Offset? to,
  }) {
    final fromPosition = getPositionForOffset(from);
    if (fromPosition.offset <= -1) return null;
    final toPosition = to == null ? null : getPositionForOffset(to);

    var baseOffset = fromPosition.offset;
    var extentOffset = fromPosition.offset;
    if (toPosition != null && toPosition.offset >= 0) {
      baseOffset = math.min(fromPosition.offset, toPosition.offset);
      extentOffset = math.max(fromPosition.offset, toPosition.offset);
    }

    final newSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: fromPosition.affinity,
    );

    // Call [onSelectionChanged] only when the selection actually changed.
    _handleSelectionChange(newSelection, cause);
    return newSelection;
  }

  @override
  void selectWord(SelectionChangedCause cause) {
    selectWordsInRange(_lastTapDownPosition!, null, cause);
  }

  @override
  void selectPosition({required SelectionChangedCause cause}) {
    selectPositionAt(from: _lastTapDownPosition!, cause: cause);
  }

  @override
  TextSelection selectWordAtPosition(TextPosition position) {
    if (position.offset <= -1) return const TextSelection.collapsed(offset: -1);
    final word = getWordBoundary(position);
    if (word.start <= -1 && word.end <= -1)
      return const TextSelection.collapsed(offset: -1);
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end) {
      return TextSelection.fromPosition(position);
    }
    return TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  @override
  TextSelection selectLineAtPosition(TextPosition position) {
    final line = getLineAtOffset(position);

    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= line.end) {
      return TextSelection.fromPosition(position);
    }
    return TextSelection(baseOffset: line.start, extentOffset: line.end);
  }

  @override
  void performLayout() {
    assert(() {
      if (!scrollable || !constraints.hasBoundedHeight) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('RenderEditableContainerBox must have '
            'unlimited space along its main axis when it is scrollable.'),
        ErrorDescription('RenderEditableContainerBox does not clip or'
            ' resize its children, so it must be '
            'placed in a parent that does not constrain the main '
            'axis.'),
        ErrorHint(
            'You probably want to put the RenderEditableContainerBox inside a '
            'RenderViewport with a matching main axis or disable the '
            'scrollable property.')
      ]);
    }());
    assert(() {
      if (constraints.hasBoundedWidth) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('RenderEditableContainerBox must have a bounded'
            ' constraint for its cross axis.'),
        ErrorDescription('RenderEditableContainerBox forces its children to '
            "expand to fit the RenderEditableContainerBox's container, "
            'so it must be placed in a parent that constrains the cross '
            'axis to a finite dimension.'),
      ]);
    }());

    resolvePadding();
    assert(resolvedPadding != null);

    var mainAxisExtent = resolvedPadding!.top;
    var child = firstChild;
    final innerConstraints = BoxConstraints.tightFor(
            width: math.min(
                _maxContentWidth ?? double.infinity, constraints.maxWidth))
        .deflate(resolvedPadding!);
    final leftOffset = _maxContentWidth == null
        ? 0.0
        : math.max((constraints.maxWidth - _maxContentWidth!) / 2, 0);
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final childParentData = child.parentData as EditableContainerParentData
        ..offset = Offset(resolvedPadding!.left + leftOffset, mainAxisExtent);
      mainAxisExtent += child.size.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    mainAxisExtent += resolvedPadding!.bottom;
    size = constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));

    assert(size.isFinite);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasFocus &&
        _cursorController.show.value &&
        !_cursorController.style.paintAboveText) {
      _paintFloatingCursor(context, offset);
    }
    defaultPaint(context, offset);
    _updateSelectionExtentsVisibility(offset + _paintOffset);
    _paintHandleLayers(context, getEndpointsForSelection(selection));

    if (_hasFocus &&
        _cursorController.show.value &&
        _cursorController.style.paintAboveText) {
      _paintFloatingCursor(context, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  void _paintHandleLayers(
      PaintingContext context, List<TextSelectionPoint> endpoints) {
    var startPoint = endpoints[0].point;
    startPoint = Offset(
      startPoint.dx.clamp(0.0, size.width),
      startPoint.dy.clamp(0.0, size.height),
    );
    context.pushLayer(
      LeaderLayer(link: _startHandleLayerLink, offset: startPoint),
      super.paint,
      Offset.zero,
    );
    if (endpoints.length == 2) {
      var endPoint = endpoints[1].point;
      endPoint = Offset(
        endPoint.dx.clamp(0.0, size.width),
        endPoint.dy.clamp(0.0, size.height),
      );
      context.pushLayer(
        LeaderLayer(link: _endHandleLayerLink, offset: endPoint),
        super.paint,
        Offset.zero,
      );
    }
  }

  @override
  double preferredLineHeight(TextPosition position) {
    final child = childAtPosition(position);
    if (child == null) return 0;
    return child.preferredLineHeightByPosition(
        TextPosition(offset: position.offset - child.node.offset));
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    final local = globalToLocal(offset);
    final child = getNodeInOffset(
      document.root.children.toList(),
      offset,
      0,
      container.childCount - 1,
    )?.selectable;
    if (child == null) return const TextPosition(offset: -1);
    final parentData = child.renderBox!.parentData as BoxParentData;
    final localOffset = local - parentData.offset;
    final localPosition = child.getPositionForOffset(localOffset);
    return TextPosition(
      offset: localPosition.offset + child.node.offset,
      affinity: localPosition.affinity,
    );
  }

  Node? getNodeInOffset(
    List<Node> sortedNodes,
    Offset offset,
    int start,
    int end, [
    bool? after,
  ]) {
    if (start < 0 && end >= sortedNodes.length) {
      return null;
    }

    var min = _findCloseNode(
      sortedNodes,
      start,
      end,
      (rect) => rect.bottom <= offset.dy,
    );

    final filteredNodes = List.of(sortedNodes)
      ..retainWhere(
        (n) => n.rect.bottom == sortedNodes[min].rect.bottom,
      );
    min = 0;
    if (filteredNodes.length > 1) {
      min = _findCloseNode(
        sortedNodes,
        0,
        filteredNodes.length - 1,
        (rect) => rect.right <= offset.dx,
      );
    }

    final node = filteredNodes[min];
    if (node is Leaf && node.rect.top <= offset.dy) {
      return node;
    } else if (node is container_node.QuillContainer) {
      if (node.children.isNotEmpty &&
          node.children.first.renderBox != null &&
          node.children.first.rect.top <= offset.dy) {
        final children = node.children.toList(growable: false)
          ..sort(
            (a, b) => a.rect.bottom != b.rect.bottom
                ? a.rect.bottom.compareTo(b.rect.bottom)
                : a.rect.left.compareTo(b.rect.left),
          );

        return getNodeInOffset(
          children,
          offset,
          0,
          children.length - 1,
        );
      }
    }
    if (min > 0 && after != null) {
      if (after) {
        return sortedNodes[min + 1];
      } else {
        return sortedNodes[min - 1];
      }
    }
    return node;
  }

  int _findCloseNode(
    List<Node> sortedNodes,
    int start,
    int end,
    bool Function(Rect rect) compare,
  ) {
    var min = start;
    var max = end;
    while (min <= max) {
      final mid = min + ((max - min) >> 1);
      final rect = sortedNodes[mid].rect;
      if (compare(rect)) {
        min = mid + 1;
      } else {
        max = mid - 1;
      }
    }
    return min.clamp(start, end);
  }

  /// Returns the y-offset of the editor at which [selection] is visible.
  ///
  /// The offset is the distance from the top of the editor and is the minimum
  /// from the current scroll position until [selection] becomes visible.
  /// Returns null if [selection] is already visible.
  ///
  /// Finds the closest scroll offset that fully reveals the editing cursor.
  ///
  /// The `scrollOffset` parameter represents current scroll offset in the
  /// parent viewport.
  ///
  /// The `offsetInViewport` parameter represents the editor's vertical offset
  /// in the parent viewport. This value should normally be 0.0 if this editor
  /// is the only child of the viewport or if it's the topmost child. Otherwise
  /// it should be a positive value equal to total height of all siblings of
  /// this editor from above it.
  ///
  /// Returns `null` if the cursor is currently visible.
  double? getOffsetToRevealCursor(
      double viewportHeight, double scrollOffset, double offsetInViewport) {
    // Endpoints coordinates represents lower left or lower right corner of
    // the selection. If we want to scroll up to reveal the caret we need to
    // adjust the dy value by the height of the line. We also add a small margin
    // so that the caret is not too close to the edge of the viewport.
    final endpoints = getEndpointsForSelection(selection);
    if (endpoints.isEmpty) return null;

    // when we drag the right handle, we should get the last point
    TextSelectionPoint endpoint;
    if (selection.isCollapsed) {
      endpoint = endpoints.first;
    } else {
      if (selection is DragTextSelection) {
        endpoint = (selection as DragTextSelection).first
            ? endpoints.first
            : endpoints.last;
      } else {
        endpoint = endpoints.first;
      }
    }

    // Collapsed selection => caret
    final child = childAtPosition(selection.extent);
    if (child == null) return null;
    const kMargin = 8.0;

    final caretTop = endpoint.point.dy -
        child.preferredLineHeightByPosition(TextPosition(
            offset: selection.extentOffset - child.node.documentOffset)) -
        kMargin +
        offsetInViewport +
        scrollBottomInset;
    final caretBottom =
        endpoint.point.dy + kMargin + offsetInViewport + scrollBottomInset;
    double? dy;
    if (caretTop < scrollOffset) {
      dy = caretTop;
    } else if (caretBottom > scrollOffset + viewportHeight) {
      dy = caretBottom - viewportHeight;
    }
    if (dy == null) {
      return null;
    }
    // Clamping to 0.0 so that the content does not jump unnecessarily.
    return math.max(dy, 0);
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    final targetChild = childAtPosition(position);
    if (targetChild == null) return Rect.zero;
    final localPosition = targetChild.globalToLocalPosition(position);

    final childLocalRect = targetChild.getLocalRectForCaret(localPosition);

    final boxParentData = targetChild.renderBox!.parentData as BoxParentData;
    return childLocalRect.shift(Offset(0, boxParentData.offset.dy));
  }

  // Start floating cursor

  FloatingCursorPainter get _floatingCursorPainter => FloatingCursorPainter(
        floatingCursorRect: _floatingCursorRect,
        style: _cursorController.style,
      );

  bool _floatingCursorOn = false;
  Rect? _floatingCursorRect;

  TextPosition get floatingCursorTextPosition => _floatingCursorTextPosition;
  late TextPosition _floatingCursorTextPosition;

  // The relative origin in relation to the distance the user has theoretically
  // dragged the floating cursor offscreen.
  // This value is used to account for the difference
  // in the rendering position and the raw offset value.
  Offset _relativeOrigin = Offset.zero;
  Offset? _previousOffset;
  bool _resetOriginOnLeft = false;
  bool _resetOriginOnRight = false;
  bool _resetOriginOnTop = false;
  bool _resetOriginOnBottom = false;

  /// Returns the position within the editor closest to the raw cursor offset.
  Offset calculateBoundedFloatingCursorOffset(
      Offset rawCursorOffset, double preferredLineHeight) {
    var deltaPosition = Offset.zero;
    final topBound = _kFloatingCursorAddedMargin.top;
    final bottomBound =
        size.height - preferredLineHeight + _kFloatingCursorAddedMargin.bottom;
    final leftBound = _kFloatingCursorAddedMargin.left;
    final rightBound = size.width - _kFloatingCursorAddedMargin.right;

    if (_previousOffset != null) {
      deltaPosition = rawCursorOffset - _previousOffset!;
    }

    // If the raw cursor offset has gone off an edge,
    // we want to reset the relative origin of
    // the dragging when the user drags back into the field.
    if (_resetOriginOnLeft && deltaPosition.dx > 0) {
      _relativeOrigin =
          Offset(rawCursorOffset.dx - leftBound, _relativeOrigin.dy);
      _resetOriginOnLeft = false;
    } else if (_resetOriginOnRight && deltaPosition.dx < 0) {
      _relativeOrigin =
          Offset(rawCursorOffset.dx - rightBound, _relativeOrigin.dy);
      _resetOriginOnRight = false;
    }
    if (_resetOriginOnTop && deltaPosition.dy > 0) {
      _relativeOrigin =
          Offset(_relativeOrigin.dx, rawCursorOffset.dy - topBound);
      _resetOriginOnTop = false;
    } else if (_resetOriginOnBottom && deltaPosition.dy < 0) {
      _relativeOrigin =
          Offset(_relativeOrigin.dx, rawCursorOffset.dy - bottomBound);
      _resetOriginOnBottom = false;
    }

    final currentX = rawCursorOffset.dx - _relativeOrigin.dx;
    final currentY = rawCursorOffset.dy - _relativeOrigin.dy;
    final double adjustedX =
        math.min(math.max(currentX, leftBound), rightBound);
    final double adjustedY =
        math.min(math.max(currentY, topBound), bottomBound);
    final adjustedOffset = Offset(adjustedX, adjustedY);

    if (currentX < leftBound && deltaPosition.dx < 0) {
      _resetOriginOnLeft = true;
    } else if (currentX > rightBound && deltaPosition.dx > 0) {
      _resetOriginOnRight = true;
    }
    if (currentY < topBound && deltaPosition.dy < 0) {
      _resetOriginOnTop = true;
    } else if (currentY > bottomBound && deltaPosition.dy > 0) {
      _resetOriginOnBottom = true;
    }

    _previousOffset = rawCursorOffset;

    return adjustedOffset;
  }

  @override
  void setFloatingCursor(FloatingCursorDragState dragState,
      Offset boundedOffset, TextPosition textPosition,
      {double? resetLerpValue}) {
    if (floatingCursorDisabled) return;

    if (dragState == FloatingCursorDragState.Start) {
      _relativeOrigin = Offset.zero;
      _previousOffset = null;
      _resetOriginOnBottom = false;
      _resetOriginOnTop = false;
      _resetOriginOnRight = false;
      _resetOriginOnBottom = false;
    }
    _floatingCursorOn = dragState != FloatingCursorDragState.End;
    if (_floatingCursorOn) {
      _floatingCursorTextPosition = textPosition;
      final sizeAdjustment = resetLerpValue != null
          ? EdgeInsets.lerp(
              _kFloatingCaretSizeIncrease, EdgeInsets.zero, resetLerpValue)!
          : _kFloatingCaretSizeIncrease;
      final child = childAtPosition(textPosition);
      if (child == null) {
        markNeedsPaint();
        return;
      }
      final caretPrototype =
          child.getCaretPrototype(child.globalToLocalPosition(textPosition));
      _floatingCursorRect =
          sizeAdjustment.inflateRect(caretPrototype).shift(boundedOffset);
      _cursorController
          .setFloatingCursorTextPosition(_floatingCursorTextPosition);
    } else {
      _floatingCursorRect = null;
      _cursorController.setFloatingCursorTextPosition(null);
    }
    markNeedsPaint();
  }

  void _paintFloatingCursor(PaintingContext context, Offset offset) {
    _floatingCursorPainter.paint(context.canvas);
  }

  // End floating cursor

  // Start TextLayoutMetrics implementation

  /// Return a [TextSelection] containing the line of the given [TextPosition].
  @override
  TextSelection getLineAtOffset(TextPosition position) {
    final child = childAtPosition(position);
    if (child == null) return const TextSelection.collapsed(offset: 0);
    final nodeOffset = child.node.offset;
    final localPosition = TextPosition(
        offset: position.offset - nodeOffset, affinity: position.affinity);
    final localLineRange = child.getLineBoundary(localPosition);
    final line = TextRange(
      start: localLineRange.start + nodeOffset,
      end: localLineRange.end + nodeOffset,
    );
    return TextSelection(baseOffset: line.start, extentOffset: line.end);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    final child = childAtPosition(position);
    if (child == null) return const TextRange.collapsed(-1);
    final nodeOffset = child.node.offset;
    final localPosition = TextPosition(
        offset: position.offset - nodeOffset, affinity: position.affinity);
    final localWord = child.getWordBoundary(localPosition);
    return TextRange(
      start: localWord.start + nodeOffset,
      end: localWord.end + nodeOffset,
    );
  }

  /// Returns the TextPosition after moving by the vertical offset.
  TextPosition getTextPositionMoveVertical(
      TextPosition position, double verticalOffset) {
    final offset = _getOffsetForCaret(position);
    if (offset.dx == 0 && offset.dy == 0) return const TextPosition(offset: 0);
    final caretOfs = localToGlobal(offset);
    final newPos = getPositionForOffset(caretOfs.translate(0, verticalOffset));
    if (newPos.offset <= -1) return const TextPosition(offset: 0);
    return newPos;
  }

  /// Returns the TextPosition above the given offset into the text.
  ///
  /// If the offset is already on the first line, the offset of the first
  /// character will be returned.
  @override
  TextPosition getTextPositionAbove(TextPosition position) {
    final child = childAtPosition(position);
    if (child == null) return const TextPosition(offset: -1);
    final localPosition =
        TextPosition(offset: position.offset - child.node.documentOffset);

    var newPosition = child.getPositionAbove(localPosition);

    if (newPosition == null) {
      // There was no text above in the current child, check the direct
      // sibling.
      final sibling = childBeforeNode(child.node);
      if (sibling == null) {
        // reached beginning of the document, move to the
        // first character
        newPosition = const TextPosition(offset: 0);
      } else {
        SelectableMixin? sibling2;
        for (final node in container.children) {
          if (node.renderBox! == sibling.renderBox) {
            sibling2 = node.selectable;
          }
        }
        if (sibling2 == null) return TextPosition(offset: document.length - 1);
        final caretOffset = child.getOffsetForCaretByPosition(localPosition);
        final testPosition = TextPosition(offset: sibling2.node.length - 1);
        final testOffset = sibling2.getOffsetForCaretByPosition(testPosition);
        final finalOffset = Offset(caretOffset.dx, testOffset.dy);
        final siblingPosition = sibling2.getPositionForOffset(finalOffset);
        newPosition = TextPosition(
            offset: sibling2.node.documentOffset + siblingPosition.offset);
      }
    } else {
      newPosition =
          TextPosition(offset: child.node.documentOffset + newPosition.offset);
    }
    return newPosition;
  }

  /// Returns the TextPosition below the given offset into the text.
  ///
  /// If the offset is already on the last line, the offset of the last
  /// character will be returned.
  @override
  TextPosition getTextPositionBelow(TextPosition position) {
    final child = childAtPosition(position);
    if (child == null) return const TextPosition(offset: -1);
    final localPosition = TextPosition(
      offset: position.offset - child.node.documentOffset,
    );

    var newPosition = child.getPositionBelow(localPosition);

    if (newPosition == null) {
      // There was no text below in the current child, check the direct sibling.
      final sibling = childAfterNode(child.node);
      if (sibling == null) {
        // reached end of the document, move to the
        // last character
        newPosition = TextPosition(offset: document.length - 1);
      } else {
        SelectableMixin? sibling2;
        for (var index = container.children.length - 1; index >= 0; index--) {
          final node = container.children.elementAt(index);
          if (node.renderBox! == sibling.renderBox) {
            sibling2 = node.selectable;
          }
        }
        if (sibling2 == null) return TextPosition(offset: document.length - 1);
        final caretOffset = child.getOffsetForCaretByPosition(localPosition);
        const testPosition = TextPosition(offset: 0);
        final testOffset = sibling2.getOffsetForCaretByPosition(testPosition);
        final finalOffset = Offset(caretOffset.dx, testOffset.dy);
        final siblingPosition = sibling2.getPositionForOffset(finalOffset);
        newPosition = TextPosition(
          offset: sibling2.node.documentOffset + siblingPosition.offset,
        );
      }
    } else {
      newPosition = TextPosition(
        offset: child.node.documentOffset + newPosition.offset,
      );
    }
    return newPosition;
  }

  // End TextLayoutMetrics implementation

  QuillVerticalCaretMovementRun startVerticalCaretMovement(
      TextPosition startPosition) {
    return QuillVerticalCaretMovementRun._(
      this,
      startPosition,
    );
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    markNeedsLayout();
  }
}

class QuillVerticalCaretMovementRun implements Iterator<TextPosition> {
  QuillVerticalCaretMovementRun._(
    this._editor,
    this._currentTextPosition,
  );

  TextPosition _currentTextPosition;

  final RenderEditor _editor;

  @override
  TextPosition get current {
    return _currentTextPosition;
  }

  @override
  bool moveNext() {
    final position = _editor.getTextPositionBelow(_currentTextPosition);
    if (position.offset <= -1) return false;
    _currentTextPosition = position;
    return true;
  }

  bool movePrevious() {
    final position = _editor.getTextPositionAbove(_currentTextPosition);
    if (position.offset <= -1) return false;
    _currentTextPosition = position;
    return true;
  }

  void moveVertical(double verticalOffset) {
    final position = _editor.getTextPositionMoveVertical(
        _currentTextPosition, verticalOffset);
    if (position.offset <= -1) return;
    _currentTextPosition = position;
    return;
  }
}
