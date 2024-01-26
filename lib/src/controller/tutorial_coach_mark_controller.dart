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

  Future<void> start();
  Future<void> next();
  Future<void> previous();
  Future<void> pause();
  Future<void> resume();
  Future<void> cancel();

  void dispose();
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

  bool get isDisposed => _eventsController == null;

  int get index => _index;
  int _index;

  @override
  bool get isPaused => _paused;
  bool _paused;

  void reset() {
    _index = -1;
  }

  @override
  Future<void> start() async {
    if (targets.isEmpty) {
      throw Exception("Can't start tutorial without any targets added");
    }
    _index = -1;
    await _move(true);
    if (isRunning) {
      _eventsController?.add(TutorialCoachMarkEvent(
          eventType: TutorialCoachMarkEventType.starting));
    }
  }

  Future<int> _getAllowedOffsetIndex(bool forward) async {
    if (isDisposed) {
      debugPrintStack(
          label: 'Called _getAllowedOffsetIndex() when controller is disposed');
    }

    int offset = (forward ? 1 : -1);
    bool found = false;
    TargetFocus? newTarget;

    while (!found && getOffsetTarget(offset) != null) {
      newTarget = getOffsetTarget(offset);
      if (newTarget != null) {
        final initialized = await _callInitActionTargetSafely(newTarget);
        if (!initialized) {
          _eventsController
              ?.add(TutorialCoachTargetFailedEvent(target: newTarget));
          offset += (forward ? 1 : -1);
        } else {
          found = true;
        }
      }
    }

    return offset;
  }

  Future<void> _move(bool forward) async {
    _ensureNotDisposed('move targets');

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
    } else {
      await _callPreActionTargetSafely(newTarget);
    }

    await _animateShowTarget();
  }

  @override
  Future<void> next() => _move(true);

  @override
  Future<void> previous() => _move(false);

  _fireTargetShowing(TargetFocus? target) {
    if (target == null) return;

    _eventsController?.add(TutorialCoachTargetShowingEvent(target: target));
  }

  @override
  Future<void> cancel() async {
    _callPostActionTargetSafely(currentTarget);

    _eventsController?.add(TutorialCoachMarkEvent(
        eventType: TutorialCoachMarkEventType.canceling));

    _index = -1;
    notifyListeners();
    _eventsController?.add(
        TutorialCoachMarkEvent(eventType: TutorialCoachMarkEventType.finished));
  }

  @override
  Future<void> pause() async {
    _paused = true;
  }

  @override
  Future<void> resume() async {
    _paused = false;
  }

  void _ensureNotDisposed(String method) {
    if (_eventsController == null) {
      throw TutorialCoachMarkControllerException(
          "Cannot $method on a disposed controller");
    }
  }

  @override
  Stream<TutorialCoachMarkEvent> get events {
    _ensureNotDisposed('get event stream');
    return _eventsController!.stream;
  }

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
    _ensureNotDisposed('add targets');

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
    _ensureNotDisposed('set targets');

    if (isRunning) {
      throw TutorialCoachMarkControllerException(
          "Cant replace targets when tutorial is running");
    }

    _targets.clear();
    _targets.addAll(targets);
  }

  Future<void> _animateShowTarget() async {
    if (currentTarget != null && _animationController != null && !isDisposed) {
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

  Future<void> _animateHideTarget() async {
    if (isDisposed) return;

    await _animationController?.reverse();
  }

  Future<bool> _callInitActionTargetSafely(TargetFocus? target) async {
    if (isDisposed) {
      debugPrintStack(
          label:
              'Called _callPreActionTargetSafely() when controller is disposed');
      return false;
    }

    if (target != null && target is InitActionTarget) {
      var pat = (target as InitActionTarget);
      _eventsController
          ?.add(TutorialCoachTargetBeforeInitEvent(target: target));
      try {
        var available = await pat.init();
        _eventsController?.add(
          TutorialCoachTargetAfterInitEvent(
            target: target,
            available: available,
          ),
        );
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
        _eventsController?.add(TutorialCoachTargetAfterInitFailedEvent(
            target: target, message: e.toString()));
        return false;
      }
    }

    return true;
  }

  Future<bool> _callPreActionTargetSafely(TargetFocus? target) async {
    if (target == null) return false;

    if (isDisposed) {
      debugPrintStack(
          label:
              'Called _callPreActionTargetSafely() when controller is disposed');
      return false;
    }

    if (target is PreActionTarget) {
      var pat = (target as PreActionTarget);
      _eventsController?.add(TutorialCoachTargetBeforePreEvent(target: target));
      try {
        await pat.pre();
        _eventsController
            ?.add(TutorialCoachTargetAfterPreEvent(target: target));
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
        _eventsController?.add(TutorialCoachTargetAfterPreFailedEvent(
            target: target, message: e.toString()));
        return false;
      }
    }

    return true;
  }

  Future<void> _callPostActionTargetSafely(TargetFocus? target) async {
    if (isDisposed) {
      debugPrintStack(
          label:
              'Called _callPostActionTargetSafely() when controller is disposed');
      return;
    }

    if (target != null && target is PostActionTarget) {
      var pat = (target as PostActionTarget);
      _eventsController?.add(TutorialCoachTargetBeforePreEvent(target: target));
      try {
        await pat.post();
        _eventsController
            ?.add(TutorialCoachTargetAfterPreEvent(target: target));
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
        _eventsController?.add(TutorialCoachTargetAfterPostFailedEvent(
            target: target, message: e.toString()));
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
