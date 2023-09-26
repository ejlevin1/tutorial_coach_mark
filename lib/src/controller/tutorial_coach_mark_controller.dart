import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

abstract class TutorialCoachMarkController extends Listenable {
  Iterable<TargetFocus> get targets;

  void addTargets(Iterable<TargetFocus> targets);
  void removeTargets(Iterable<TargetFocus> targets);
  void setTargets(Iterable<TargetFocus> targets);

  TargetFocus? get currentTarget;
  Animation<double>? get animation;

  bool get isRunning;
  bool get isPaused;
  bool get hasPrevious;
  bool get hasNext;

  Stream<TutorialCoachMarkEvent> get events;

  Future next();
  Future previous();
  Future skip();

  Future start();
  Future pause();
  Future resume();

  TargetFocus? getPrevTarget();
  TargetFocus? getNextTarget();
}

class DefaultTutorialCoachMarkController extends ChangeNotifier
    implements TutorialCoachMarkController {
  static const _defaultFocusAnimationDuration = Duration(milliseconds: 600);

  DefaultTutorialCoachMarkController({
    int index = -1,
    required List<TargetFocus> targets,
    required TickerProvider vsync,
  })  : assert(index >= -1),
        _index = index,
        _targets = targets,
        _paused = false,
        _animationController = AnimationController(
          vsync: vsync,
          duration: _defaultFocusAnimationDuration,
        ),
        _eventsController =
            StreamController<TutorialCoachMarkEvent>.broadcast();

  @override
  Iterable<TargetFocus> get targets => _targets;
  @override
  Animation<double>? get animation => _animationController?.view;

  final List<TargetFocus> _targets;
  AnimationController? _animationController;
  StreamController<TutorialCoachMarkEvent>? _eventsController;

  int get index => _index;
  int _index;

  @override
  bool get isPaused => _paused;
  bool _paused;

  void reset() {
    _index = -1;
  }

  @override
  Future start() async {
    if (targets.isEmpty) {
      throw Exception("Can't start tutorial without any targets added");
    }

    if (isRunning) {
      _animateHideTarget();
    } else {
      _eventsController?.add(TutorialCoachMarkEvent(
          eventType: TutorialCoachMarkEventType.starting));
    }

    _index = 0;
    await _callPreActionTargetSafely(currentTarget);
    notifyListeners();
    await _animateShowTarget();
  }

  @override
  Future next() async {
    if (isPaused) return;

    await _animateHideTarget();
    await _callPostActionTargetSafely(currentTarget);

    var newTarget = getNextTarget();
    await _callPreActionTargetSafely(newTarget);

    if (newTarget != null) {
      _index++;
    } else {
      _index = -1;
    }

    notifyListeners();

    if (newTarget == null) {
      _eventsController?.add(TutorialCoachMarkEvent(
          eventType: TutorialCoachMarkEventType.finished));
    }

    await _animateShowTarget();
  }

  @override
  Future previous() async {
    if (isPaused) return;

    await _animateHideTarget();
    await _callPostActionTargetSafely(currentTarget);

    var newTarget = getPrevTarget();
    await _callPreActionTargetSafely(newTarget);

    if (newTarget != null) {
      _index--;
    } else {
      _index = -1;
    }

    notifyListeners();

    if (newTarget == null) {
      _eventsController?.add(TutorialCoachMarkEvent(
          eventType: TutorialCoachMarkEventType.finished));
    }

    await _animateShowTarget();
  }

  _fireTargetShowing(TargetFocus? target) {
    if (target == null) return;

    _eventsController?.add(TutorialCoachTargetShowingEvent(target: target));
  }

  @override
  Future skip() async {
    if (currentTarget is PostActionTarget) {
      (currentTarget as PostActionTarget).post?.call();
    }

    _eventsController?.add(
        TutorialCoachMarkEvent(eventType: TutorialCoachMarkEventType.skipped));

    _index = -1;
    notifyListeners();
    _eventsController?.add(
        TutorialCoachMarkEvent(eventType: TutorialCoachMarkEventType.finished));
  }

  @override
  Future pause() async {
    _paused = true;
  }

  @override
  Future resume() async {
    _paused = false;
  }

  @override
  Stream<TutorialCoachMarkEvent> get events {
    if (_eventsController == null) {
      throw TutorialCoachMarkControllerException(
          "Cannot listen to events on a disposed controller");
    }
    return _eventsController!.stream;
  }

  @override
  TargetFocus? getNextTarget() {
    if (index >= 0 && _targets.length > (index + 1)) {
      return _targets[index + 1];
    }
    return null;
  }

  @override
  TargetFocus? getPrevTarget() {
    if (index > 0) {
      return _targets[index - 1];
    }
    return null;
  }

  @override
  TargetFocus? get currentTarget {
    if (index >= 0 && targets.length > index) return _targets[index];
    return null;
  }

  @override
  bool get hasNext => getNextTarget() != null;

  @override
  bool get hasPrevious => getPrevTarget() != null;

  @override
  bool get isRunning => index != -1;

  @override
  void addTargets(Iterable<TargetFocus> targets) {
    for (var target in targets) {
      if (_targets.where((t) => t.identify == target.identify).isEmpty) {
        _targets.add(target);
      }
    }
  }

  @override
  void removeTargets(Iterable<TargetFocus> targets) {
    for (var target in targets) {
      if (target.identify == currentTarget?.identify) {
        throw TutorialCoachMarkControllerException(
            "Cant remove target when it's currently the target of a running tutorial");
      }

      var index = _targets.indexWhere((t) => t.identify == target.identify);
      if (index != -1) {
        _targets.removeAt(index);
      }
    }
  }

  @override
  void setTargets(Iterable<TargetFocus> targets) {
    if (isRunning) {
      throw TutorialCoachMarkControllerException(
          "Cant replace targets when tutorial is running");
    }

    _targets.clear();
    _targets.addAll(targets);
  }

  Future _animateShowTarget() async {
    if (currentTarget != null && _animationController != null) {
      _animationController!.duration =
          currentTarget?.unFocusAnimationDuration ??
              // widget.unFocusAnimationDuration ??
              currentTarget?.focusAnimationDuration ??
              // widget.focusAnimationDuration ??
              _defaultFocusAnimationDuration;
      await _animationController!.forward();

      _fireTargetShowing(currentTarget);
    }
  }

  Future _animateHideTarget() async {
    await _animationController?.reverse();
  }

  Future _callPostActionTargetSafely(TargetFocus? target) async {
    if (target != null && target is PostActionTarget) {
      var pat = (target as PostActionTarget);
      if (pat.post != null) {
        try {
          await pat.post!();
        } catch (e, s) {
          debugPrint(e.toString());
          debugPrintStack(stackTrace: s);
        }
      }
    }
  }

  Future _callPreActionTargetSafely(TargetFocus? target) async {
    if (target != null && target is PreActionTarget) {
      var pat = (target as PreActionTarget);
      if (pat.pre != null) {
        try {
          await pat.pre!();
        } catch (e, s) {
          debugPrint(e.toString());
          debugPrintStack(stackTrace: s);
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _animationController = null;

    _eventsController?.close();
    _eventsController = null;

    _targets.clear();

    super.dispose();
  }
}
