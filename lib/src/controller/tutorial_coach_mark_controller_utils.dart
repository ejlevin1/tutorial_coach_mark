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
  running,
  skipped,
  finished,
  targetShowing
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
