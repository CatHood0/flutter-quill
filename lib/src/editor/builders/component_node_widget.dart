import 'package:flutter/material.dart';

import '../../document/nodes/container.dart';

mixin QuillComponentWidget on Widget {
  QuillContainer get node;
}
