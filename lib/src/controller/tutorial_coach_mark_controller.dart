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

  Future start();
  Future next();
  Future previous();
  Future pause();
  Future resume();
  Future cancel();
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
    print("starting");

    _index = -1;
    await _move(true);
    print("current index $_index");
    if (isRunning) {
      _eventsController?.add(TutorialCoachMarkEvent(
          eventType: TutorialCoachMarkEventType.starting));
    }
  }

  Future<int> _getAllowedOffsetIndex(bool forward) async {
    int offset = (forward ? 1 : -1);
    bool preSuccessful = false;
    TargetFocus? newTarget;

    while (!preSuccessful && getOffsetTarget(index + offset) != null) {
      newTarget = getOffsetTarget(index + offset);
      preSuccessful = await _callPreActionTargetSafely(newTarget);
      if (!preSuccessful) {
        if (newTarget != null) {
          _eventsController
              ?.add(TutorialCoachTargetFailedEvent(target: newTarget));
        }
        offset += (forward ? 1 : -1);
      }
    }

    return offset;
  }

  Future _move(bool forward) async {
    if (isPaused) return;

    await _animateHideTarget();
    await _callPostActionTargetSafely(currentTarget);

    var offset = await _getAllowedOffsetIndex(forward);
    TargetFocus? newTarget = getOffsetTarget(offset);
    if (newTarget != null) {
      _index += offset;
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
  Future next() => _move(true);

  @override
  Future previous() => _move(false);

  _fireTargetShowing(TargetFocus? target) {
    if (target == null) return;

    _eventsController?.add(TutorialCoachTargetShowingEvent(target: target));
  }

  @override
  Future cancel() async {
    _callPostActionTargetSafely(currentTarget);

    _eventsController?.add(TutorialCoachMarkEvent(
        eventType: TutorialCoachMarkEventType.canceling));

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
  TargetFocus? getOffsetTarget(int offset) {
    var newIndex = index + offset;
    if (newIndex >= 0 && _targets.length > newIndex) {
      return _targets[newIndex];
    }
    return null;
  }

  @override
  TargetFocus? get currentTarget {
    if (index >= 0 && targets.length > index) return _targets[index];
    return null;
  }

  @override
  bool get hasNext => getOffsetTarget(1) != null;

  @override
  bool get hasPrevious => getOffsetTarget(-1) != null;

  @override
  bool get isRunning => currentTarget != null;

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

  Future<bool> _callPreActionTargetSafely(TargetFocus? target) async {
    if (target != null && target is PreActionTarget) {
      var pat = (target as PreActionTarget);
      if (pat.pre != null) {
        try {
          await pat.pre!();
        } catch (e, s) {
          debugPrint(e.toString());
          debugPrintStack(stackTrace: s);
          return false;
        }
      }
    }

    return true;
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
