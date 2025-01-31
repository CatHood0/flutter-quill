import '../blockquote_component/blockquote_component.dart';
import '../code_block_component/code_block_component.dart';
import '../component_node_builder.dart';
import '../header_component/header_component.dart';
import '../list_components/checkbox_component.dart';
import '../list_components/ordered_component.dart';
import '../list_components/unordered_component.dart';
import '../paragraph_component/paragraph_component.dart';

final List<QuillComponentBuilder> standardsBuilders = List.unmodifiable(
  [
    HeaderComponent(),
    ListOrderedComponent(),
    ListUnorderedComponent(),
    CheckBoxComponent(),
    CodeBlockComponent(),
    BlockquoteComponent(),
    ParagraphComponent(),
  ],
);
