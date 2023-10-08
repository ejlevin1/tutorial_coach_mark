import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/src/clipper/circle_clipper.dart';
import 'package:tutorial_coach_mark/src/clipper/rect_clipper.dart';
import 'package:tutorial_coach_mark/src/controller/tutorial_coach_mark_controller.dart';
import 'package:tutorial_coach_mark/src/paint/light_paint.dart';
import 'package:tutorial_coach_mark/src/paint/light_paint_rect.dart';
import 'package:tutorial_coach_mark/src/target/target_focus.dart';
import 'package:tutorial_coach_mark/src/target/target_position.dart';
import 'package:tutorial_coach_mark/src/util.dart';

class AnimatedFocusLight extends StatefulWidget {
  final TutorialCoachMarkController controller;
  final Function(TargetFocus)? focus;
  final FutureOr Function(TargetFocus)? clickTarget;
  final FutureOr Function(TargetFocus, TapDownDetails)?
      clickTargetWithTapPosition;
  final FutureOr Function(TargetFocus)? clickOverlay;
  final Function? removeFocus;
  final Function()? finish;
  final double paddingFocus;
  final Color colorShadow;
  final double opacityShadow;
  final Duration? focusAnimationDuration;
  final Duration? unFocusAnimationDuration;
  final Duration? pulseAnimationDuration;
  final Tween<double>? pulseVariation;
  final bool pulseEnable;
  final bool rootOverlay;
  final ImageFilter? imageFilter;
  final FutureOr Function(TargetFocus target)? preFindTarget;

