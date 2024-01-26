import 'package:flutter/widgets.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

abstract class TargetPositionResolver {
  TargetPosition? resolve({
    bool rootOverlay = false,
  });
}

extension TargetPositionResolverExtensions on TargetPositionResolver {
  GlobalKey? maybeGetGlobalKey() {
    if (this is GlobalKeyTargetResolver) {
      return (this as GlobalKeyTargetResolver).key;
    }
    return null;
  }
}

class CallbackTargetResolver extends TargetPositionResolver {
  CallbackTargetResolver({required this.callback});

  final TargetPosition? Function({
    bool rootOverlay,
  }) callback;

  @override
  TargetPosition? resolve({bool rootOverlay = false}) =>
      callback.call(rootOverlay: rootOverlay);
}

class GlobalKeyTargetResolver extends TargetPositionResolver {
  GlobalKeyTargetResolver({required this.key});

  final GlobalKey key;

  @override
  TargetPosition? resolve({
    bool rootOverlay = false,
  }) {
    var position =
        key.currentContext.getTutorialPosition(rootOverlay: rootOverlay);
    if (position == null) {
      throw NotFoundTargetException();
    }
    return position;
  }
}
