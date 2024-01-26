import 'package:flutter/widgets.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

abstract class TargetFocus {
  TargetFocus({
    this.identify,
    this.contents,
    this.shape,
    this.radius,
    this.borderSide,
    this.color,
    this.enableOverlayTab = false,
    this.enableTargetTab = true,
    this.alignSkip,
    this.paddingFocus,
    this.focusAnimationDuration,
    this.unFocusAnimationDuration,
    this.pulseVariation,
  });

  final dynamic identify;
  final List<TargetContent>? contents;
  final ShapeLightFocus? shape;
  final double? radius;
  final BorderSide? borderSide;
  final bool enableOverlayTab;
  final bool enableTargetTab;
  final Color? color;
  final AlignmentGeometry? alignSkip;
  final double? paddingFocus;
  final Duration? focusAnimationDuration;
  final Duration? unFocusAnimationDuration;
  final Tween<double>? pulseVariation;

  TargetPosition? findPosition({
    bool rootOverlay = false,
  });

  @override
  String toString() {
    return 'TargetFocus{identify: $identify, contents: $contents, shape: $shape}';
  }
}

class ResolverBasedActionableTargetFocus extends ActionableTargetFocus {
  ResolverBasedActionableTargetFocus({
    super.identify,
    super.contents,
    super.shape,
    super.radius,
    super.borderSide,
    super.color,
    super.enableOverlayTab = false,
    super.enableTargetTab = true,
    super.alignSkip,
    super.paddingFocus,
    super.focusAnimationDuration,
    super.unFocusAnimationDuration,
    super.pulseVariation,
    super.onInit,
    super.onPre,
    super.onPost,
    required this.targetResolver,
  });

  TargetPositionResolver targetResolver;

  @override
  TargetPosition? findPosition({bool rootOverlay = false}) =>
      targetResolver.resolve(
        rootOverlay: rootOverlay,
      );
}

abstract class ActionableTargetFocus extends TargetFocus
    implements InitActionTarget, PreActionTarget, PostActionTarget {
  ActionableTargetFocus({
    super.identify,
    super.contents,
    super.shape,
    super.radius,
    super.borderSide,
    super.color,
    super.enableOverlayTab = false,
    super.enableTargetTab = true,
    super.alignSkip,
    super.paddingFocus,
    super.focusAnimationDuration,
    super.unFocusAnimationDuration,
    super.pulseVariation,
    this.onInit,
    this.onPre,
    this.onPost,
  });

  Future<bool> Function()? onInit;
  Future<void> Function()? onPre;
  Future<void> Function()? onPost;

  @override
  Future<void> pre() async {
    if (onPre != null) {
      await onPre!.call();
    }
  }

  @override
  Future<void> post() async {
    if (onPost != null) {
      await onPost!.call();
    }
  }

  @override
  Future<bool> init() async {
    if (onInit != null) {
      return await onInit!.call();
    }
    return true;
  }
}