  const AnimatedFocusLight({
    Key? key,
    required this.controller,
    this.focus,
    this.finish,
    this.removeFocus,
    this.clickTarget,
    this.clickTargetWithTapPosition,
    this.clickOverlay,
    this.paddingFocus = 10,
    this.colorShadow = Colors.black,
    this.opacityShadow = 0.8,
    this.focusAnimationDuration,
    this.unFocusAnimationDuration,
    this.pulseAnimationDuration,
    this.pulseVariation,
    this.imageFilter,
    this.pulseEnable = true,
    this.rootOverlay = false,
    this.preFindTarget,
  }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  AnimatedFocusLightState createState() => pulseEnable
      ? AnimatedPulseFocusLightState()
      : AnimatedStaticFocusLightState();
}

abstract class AnimatedFocusLightState extends State<AnimatedFocusLight>
    with TickerProviderStateMixin {
  final borderRadiusDefault = 10.0;
  final defaultFocusAnimationDuration = const Duration(milliseconds: 600);

  late CurvedAnimation _curvedAnimation;

  late TargetFocus? _targetFocus;
  Offset _positioned = const Offset(0.0, 0.0);
  TargetPosition? _targetPosition;

  double _sizeCircle = 100;
  double _progressAnimated = 0;
  bool _goNext = true;

  void onControllerUpdated() {
    if (_targetFocus != widget.controller.currentTarget) {
      setState(() {
        _targetFocus = widget.controller.currentTarget;
      });

      if (_targetFocus == null || !widget.controller.isRunning) {
        widget.finish?.call();
      } else {
        _runFocus();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(onControllerUpdated);
    widget.controller.animation?.addStatusListener(_listener);

    _targetFocus = widget.controller.currentTarget;

    _curvedAnimation = CurvedAnimation(
      parent: widget.controller.animation!,
      curve: Curves.ease,
    );

    Future.delayed(Duration.zero, _runFocus);
  }

  @override
  void dispose() {
    widget.controller.removeListener(onControllerUpdated);
    widget.controller.animation?.removeStatusListener(_listener);
    super.dispose();
  }

  Future _tapHandler({
    bool goNext = true,
    bool targetTap = false,
    bool overlayTap = false,
  }) async {
    if (_targetFocus != null) {
      if (targetTap) {
        await widget.clickTarget?.call(_targetFocus!);
      }
      if (overlayTap) {
        await widget.clickOverlay?.call(_targetFocus!);
      }
    }
  }

  Future _tapHandlerForPosition(TapDownDetails tapDetails) async {
    if (_targetFocus != null) {
      await widget.clickTargetWithTapPosition?.call(_targetFocus!, tapDetails);
    }
  }

  void _runFocus() async {
    if (widget.controller.currentTarget == null) return;
    _targetFocus = widget.controller.currentTarget!;

    try {
      await widget.preFindTarget?.call(widget.controller.currentTarget!);
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
    }

    TargetPosition? targetPosition;
    try {
      targetPosition = getTargetCurrent(
        _targetFocus,
        rootOverlay: widget.rootOverlay,
      );
    } on NotFoundTargetException catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
    }

    // debugPrint(
    //     'targetPosition identity=${widget.controller.currentTarget!.identify} size=${targetPosition?.size}, offset=${targetPosition?.offset}');
    if (targetPosition == null) {
      // debugPrint(
      //     'Auto-progressing to next step. ${widget.controller.currentTarget!.identify} target not found.');
      widget.controller.next();
      return;
    }

    safeSetState(() {
      _targetPosition = targetPosition!;

      _positioned = Offset(
        targetPosition.offset.dx + (targetPosition.size.width / 2),
        targetPosition.offset.dy + (targetPosition.size.height / 2),
      );

      if (targetPosition.size.height > targetPosition.size.width) {
        _sizeCircle = targetPosition.size.height * 0.6 + _getPaddingFocus();
      } else {
        _sizeCircle = targetPosition.size.width * 0.6 + _getPaddingFocus();
      }
    });
  }

  void _listener(AnimationStatus status);

  CustomPainter _getPainter(TargetFocus? target) {
    if (target?.shape == ShapeLightFocus.RRect) {
      return LightPaintRect(
        colorShadow: target?.color ?? widget.colorShadow,
        progress: _progressAnimated,
        offset: _getPaddingFocus(),
        target: _targetPosition ?? TargetPosition(Size.zero, Offset.zero),
        radius: target?.radius ?? 0,
        borderSide: target?.borderSide,
        opacityShadow: widget.opacityShadow,
      );
    } else {
      return LightPaint(
        _progressAnimated,
        _positioned,
        _sizeCircle,
        colorShadow: target?.color ?? widget.colorShadow,
        borderSide: target?.borderSide,
        opacityShadow: widget.opacityShadow,
      );
    }
  }

  double _getPaddingFocus() {
    return _targetFocus?.paddingFocus ?? (widget.paddingFocus);
  }

  BorderRadius _betBorderRadiusTarget() {
    double radius = _targetFocus?.shape == ShapeLightFocus.Circle
        ? _targetPosition?.size.width ?? borderRadiusDefault
        : _targetFocus?.radius ?? borderRadiusDefault;
    return BorderRadius.circular(radius);
  }
}

class AnimatedStaticFocusLightState extends AnimatedFocusLightState {
  double get left => (_targetPosition?.offset.dx ?? 0) - _getPaddingFocus() * 2;

  double get top => (_targetPosition?.offset.dy ?? 0) - _getPaddingFocus() * 2;

  double get width {
    return (_targetPosition?.size.width ?? 0) + _getPaddingFocus() * 4;
  }

  double get height {
    return (_targetPosition?.size.height ?? 0) + _getPaddingFocus() * 4;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.animation == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: _targetFocus?.enableOverlayTab ?? false
          ? () => _tapHandler(overlayTap: true)
          : null,
      child: AnimatedBuilder(
        animation: widget.controller.animation!,
        builder: (_, child) {
          _progressAnimated = _curvedAnimation.value;
          return Stack(
            children: <Widget>[
              SizedBox(
                width: double.maxFinite,
                height: double.maxFinite,
                child: CustomPaint(
                  painter: _getPainter(_targetFocus),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: InkWell(
                  borderRadius: _betBorderRadiusTarget(),
                  onTapDown: _tapHandlerForPosition,
                  onTap: _targetFocus?.enableTargetTab ?? false
                      ? () => _tapHandler(targetTap: true)

                      /// Essential for collecting [TapDownDetails]. Do not make [null]
                      : () {},
                  child: Container(
                    color: Colors.transparent,
                    width: width,
                    height: height,
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Future _tapHandler({
    bool goNext = true,
    bool targetTap = false,
    bool overlayTap = false,
  }) async {
    await super._tapHandler(
      goNext: goNext,
      targetTap: targetTap,
      overlayTap: overlayTap,
    );
    safeSetState(() => _goNext = goNext);
  }

  @override
  void _listener(AnimationStatus status) {
    if (status == AnimationStatus.completed && _targetFocus != null) {
      widget.focus?.call(_targetFocus!);
    } else if (status == AnimationStatus.reverse) {
      widget.removeFocus!();
    }
  }
}

class AnimatedPulseFocusLightState extends AnimatedFocusLightState {
  final defaultPulseAnimationDuration = const Duration(milliseconds: 500);
  final defaultPulseVariation = Tween(begin: 1.0, end: 0.99);
  late AnimationController _controllerPulse;
  late Animation _tweenPulse;

  bool _finishFocus = false;
  bool _initReverse = false;

  get left => (_targetPosition?.offset.dx ?? 0) - _getPaddingFocus() * 2;

  get top => (_targetPosition?.offset.dy ?? 0) - _getPaddingFocus() * 2;

  get width => (_targetPosition?.size.width ?? 0) + _getPaddingFocus() * 4;

  get height => (_targetPosition?.size.height ?? 0) + _getPaddingFocus() * 4;

  @override
  void initState() {
    super.initState();
    _controllerPulse = AnimationController(
      vsync: this,
      duration: widget.pulseAnimationDuration ?? defaultPulseAnimationDuration,
    );

    _tweenPulse = _createTweenAnimation(
      _targetFocus?.pulseVariation ??
          widget.pulseVariation ??
          defaultPulseVariation,
    );

    _controllerPulse.addStatusListener(_listenerPulse);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.animation == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: _targetFocus?.enableOverlayTab ?? false
          ? () => _tapHandler(overlayTap: true)
          : null,
      child: AnimatedBuilder(
        animation: widget.controller.animation!,
        builder: (_, child) {
          _progressAnimated = _curvedAnimation.value;
          // print(
          //     'controller.value=${widget.controller.animation!.value}, curvedAnimation.value=${_curvedAnimation.value}, left=$left, top=$top');
          return AnimatedBuilder(
            animation: _controllerPulse,
            builder: (_, child) {
              if (_finishFocus) {
                _progressAnimated = _tweenPulse.value;
              }
              // print('animationBuilder val=${_tweenPulse.value}');
              return Stack(
                children: <Widget>[
                  _getLightPaint(_targetFocus),
                  Positioned(
                    left: left,
                    top: top,
                    child: InkWell(
                      borderRadius: _betBorderRadiusTarget(),
                      onTap: _targetFocus?.enableTargetTab ?? false
                          ? () => _tapHandler(targetTap: true)

                          /// Essential for collecting [TapDownDetails]. Do not make [null]
                          : () {},
                      onTapDown: _tapHandlerForPosition,
                      child: Container(
                        color: Colors.transparent,
                        width: width,
                        height: height,
                      ),
                    ),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  void _runFocus() {
    _tweenPulse = _createTweenAnimation(
      _targetFocus?.pulseVariation ??
          widget.pulseVariation ??
          defaultPulseVariation,
    );
    _finishFocus = false;
    super._runFocus();
  }

  @override
  Future _tapHandler({
    bool goNext = true,
    bool targetTap = false,
    bool overlayTap = false,
  }) async {
    await super._tapHandler(
      goNext: goNext,
      targetTap: targetTap,
      overlayTap: overlayTap,
    );
    if (mounted) {
      safeSetState(() {
        _goNext = goNext;
        _initReverse = true;
      });
    }

    _controllerPulse.reverse(from: _controllerPulse.value);
  }

  @override
  void dispose() {
    _controllerPulse.dispose();
    super.dispose();
  }

  @override
  void _listener(AnimationStatus status) {
    if (status == AnimationStatus.completed && _targetFocus != null) {
      safeSetState(() => _finishFocus = true);

      widget.focus?.call(_targetFocus!);

      _controllerPulse.forward();
    }
    if (status == AnimationStatus.dismissed) {
      safeSetState(() {
        _finishFocus = false;
        _initReverse = false;
      });
    }

    if (status == AnimationStatus.reverse) {
      widget.removeFocus?.call();
    }
  }

  void _listenerPulse(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controllerPulse.reverse();
    }

    if (status == AnimationStatus.dismissed) {
      if (_initReverse) {
        safeSetState(() => _finishFocus = false);
        if (_goNext) {
          widget.controller.next();
        } else {
          widget.controller.previous();
        }
      } else if (_finishFocus) {
        _controllerPulse.forward();
      }
    }
  }

  Animation _createTweenAnimation(Tween<double> tween) {
    return tween.animate(
      CurvedAnimation(parent: _controllerPulse, curve: Curves.ease),
    );
  }

  Widget _getLightPaint(TargetFocus? targetFocus) {
    if (widget.imageFilter != null) {
      return ClipPath(
        clipper: _getClipper(targetFocus?.shape),
        child: BackdropFilter(
          filter: widget.imageFilter!,
          child: _getSizedPainter(targetFocus),
        ),
      );
    } else {
      return _getSizedPainter(targetFocus);
    }
  }

  SizedBox _getSizedPainter(TargetFocus? targetFocus) {
    return SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: CustomPaint(
        painter: _getPainter(targetFocus),
      ),
    );
  }

  CustomClipper<Path> _getClipper(ShapeLightFocus? shape) {
    return shape == ShapeLightFocus.RRect
        ? RectClipper(
            progress: _progressAnimated,
            offset: _getPaddingFocus(),
            target: _targetPosition ?? TargetPosition(Size.zero, Offset.zero),
            radius: _targetFocus?.radius ?? 0,
            borderSide: _targetFocus?.borderSide,
          )
        : CircleClipper(
            _progressAnimated,
            _positioned,
            _sizeCircle,
            _targetFocus?.borderSide,
          );
  }
}
