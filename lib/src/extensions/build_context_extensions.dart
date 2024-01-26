import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

extension BuildContextExtensions on BuildContext? {
  TargetPosition? getTutorialPosition({required bool rootOverlay}) {
    if (this == null || !this!.mounted) return null;

    final RenderBox renderBoxRed = this!.findRenderObject() as RenderBox;
    final size = renderBoxRed.size;

    BuildContext? context;
    if (rootOverlay) {
      context = this!.findRootAncestorStateOfType<OverlayState>()?.context;
    } else {
      context = this!.findAncestorStateOfType<NavigatorState>()?.context;
    }
    Offset offset;
    if (context != null) {
      offset = renderBoxRed.localToGlobal(
        Offset.zero,
        ancestor: context.findRenderObject(),
      );
    } else {
      offset = renderBoxRed.localToGlobal(Offset.zero);
    }

    return TargetPosition(size, offset);
  }
}
