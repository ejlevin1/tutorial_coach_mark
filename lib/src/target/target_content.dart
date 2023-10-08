import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../tutorial_coach_mark.dart';

class CustomTargetContentPosition {
  CustomTargetContentPosition({
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double? top, left, right, bottom;

  @override
  String toString() {
    return 'CustomTargetPosition{top: $top, left: $left, right: $right, bottom: $bottom}';
  }
}

enum ContentAlign { top, bottom, left, right, custom }

typedef TargetContentBuilder = Widget Function(
  BuildContext context,
  TutorialCoachMarkController controller,
);

class TargetContent {
  TargetContent({
    this.align = ContentAlign.bottom,
    this.padding = const EdgeInsets.all(20.0),
    this.child,
    this.customPosition,
    this.builder,
    ContentAlign Function(BuildContext context, TargetPosition targetPosition)?
        calculateAlignment,
  })  : assert(!(align == ContentAlign.custom && customPosition == null)),
        _calcAlignment = calculateAlignment ?? createDefaultAlignmentFn(align);

  static ContentAlign Function(
          BuildContext context, TargetPosition targetPosition)
      createDefaultAlignmentFn(ContentAlign align) {
    return (BuildContext context, TargetPosition targetPosition) {
      return align;
    };
  }

  final ContentAlign align;
  final EdgeInsets padding;
  final CustomTargetContentPosition? customPosition;
  final Widget? child;
  final TargetContentBuilder? builder;
  final ContentAlign Function(
      BuildContext context, TargetPosition targetPosition) _calcAlignment;

  ContentAlign calculateAlignment(
          BuildContext context, TargetPosition targetPosition) =>
      _calcAlignment(context, targetPosition);

  @override
  String toString() {
    return 'ContentTarget{align: $align, child: $child}';
  }
}
