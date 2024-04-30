import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialCoachMarkControllerException implements Exception {
  /// Creates a [TutorialCoachMarkControllerException] with an optional human-readable
  /// error message.
  TutorialCoachMarkControllerException([this.message]);

  /// A human-readable error message, possibly null.
  final String? message;

  @override
  String toString() => 'TutorialCoachMarkControllerException($message)';
}

enum TutorialCoachMarkEventType {
  starting,
  canceling,
  finished,
  targetShowing,
  targetFailed,
  controllerEvent
}

class TutorialCoachMarkEvent {
  TutorialCoachMarkEvent({required this.eventType});

  TutorialCoachMarkEventType eventType;

  @override
  String toString() => 'TutorialCoachMarkEventType($eventType)';
}

abstract class TutorialCoachTargetBaseControllerEvent
    extends TutorialCoachMarkEvent {
  TutorialCoachTargetBaseControllerEvent({
    required this.target,
  }) : super(
          eventType: TutorialCoachMarkEventType.controllerEvent,
        );

  final TargetFocus target;
}

abstract class TutorialCoachTargetBaseControllerEventWithMessage
    extends TutorialCoachTargetBaseControllerEvent {
  TutorialCoachTargetBaseControllerEventWithMessage({
    required TargetFocus target,
    required this.message,
  }) : super(
          target: target,
        );

  final String message;
}

class TutorialCoachTargetBeforeInitEvent
    extends TutorialCoachTargetBaseControllerEvent {
  TutorialCoachTargetBeforeInitEvent({
    required TargetFocus target,
  }) : super(
          target: target,
        );

  @override
  String toString() => 'Before Init() event for ${target.identify}';
}

class TutorialCoachTargetAfterInitEvent
    extends TutorialCoachTargetBaseControllerEvent {
  TutorialCoachTargetAfterInitEvent({
    required TargetFocus target,
    required this.available,
  }) : super(
          target: target,
        );

  final bool available;

  @override
  String toString() => 'After Init() event for ${target.identify}';
}

class TutorialCoachTargetAfterInitFailedEvent
    extends TutorialCoachTargetBaseControllerEventWithMessage {
  TutorialCoachTargetAfterInitFailedEvent({
    required TargetFocus target,
    required String message,
  }) : super(
          target: target,
          message: message,
        );

  @override
  String toString() => 'Init() event failed for ${target.identify}: $message';
}

class TutorialCoachTargetBeforePreEvent
    extends TutorialCoachTargetBaseControllerEvent {
  TutorialCoachTargetBeforePreEvent({
    required TargetFocus target,
  }) : super(
          target: target,
        );

  @override
  String toString() => 'Before Pre() event for ${target.identify}';
}

class TutorialCoachTargetAfterPreEvent
    extends TutorialCoachTargetBaseControllerEvent {
  TutorialCoachTargetAfterPreEvent({
    required TargetFocus target,
  }) : super(
          target: target,
        );

  @override
  String toString() => 'After Pre() event for ${target.identify}';
}

class TutorialCoachTargetAfterPreFailedEvent
    extends TutorialCoachTargetBaseControllerEventWithMessage {
  TutorialCoachTargetAfterPreFailedEvent({
    required TargetFocus target,
    required String message,
  }) : super(
          target: target,
          message: message,
        );

  @override
  String toString() => 'Pre() event failed for ${target.identify}: $message';
}

class TutorialCoachTargetAfterPostFailedEvent
    extends TutorialCoachTargetBaseControllerEventWithMessage {
  TutorialCoachTargetAfterPostFailedEvent({
    required TargetFocus target,
    required String message,
  }) : super(
          target: target,
          message: message,
        );

  @override
  String toString() => 'Post() event failed for ${target.identify}: $message';
}

class TutorialCoachTargetShowingEvent extends TutorialCoachMarkEvent {
  TutorialCoachTargetShowingEvent({
    required this.target,
  }) : super(
          eventType: TutorialCoachMarkEventType.targetShowing,
        );

  final TargetFocus target;
}

class TutorialCoachTargetFailedEvent extends TutorialCoachMarkEvent {
  TutorialCoachTargetFailedEvent({
    required this.target,
  }) : super(
          eventType: TutorialCoachMarkEventType.targetFailed,
        );

  final TargetFocus target;
}
