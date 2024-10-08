library rounded_loading_button;

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

enum LoadingState { idle, loading, success, error }

class RoundedLoadingButton extends StatefulWidget {
  final RoundedLoadingButtonController? controller;

  /// The callback that is called when the button is tapped or otherwise activated.
  final VoidCallback? onPressed;

  /// The button's label
  final Widget? child;

  /// The primary color of the button
  final Color? color;

  /// The vertical extent of the button.
  final double height;

  /// The horiztonal extent of the button.
  final double width;

  /// The size of the CircularProgressIndicator
  final double loaderSize;

  /// The stroke width of the CircularProgressIndicator
  final double loaderStrokeWidth;

  /// Whether to trigger the animation on the tap event
  final bool animateOnTap;

  /// The color of the static icons
  final Color valueColor;

  /// The curve of the shrink animation
  final Curve curve;

  /// The radius of the button border
  final double borderRadius;

  /// The duration of the button animation
  final Duration duration;

  /// The elevation of the raised button
  final double elevation;

  /// The color of the button when it is in the error state
  final Color errorColor;

  /// The color of the button when it is in the success state
  final Color? successColor;

  /// The color of the button when it is disabled
  final Color? disabledColor;

  Duration get _borderDuration {
    return Duration(milliseconds: (duration.inMilliseconds / 2).round());
  }

  RoundedLoadingButton(
      {Key? key,
      this.controller,
      this.onPressed,
      this.child,
      this.color,
      this.height = 50,
      this.width = 300,
      this.loaderSize = 24.0,
      this.loaderStrokeWidth = 2.0,
      this.animateOnTap = true,
      this.valueColor = Colors.white,
      this.borderRadius = 35,
      this.elevation = 2,
      this.duration = const Duration(milliseconds: 500),
      this.curve = Curves.easeInOutCirc,
      this.errorColor = Colors.red,
      this.successColor,
      this.disabledColor});

  @override
  State<StatefulWidget> createState() => RoundedLoadingButtonState();
}

class RoundedLoadingButtonState extends State<RoundedLoadingButton> with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late AnimationController _borderController;
  late AnimationController _checkButtonControler;

  late Animation _squeezeAnimation;
  late Animation _bounceAnimation;
  late Animation _borderAnimation;

  final _state = BehaviorSubject<LoadingState>.seeded(LoadingState.idle);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final _check = Container(
        alignment: FractionalOffset.center,
        decoration: BoxDecoration(
          color: widget.successColor ?? theme.primaryColor,
          borderRadius: BorderRadius.all(Radius.circular(_bounceAnimation.value / 2)),
        ),
        width: _bounceAnimation.value,
        height: _bounceAnimation.value,
        child: _bounceAnimation.value > 20
            ? Icon(
                Icons.check,
                color: widget.valueColor,
              )
            : null);

    final _cross = Container(
        alignment: FractionalOffset.center,
        decoration: BoxDecoration(
          color: widget.errorColor,
          borderRadius: BorderRadius.all(Radius.circular(_bounceAnimation.value / 2)),
        ),
        width: _bounceAnimation.value,
        height: _bounceAnimation.value,
        child: _bounceAnimation.value > 20
            ? Icon(
                Icons.close,
                color: widget.valueColor,
              )
            : null);

    final _loader = SizedBox(
        height: widget.loaderSize,
        width: widget.loaderSize,
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor), strokeWidth: widget.loaderStrokeWidth));

    final childStream = StreamBuilder(
      stream: _state,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: snapshot.data == LoadingState.loading ? _loader : widget.child);
      },
    );

    final _btn = ButtonTheme(
        shape: RoundedRectangleBorder(borderRadius: _borderAnimation.value),
        minWidth: _squeezeAnimation.value,
        height: widget.height,
        disabledColor: widget.disabledColor,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(widget.width, widget.height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            backgroundColor: widget.color,
            elevation: widget.elevation,
          ),
          onPressed: widget.onPressed == null ? null : _btnPressed,
          child: childStream,
        ));

    return Container(
        height: widget.height,
        child: Center(
            child: _state.value == LoadingState.error
                ? _cross
                : _state.value == LoadingState.success
                    ? _check
                    : _btn));
  }

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(duration: widget.duration, vsync: this);

    _checkButtonControler = AnimationController(duration: Duration(milliseconds: 1000), vsync: this);

    _borderController = AnimationController(duration: widget._borderDuration, vsync: this);

    _bounceAnimation = Tween<double>(begin: 0, end: widget.height)
        .animate(CurvedAnimation(parent: _checkButtonControler, curve: Curves.elasticOut));
    _bounceAnimation.addListener(() {
      setState(() {});
    });

    _squeezeAnimation = Tween<double>(begin: widget.width, end: widget.height)
        .animate(CurvedAnimation(parent: _buttonController, curve: widget.curve));

    _squeezeAnimation.addListener(() {
      setState(() {});
    });

    _squeezeAnimation.addStatusListener((state) {
      if (state == AnimationStatus.completed && widget.animateOnTap) {
        widget.onPressed!();
      }
    });

    _borderAnimation =
        BorderRadiusTween(begin: BorderRadius.circular(widget.borderRadius), end: BorderRadius.circular(widget.height))
            .animate(_borderController);

    _borderAnimation.addListener(() {
      setState(() {});
    });

    widget.controller?._addListeners(_start, _stop, _success, _error, _reset);
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _checkButtonControler.dispose();
    _borderController.dispose();
    _state.close();
    super.dispose();
  }

  void _btnPressed() async {
    if (widget.animateOnTap) {
      _start();
    } else {
      widget.onPressed!();
    }
  }

  void _start() {
    _state.sink.add(LoadingState.loading);
    _borderController.forward();
    _buttonController.forward();
  }

  void _stop() {
    _state.sink.add(LoadingState.idle);
    _buttonController.reverse();
    _borderController.reverse();
  }

  void _success() {
    _state.sink.add(LoadingState.success);
    _checkButtonControler.forward();
  }

  void _error() {
    _state.sink.add(LoadingState.error);
    _checkButtonControler.forward();
  }

  void _reset() {
    _state.sink.add(LoadingState.idle);
    _buttonController.reverse();
    _borderController.reverse();
    _checkButtonControler.reset();
  }
}

class RoundedLoadingButtonController {
  late VoidCallback _startListener;
  late VoidCallback _stopListener;
  late VoidCallback _successListener;
  late VoidCallback _errorListener;
  late VoidCallback _resetListener;

  void _addListeners(VoidCallback startListener, VoidCallback stopListener, VoidCallback successListener,
      VoidCallback errorListener, VoidCallback resetListener) {
    _startListener = startListener;
    _stopListener = stopListener;
    _successListener = successListener;
    _errorListener = errorListener;
    _resetListener = resetListener;
  }

  void start() {
    _startListener();
  }

  void stop() {
    _stopListener();
  }

  void success() {
    _successListener();
  }

  void error() {
    _errorListener();
  }

  void reset() {
    _resetListener();
  }
}
