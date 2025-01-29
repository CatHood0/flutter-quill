import 'package:flutter/material.dart';

import '../../../../flutter_quill.dart';
import '../../../document/nodes/container.dart';
import '../selectable_mixin.dart';
import 'selection_node_area_widget.dart';

class SelectableNodeWidget extends StatelessWidget {
  const SelectableNodeWidget({
    required this.selection,
    required this.delegate,
    required this.child,
    required this.container,
    required this.cursorCont,
    required this.hasFocus,
    super.key,
  });

  final QuillContainer container;
  final ValueNotifier<TextSelection> selection;
  final SelectableMixin delegate;
  final CursorCont cursorCont;
  final bool hasFocus;
  //TODO: add selection style
  //should be the selectable node
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      // In RTL mode, if the alignment is topStart,
      //  the selection will be on the opposite side of the block component.
      alignment: Directionality.of(context) == TextDirection.ltr
          ? AlignmentDirectional.topStart
          : AlignmentDirectional.topEnd,
      children: [
        //TODO: at this way we can add remote cursors
        if (cursorCont.style.paintAboveText)
          // block selection or selection area
          SelectionAreaForNodeWidget(
            selection: selection,
            cursorCont: cursorCont,
            hasFocus: hasFocus,
            delegate: delegate,
            container: container,
          ),
        child,
        if (!cursorCont.style.paintAboveText)
          // block selection or selection area
          SelectionAreaForNodeWidget(
            selection: selection,
            cursorCont: cursorCont,
            hasFocus: hasFocus,
            delegate: delegate,
            container: container,
          ),
      ],
    );
  }
}
