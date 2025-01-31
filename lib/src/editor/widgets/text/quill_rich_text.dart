import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../flutter_quill.dart';
import '../../../common/utils/color.dart';
import '../../../common/utils/font.dart';
import '../../../common/utils/platform.dart';
import '../../../document/nodes/container.dart';
import '../../../document/nodes/leaf.dart' as leaf;
import '../../selection/selectable_mixin.dart';
import '../../selection/widgets/selectable_node_widget.dart';
import '../delegate.dart';
import '../keyboard_listener.dart';
import '../proxy.dart';

class QuillRichText extends StatefulWidget {
  const QuillRichText({
    required GlobalKey key,
    required this.node,
    required this.embedBuilder,
    required this.styles,
    required this.readOnly,
    required this.controller,
    required this.onLaunchUrl,
    required this.linkActionPicker,
    required this.composingRange,
    required this.cursorCont,
    required this.hasFocus,
    required this.horizontalSpacing,
    required this.verticalSpacing,
    this.parent,
    this.scrollBottomInset = 0.0,
    this.textDirection,
    this.customStyleBuilder,
    this.customRecognizerBuilder,
    this.customLinkPrefixes = const <String>[],
  }) : super(key: key);

  final Node node;
  // this is the parent, and should be passed
  // when the block is a Header or a Embed
  // only, because it contains only QuillText nodes instead Lines
  final QuillContainer? parent;
  final TextDirection? textDirection;
  final EmbedsBuilder embedBuilder;
  final CursorCont cursorCont;
  final HorizontalSpacing horizontalSpacing;
  final VerticalSpacing verticalSpacing;
  final DefaultStyles styles;
  final bool readOnly;
  final bool hasFocus;
  final double scrollBottomInset;
  final QuillController controller;
  final CustomStyleBuilder? customStyleBuilder;
  final CustomRecognizerBuilder? customRecognizerBuilder;
  final ValueChanged<String>? onLaunchUrl;
  final LinkActionPicker linkActionPicker;
  final List<String> customLinkPrefixes;
  final TextRange composingRange;

  @override
  State<QuillRichText> createState() => _QuillRichTextState();
}

