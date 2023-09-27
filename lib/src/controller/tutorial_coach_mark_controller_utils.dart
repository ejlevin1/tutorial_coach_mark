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
  targetFailed
}

class TutorialCoachMarkEvent {
  TutorialCoachMarkEvent({required this.eventType});

  TutorialCoachMarkEventType eventType;
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
