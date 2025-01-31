import '../../../../quill_delta.dart';
import 'container.dart';
import 'line.dart';
import 'node.dart';

/// Represents a group of adjacent [Line]s with the same block style.
///
/// Block elements are:
/// - Blockquote
/// - Header
/// - Indent
/// - List
/// - Text Alignment
/// - Text Direction
/// - Code Block
base class Block extends QuillContainer<Line?> {
  /// Creates new unmounted [Block].
  @override
  Node newInstance() => Block();

  @override
  Line get defaultChild => Line();

  @override
  Delta toDelta() {
    // Line nodes take care of incorporating block style into their delta.
    return children
        .map((child) => child.toDelta())
        .fold(Delta(), (a, b) => a.concat(b));
  }

  @override
  void adjust() {
    if (isEmpty) {
      final sibling = previous;
      unlink();
      if (sibling != null) {
        sibling
          ..adjust()
          ..notify();
        notify();
      }
      return;
    }

    var block = this;
    final prev = block.previous;
    // merging it with previous block if style is the same
    if (!block.isFirst &&
        block.previous is Block &&
        prev!.style == block.style) {
      block
        ..moveChildToNewParent(prev as QuillContainer<Node?>?)
        ..unlink();
      block = prev as Block..notify();
      notify();
    }
    final next = block.next;
    // merging it with next block if style is the same
    if (!block.isLast && block.next is Block && next!.style == block.style) {
      (next as Block).moveChildToNewParent(block);
      next.unlink();
    }
    notify();
  }

  @override
  String toString() {
    final block = style.attributes.toString();
    final buffer = StringBuffer('§ {$block}\n');
    for (final child in children) {
      final tree = child.isLast ? '└' : '├';
      buffer.write('  $tree $child');
      if (!child.isLast) buffer.writeln();
    }
    return buffer.toString();
  }
}
