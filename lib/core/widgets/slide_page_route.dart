import 'package:flutter/cupertino.dart';

/// The iOS page transition, with swipe-from-the-left-edge to go back.
class SlidePageRoute<T> extends CupertinoPageRoute<T> {
  SlidePageRoute({required Widget page, super.settings}) : super(builder: (_) => page);
}