class _QuillRichTextState extends State<QuillRichText>
    with SelectableMixin<QuillRichText> {
  bool _metaOrControlPressed = false;

  QuillPressedKeys? _pressedKeys;

  final _linkRecognizers = <Node, GestureRecognizer>{};

  late final GlobalKey richTextKey =
      GlobalKey(debugLabel: 'quill_rich_text:${node.hashCode}');

  RenderParagraph? get paragraph =>
      richTextKey.currentContext?.findRenderObject() as RenderParagraph?;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    /* if (widget.node.hasEmbed && widget.node.childCount == 1) {
      // Single child embeds can be expanded
      var embed = widget.node.children.single as Embed;
      // Creates correct node for custom embed
      if (embed.value.type == BlockEmbed.customType) {
        embed = Embed(
          CustomBlockEmbed.fromJsonString(embed.value.data),
        );
      }
      final embedBuilder = widget.embedBuilder(embed);
      if (embedBuilder.expanded) {
        // Creates correct node for custom embed
        final lineStyle = _getLineStyle(widget.styles);
        return EmbedProxy(
          embedBuilder.build(
            context,
            EmbedContext(
              controller: widget.controller,
              node: embed,
              readOnly: widget.readOnly,
              inline: false,
              textStyle: lineStyle,
            ),
          ),
        );
      }
    }
    */
    final textSpan = _getTextSpanForWholeLine();
    final strutStyle =
        StrutStyle.fromTextStyle(textSpan.style ?? const TextStyle());
    final textAlign = _getTextAlign();
    // selectable node is encharged of the manage selection changes
    return SelectableNodeWidget(
      delegate: this,
      selection: widget.controller.listenableSelection,
      container: node,
      cursorCont: widget.cursorCont,
      hasFocus: widget.hasFocus,
      child: RichText(
        key: richTextKey,
        text: textSpan,
        textAlign: textAlign,
        textDirection: widget.textDirection,
        strutStyle: strutStyle,
        textScaler: MediaQuery.textScalerOf(context),
      ),
    );
  }

  InlineSpan _getTextSpanForWholeLine() {
    var lineStyle = _getLineStyle(widget.styles);
    final node = widget.node;
    if ((node is Line && node.hasEmbed) ||
        (node is Leaf && node.value is! String)) {
      return _buildTextSpan(
        widget.styles,
        node is QuillContainer ? node.children : LinkedList<Node>()
          ..add(node),
        lineStyle,
      );
    }

    // The line could contain more than one Embed & more than one Text
    final textSpanChildren = <InlineSpan>[];
    var textNodes = LinkedList<Node>();
    for (var child in node is QuillContainer ? node.children : [node]) {
      if (child is Embed) {
        if (textNodes.isNotEmpty) {
          textSpanChildren
              .add(_buildTextSpan(widget.styles, textNodes, lineStyle));
          textNodes = LinkedList<Node>();
        }
        // Creates correct node for custom embed
        if (child.value.type == BlockEmbed.customType) {
          child = Embed(CustomBlockEmbed.fromJsonString(child.value.data))
            ..applyStyle(child.style);
        }

        if (child.value.type == BlockEmbed.formulaType) {
          lineStyle = lineStyle.merge(_getInlineTextStyle(
            child.style,
            widget.styles,
            widget.node.style,
            false,
          ));
        }

        final embedBuilder = widget.embedBuilder(child);
        final embedWidget = EmbedProxy(
          embedBuilder.build(
            context,
            EmbedContext(
              controller: widget.controller,
              node: child,
              readOnly: widget.readOnly,
              inline: true,
              textStyle: lineStyle,
            ),
          ),
        );
        final embed = embedBuilder.buildWidgetSpan(embedWidget);
        textSpanChildren.add(embed);
        continue;
      }

      // here child is Text node and its value is cloned
      textNodes.add(child.clone());
    }

    if (textNodes.isNotEmpty) {
      textSpanChildren.add(_buildTextSpan(widget.styles, textNodes, lineStyle));
    }

    return TextSpan(style: lineStyle, children: textSpanChildren);
  }

  TextAlign _getTextAlign() {
    final alignment = widget.node.style.attributes[Attribute.align.key];
    if (alignment == Attribute.leftAlignment) {
      return TextAlign.start;
    } else if (alignment == Attribute.centerAlignment) {
      return TextAlign.center;
    } else if (alignment == Attribute.rightAlignment) {
      return TextAlign.end;
    } else if (alignment == Attribute.justifyAlignment) {
      return TextAlign.justify;
    }
    return TextAlign.start;
  }

  TextSpan _buildTextSpan(
    DefaultStyles defaultStyles,
    LinkedList<Node> nodes,
    TextStyle lineStyle,
  ) {
    if (nodes.isEmpty && kIsWeb) {
      nodes = LinkedList<Node>()..add(leaf.QuillText('\u{200B}'));
    }

    final isComposingRangeOutOfLine = isDesktop
        ? true
        : !widget.composingRange.isValid ||
            widget.composingRange.isCollapsed ||
            (widget.composingRange.start < widget.node.documentOffset ||
                widget.composingRange.end >
                    widget.node.documentOffset + widget.node.length);

    if (isComposingRangeOutOfLine) {
      final children = nodes
          .map((node) =>
              _getTextSpanFromNode(defaultStyles, node, widget.node.style))
          .toList(growable: false);
      return TextSpan(children: children, style: lineStyle);
    }

    final children = nodes.expand((node) {
      final child =
          _getTextSpanFromNode(defaultStyles, node, widget.node.style);
      final isNodeInComposingRange =
          node.documentOffset <= widget.composingRange.start &&
              widget.composingRange.end <= node.documentOffset + node.length;
      if (isNodeInComposingRange) {
        return _splitAndApplyComposingStyle(node, child);
      } else {
        return [child];
      }
    }).toList(growable: false);

    return TextSpan(children: children, style: lineStyle);
  }

  // split the text nodes into composing and non-composing nodes
  // and apply the composing style to the composing nodes
  List<InlineSpan> _splitAndApplyComposingStyle(Node node, InlineSpan child) {
    assert(widget.composingRange.isValid && !widget.composingRange.isCollapsed);

    final composingStart = widget.composingRange.start - node.documentOffset;
    final composingEnd = widget.composingRange.end - node.documentOffset;
    final text = child.toPlainText();

    final textBefore = text.substring(0, composingStart);
    final textComposing = text.substring(composingStart, composingEnd);
    final textAfter = text.substring(composingEnd);

    final composingStyle = child.style
            ?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
        const TextStyle(decoration: TextDecoration.underline);

    return [
      TextSpan(
        text: textBefore,
        style: child.style,
      ),
      TextSpan(
        text: textComposing,
        style: composingStyle,
      ),
      TextSpan(
        text: textAfter,
        style: child.style,
      ),
    ];
  }

  TextStyle _getLineStyle(DefaultStyles defaultStyles) {
    var textStyle = const TextStyle();

    if (widget.node.style.containsKey(Attribute.placeholder.key)) {
      return defaultStyles.placeHolder!.style;
    }

    final header = widget.node.style.attributes[Attribute.header.key];
    final m = <Attribute, TextStyle>{
      Attribute.h1: defaultStyles.h1!.style,
      Attribute.h2: defaultStyles.h2!.style,
      Attribute.h3: defaultStyles.h3!.style,
      Attribute.h4: defaultStyles.h4!.style,
      Attribute.h5: defaultStyles.h5!.style,
      Attribute.h6: defaultStyles.h6!.style,
    };

    textStyle = textStyle.merge(m[header] ?? defaultStyles.paragraph!.style);

    // Only retrieve exclusive block format for the line style purpose
    Attribute? block;
    widget.node.style.getBlocksExceptHeader().forEach((key, value) {
      if (Attribute.exclusiveBlockKeys.contains(key)) {
        block = value;
      }
    });

    TextStyle? toMerge;
    if (block == Attribute.blockQuote) {
      toMerge = defaultStyles.quote!.style;
    } else if (block == Attribute.codeBlock) {
      toMerge = defaultStyles.code!.style;
    } else if (block?.key == Attribute.list.key) {
      toMerge = defaultStyles.lists!.style;
    }

    textStyle = textStyle.merge(toMerge);

    final lineHeight = widget.node.style.attributes[Attribute.lineHeight.key];
    final x = <Attribute, TextStyle>{
      LineHeightAttribute.lineHeightNormal:
          defaultStyles.lineHeightNormal!.style,
      LineHeightAttribute.lineHeightTight: defaultStyles.lineHeightTight!.style,
      LineHeightAttribute.lineHeightOneAndHalf:
          defaultStyles.lineHeightOneAndHalf!.style,
      LineHeightAttribute.lineHeightDouble:
          defaultStyles.lineHeightDouble!.style,
    };

    // If the lineHeight attribute isn't null, then get just the height param instead whole TextStyle
    // to avoid modify the current style of the text line
    textStyle =
        textStyle.merge(textStyle.copyWith(height: x[lineHeight]?.height));

    textStyle = _applyCustomAttributes(textStyle, widget.node.style.attributes);

    if (isPlaceholderLine) {
      final oldStyle = textStyle;
      textStyle = defaultStyles.placeHolder!.style;
      textStyle = textStyle.merge(oldStyle.copyWith(
        color: textStyle.color,
        backgroundColor: textStyle.backgroundColor,
        background: textStyle.background,
      ));
    }

    return textStyle;
  }

  TextStyle _applyCustomAttributes(
      TextStyle textStyle, Map<String, Attribute> attributes) {
    if (widget.customStyleBuilder == null) {
      return textStyle;
    }
    for (final key in attributes.keys) {
      final attr = attributes[key];
      if (attr != null) {
        /// Custom Attribute
        final customAttr = widget.customStyleBuilder!.call(attr);
        textStyle = textStyle.merge(customAttr);
      }
    }
    return textStyle;
  }

  /// Processes subscript and superscript attributed text.
  ///
  /// Reduces text fontSize and shifts down or up. Increases fontWeight to maintain balance with normal text.
  /// Outputs characters individually to allow correct caret positioning and text selection.
  InlineSpan _scriptSpan(String text, bool superScript, TextStyle style,
      DefaultStyles defaultStyles) {
    assert(text.isNotEmpty);
    //
    final lineStyle = style.fontSize == null || style.fontWeight == null
        ? _getLineStyle(defaultStyles)
        : null;
    final fontWeight = FontWeight.lerp(
        style.fontWeight ?? lineStyle?.fontWeight ?? FontWeight.normal,
        FontWeight.w900,
        0.25);
    final fontSize = style.fontSize ?? lineStyle?.fontSize ?? 16;
    final y = (superScript ? -0.4 : 0.14) * fontSize;
    final charStyle = style.copyWith(
        fontFeatures: <FontFeature>[],
        fontWeight: fontWeight,
        fontSize: fontSize * 0.7);
    //
    final offset = Offset(0, y);
    final children = <WidgetSpan>[];
    for (final c in text.characters) {
      children.add(
        WidgetSpan(
          child: Transform.translate(
            offset: offset,
            child: Text(
              c,
              style: charStyle,
            ),
          ),
        ),
      );
    }
    //
    if (children.length > 1) {
      return TextSpan(children: children);
    }
    return children.first;
  }

  InlineSpan _getTextSpanFromNode(
      DefaultStyles defaultStyles, Node node, Style lineStyle) {
    final textNode = node as leaf.QuillText;
    final nodeStyle = textNode.style;
    final isLink = nodeStyle.containsKey(Attribute.link.key) &&
        nodeStyle.attributes[Attribute.link.key]!.value != null;
    final style =
        _getInlineTextStyle(nodeStyle, defaultStyles, lineStyle, isLink);
    if (widget.controller.config.requireScriptFontFeatures == false &&
        textNode.value.isNotEmpty) {
      if (nodeStyle.containsKey(Attribute.script.key)) {
        final attr = nodeStyle.attributes[Attribute.script.key];
        if (attr == Attribute.superscript || attr == Attribute.subscript) {
          return _scriptSpan(textNode.value, attr == Attribute.superscript,
              style, defaultStyles);
        }
      }
    }

    final recognizer = _getRecognizer(node, isLink);
    return TextSpan(
      text: textNode.value,
      style: style,
      recognizer: recognizer,
      mouseCursor: (recognizer != null) ? SystemMouseCursors.click : null,
    );
  }

  TextStyle _getInlineTextStyle(Style nodeStyle, DefaultStyles defaultStyles,
      Style lineStyle, bool isLink) {
    var res = const TextStyle(); // This is inline text style
    final color = nodeStyle.attributes[Attribute.color.key];

    <String, TextStyle?>{
      Attribute.bold.key: defaultStyles.bold,
      Attribute.italic.key: defaultStyles.italic,
      Attribute.small.key: defaultStyles.small,
      Attribute.link.key: defaultStyles.link,
      Attribute.underline.key: defaultStyles.underline,
      Attribute.strikeThrough.key: defaultStyles.strikeThrough,
    }.forEach((k, s) {
      if (nodeStyle.values.any((v) => v.key == k)) {
        if (k == Attribute.underline.key || k == Attribute.strikeThrough.key) {
          var textColor = defaultStyles.color;
          if (color?.value is String) {
            textColor = stringToColor(color?.value, textColor, defaultStyles);
          }
          res = _merge(res.copyWith(decorationColor: textColor),
              s!.copyWith(decorationColor: textColor));
        } else if (k == Attribute.link.key && !isLink) {
          // null value for link should be ignored
          // i.e. nodeStyle.attributes[Attribute.link.key]!.value == null
        } else {
          res = _merge(res, s!);
        }
      }
    });

    if (nodeStyle.containsKey(Attribute.script.key)) {
      if (nodeStyle.attributes.values.contains(Attribute.subscript)) {
        res = _merge(res, defaultStyles.subscript!);
      } else if (nodeStyle.attributes.values.contains(Attribute.superscript)) {
        res = _merge(res, defaultStyles.superscript!);
      }
    }

    if (nodeStyle.containsKey(Attribute.inlineCode.key)) {
      res = _merge(res, defaultStyles.inlineCode!.styleFor(lineStyle));
    }

    final font = nodeStyle.attributes[Attribute.font.key];
    if (font != null && font.value != null) {
      res = res.merge(TextStyle(fontFamily: font.value));
    }

    final size = nodeStyle.attributes[Attribute.size.key];
    if (size != null && size.value != null) {
      switch (size.value) {
        case 'small':
          res = res.merge(defaultStyles.sizeSmall);
          break;
        case 'large':
          res = res.merge(defaultStyles.sizeLarge);
          break;
        case 'huge':
          res = res.merge(defaultStyles.sizeHuge);
          break;
        default:
          res = res.merge(TextStyle(
            fontSize: getFontSize(
              size.value,
            ),
          ));
      }
    }

    if (color != null && color.value != null) {
      var textColor = defaultStyles.color;
      if (color.value is String) {
        textColor = stringToColor(color.value, null, defaultStyles);
      }
      if (textColor != null) {
        res = res.merge(TextStyle(color: textColor));
      }
    }

    final background = nodeStyle.attributes[Attribute.background.key];
    if (background != null && background.value != null) {
      final backgroundColor =
          stringToColor(background.value, null, defaultStyles);
      res = res.merge(TextStyle(backgroundColor: backgroundColor));
    }

    res = _applyCustomAttributes(res, nodeStyle.attributes);
    return res;
  }

  GestureRecognizer? _getRecognizer(Node segment, bool isLink) {
    if (_linkRecognizers.containsKey(segment)) {
      return _linkRecognizers[segment]!;
    }

    if (widget.customRecognizerBuilder != null) {
      final textNode = segment as leaf.QuillText;
      final nodeStyle = textNode.style;

      nodeStyle.attributes.forEach((key, value) {
        final recognizer = widget.customRecognizerBuilder!.call(value, segment);
        if (recognizer != null) {
          _linkRecognizers[segment] = recognizer;
          return;
        }
      });
    }

    if (_linkRecognizers.containsKey(segment)) {
      return _linkRecognizers[segment]!;
    }

    if (isLink && canLaunchLinks) {
      if (isDesktop || widget.readOnly) {
        _linkRecognizers[segment] = TapGestureRecognizer()
          ..onTap = () => _tapNodeLink(segment);
      } else {
        _linkRecognizers[segment] = LongPressGestureRecognizer()
          ..onLongPress = () => _longPressLink(segment);
      }
    }
    return _linkRecognizers[segment];
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  void _tapNodeLink(Node node) {
    final link = node.style.attributes[Attribute.link.key]!.value;

    _tapLink(link);
  }

  void _tapLink(String? link) {
    if (link == null) {
      return;
    }

    var launchUrl = widget.onLaunchUrl;
    launchUrl ??= _launchUrl;

    link = link.trim();
    if (!(widget.customLinkPrefixes + linkPrefixes)
        .any((linkPrefix) => link!.toLowerCase().startsWith(linkPrefix))) {
      link = 'https://$link';
    }
    launchUrl(link);
  }

  Future<void> _longPressLink(Node node) async {
    final link = node.style.attributes[Attribute.link.key]!.value!;
    final action = await widget.linkActionPicker(node);
    switch (action) {
      case LinkMenuAction.launch:
        _tapLink(link);
        break;
      case LinkMenuAction.copy:
        Clipboard.setData(ClipboardData(text: link));
        break;
      case LinkMenuAction.remove:
        final range = getLinkRange(node);
        widget.controller
            .formatText(range.start, range.end - range.start, Attribute.link);
        break;
      case LinkMenuAction.none:
        break;
    }
  }

  TextStyle _merge(TextStyle a, TextStyle b) {
    final decorations = <TextDecoration?>[];
    if (a.decoration != null) {
      decorations.add(a.decoration);
    }
    if (b.decoration != null) {
      decorations.add(b.decoration);
    }
    return a.merge(b).apply(
        decoration: TextDecoration.combine(
            List.castFrom<dynamic, TextDecoration>(decorations)));
  }

  void _pressedKeysChanged() {
    final newValue = _pressedKeys!.metaPressed || _pressedKeys!.controlPressed;
    if (_metaOrControlPressed != newValue) {
      setState(() {
        _metaOrControlPressed = newValue;
        _linkRecognizers
          ..forEach((key, value) {
            value.dispose();
          })
          ..clear();
      });
    }
  }

  bool get canLaunchLinks {
    // In readOnly mode users can launch links
    // by simply tapping (clicking) on them
    if (widget.readOnly) return true;

    // In editing mode it depends on the platform:

    // Desktop platforms (macOS, Linux, Windows):
    // only allow Meta (Control) + Click combinations
    if (isDesktopApp) {
      return _metaOrControlPressed;
    }
    // Mobile platforms (ios, android): always allow but we install a
    // long-press handler instead of a tap one. LongPress is followed by a
    // context menu with actions.
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pressedKeys == null) {
      _pressedKeys = QuillPressedKeys.of(context);
      _pressedKeys!.addListener(_pressedKeysChanged);
    } else {
      _pressedKeys!.removeListener(_pressedKeysChanged);
      _pressedKeys = QuillPressedKeys.of(context);
      _pressedKeys!.addListener(_pressedKeysChanged);
    }
  }

  @override
  void didUpdateWidget(covariant QuillRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readOnly != widget.readOnly) {
      _linkRecognizers
        ..forEach((key, value) {
          value.dispose();
        })
        ..clear();
    }
  }

  @override
  void dispose() {
    _pressedKeys?.removeListener(_pressedKeysChanged);
    _linkRecognizers
      ..forEach((key, value) => value.dispose())
      ..clear();
    super.dispose();
  }

  /// Check if this line contains the placeholder attribute
  bool get isPlaceholderLine =>
      widget.node.toDelta().first.attributes?.containsKey('placeholder') ??
      false;

  @override
  QuillContainer get node => widget.node is! QuillContainer
      ? widget.parent!
      : widget.node as QuillContainer;

  // selectable mixin implementation

  TextPainter get prototypePainter {
    TextPainter? painter;
    final styles = _getLineStyle(widget.styles);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      painter = TextPainter(
        text: TextSpan(text: ' ', style: styles),
        textAlign: _getTextAlign(),
        textDirection: widget.textDirection,
        textScaler: MediaQuery.textScalerOf(context),
        strutStyle: StrutStyle.fromTextStyle(styles),
        locale: Localizations.localeOf(context),
        textWidthBasis: TextWidthBasis.parent,
        textHeightBehavior: null,
      );
    });
    return painter ??
        TextPainter(
          text: TextSpan(text: ' ', style: styles),
          textAlign: _getTextAlign(),
          textDirection: widget.textDirection,
          strutStyle: StrutStyle.fromTextStyle(styles),
        );
  }

  @override
  double get preferredLineHeight => prototypePainter.preferredLineHeight;

  @override
  double preferredLineHeightByPosition(TextPosition position) {
    return preferredLineHeight;
  }

  @override
  Offset getOffsetForCaretByPosition(TextPosition position) {
    if (caretPrototype == null) computeCaretPrototype();
    return getOffsetForCaret(position, caretPrototype!);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    // parsing the global offset to local, fix weird behavior
    // in selection actions
    final baseOffset = paragraph?.globalToLocal(offset) ?? Offset.zero;
    return paragraph?.getPositionForOffset(baseOffset) ??
        const TextPosition(
          offset: 0,
        );
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return paragraph?.getWordBoundary(position) ??
        const TextRange(start: 0, end: 0);
  }

  @override
  List<TextBox> getBoxesForSelection(TextSelection textSelection) {
    return paragraph?.getBoxesForSelection(textSelection) ?? [];
  }

  @override
  double? getFullHeightForCaret(TextPosition position) {
    //TODO: create a kCaretHeight
    return paragraph?.getFullHeightForCaret(position) ?? 0;
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    //TODO: fix this method too
    return paragraph?.getOffsetForCaret(
          position,
          caretPrototype,
        ) ??
        const Offset(0, 0);
  }

  @override
  TextPosition globalToLocalPosition(TextPosition position) {
    assert(node.containsOffset(position.offset),
        'The provided text position is not in the current node');
    return TextPosition(
      offset: position.offset - node.documentOffset,
      affinity: position.affinity,
    );
  }

  @override
  Rect getCaretPrototype(TextPosition position) {
    if (caretPrototype == null) {
      computeCaretPrototype();
    }
    return caretPrototype!;
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    if (caretPrototype == null) computeCaretPrototype();
    final caretOffset =
        paragraph?.getOffsetForCaret(position, caretPrototype!) ?? Offset.zero;
    var rect = Rect.fromLTWH(
      max(0, caretOffset.dx - (cursorWidth / 2.0)),
      caretOffset.dy,
      cursorWidth,
      cursorHeight,
    );
    final cursorOffset = cursorCont.style.offset;
    // Add additional cursor offset (generally only if on iOS).
    if (cursorOffset != null) rect = rect.shift(cursorOffset);
    return rect;
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    final lineDy = getOffsetForCaretByPosition(position)
        .translate(
          0,
          0.5 *
              preferredLineHeightByPosition(
                position,
              ),
        )
        .dy;
    final lineBoxes = getBoxes(
      TextSelection(baseOffset: 0, extentOffset: node.length - 1),
    )
        .where(
          (element) => element.top < lineDy && element.bottom > lineDy,
        )
        .toList(growable: false);
    return TextRange(
        start: getPositionForOffset(
          Offset(lineBoxes.first.left, lineDy),
        ).offset,
        end: getPositionForOffset(
          Offset(lineBoxes.last.right, lineDy),
        ).offset);
  }

  List<TextBox> getBoxes(TextSelection textSelection) {
    final parentData = renderBox!.parentData;
    var parentOffset = Offset.zero;
    if (parentData is BoxParentData) {
      parentOffset = parentData.offset;
    }
    final boxes = getBoxesForSelection(textSelection).map((box) {
      return TextBox.fromLTRBD(
        box.left + parentOffset.dx,
        box.top + parentOffset.dy,
        box.right + parentOffset.dx,
        box.bottom + parentOffset.dy,
        box.direction,
      );
    }).toList(growable: false);
    if (boxes.isEmpty) {
      return [
        TextBox.fromLTRBD(
          0,
          0,
          1,
          paragraph?.size.height ?? 0,
          widget.textDirection ?? Directionality.of(context),
        ),
      ];
    }
    return boxes;
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection) {
    return _getEndpointForSelection(textSelection, true);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(
      TextSelection textSelection) {
    return _getEndpointForSelection(
      textSelection,
      false,
    );
  }

  TextSelectionPoint _getEndpointForSelection(
    TextSelection textSelection,
    bool first,
  ) {
    if (textSelection.isCollapsed) {
      return TextSelectionPoint(
        Offset(0, preferredLineHeight) +
            getOffsetForCaretByPosition(
              textSelection.extent,
            ),
        context.mounted ? Directionality.of(context) : TextDirection.ltr,
      );
    }
    final boxes = getBoxes(textSelection);
    assert(boxes.isNotEmpty);
    final targetBox = first ? boxes.first : boxes.last;
    return TextSelectionPoint(
      Offset(first ? targetBox.start : targetBox.end, targetBox.bottom),
      targetBox.direction,
    );
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    double? maxOffset;
    double limit() => maxOffset ??= renderBox!.semanticBounds.height /
            preferredLineHeightByPosition(position) +
        1;
    // ?
    bool checkLimit(double offset) => offset < 4.0 ? false : offset > limit();

    /// Move up by fraction of the default font height, larger font sizes need larger offset, embed images need larger offset
    for (var offset = 0.5;; offset += offset < 4 ? 0.25 : 1.0) {
      final pos = _getPosition(position, -offset);
      if (pos?.offset != position.offset || checkLimit(offset)) {
        return pos;
      }
    }
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    return _getPosition(position, 1.5);
  }

  TextPosition? _getPosition(TextPosition textPosition, double dyScale) {
    assert(textPosition.offset < node.length);
    final body = renderBox;
    final offset = getOffsetForCaretByPosition(textPosition)
        .translate(0, dyScale * preferredLineHeightByPosition(textPosition));
    if (body!.size.contains(offset)) {
      return getPositionForOffset(offset);
    }
    return null;
  }

  // TODO: This is no longer producing the highest-fidelity caret
  // heights for Android, especially when non-alphabetic languages
  // are involved. The current implementation overrides the height set
  // here with the full measured height of the text on Android which looks
  // superior (subjectively and in terms of fidelity) in _paintCaret. We
  // should rework this properly to once again match the platform. The constant
  // _kCaretHeightOffset scales poorly for small font sizes.
  @override
  void computeCaretPrototype() {
    setCaretPrototype = isIos
        ? Rect.fromLTWH(0, 0, cursorWidth, cursorHeight + 2)
        : Rect.fromLTWH(0, 2, cursorWidth, cursorHeight - 4.0);
  }

  CursorCont get cursorCont => widget.cursorCont;

  double get cursorHeight =>
      cursorCont.style.height ??
      preferredLineHeightByPosition(
        const TextPosition(offset: 0),
      );

  double get cursorWidth => cursorCont.style.width;

  @override
  GlobalKey<State<StatefulWidget>> get forwardKey => GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get componentKey => GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;
}
