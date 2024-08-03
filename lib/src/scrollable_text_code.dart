import 'dart:async';
import 'package:flutter/material.dart';

class ScrollableText extends StatefulWidget {
  const ScrollableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection = TextDirection.ltr,
    this.numberOfReps,
    this.delayBefore,
    this.pauseBetween,
    this.pauseOnBounce,
    this.mode = ScrollableTextMode.endless,
    this.velocity = const Velocity(pixelsPerSecond: Offset(80, 0)),
    this.selectable = false,
    this.intervalSpaces,
    this.fadedBorder = false,
    this.fadedBorderWidth = 0.2,
    this.fadeBorderSide = FadeBorderSide.both,
    this.fadeBorderVisibility = FadeBorderVisibility.auto,
  });

  final String text;

  final TextAlign? textAlign;

  final TextDirection textDirection;

  final TextStyle? style;

  final int? numberOfReps;

  final Duration? delayBefore;

  final Duration? pauseBetween;

  final Duration? pauseOnBounce;

  final ScrollableTextMode mode;

  final Velocity velocity;

  final bool selectable;

  final int? intervalSpaces;

  final bool fadedBorder;

  final double? fadedBorderWidth;

  final FadeBorderSide fadeBorderSide;

  final FadeBorderVisibility fadeBorderVisibility;

  @override
  State<ScrollableText> createState() => _ScrollableTextState();
}

class _ScrollableTextState extends State<ScrollableText> {
  final _scrollController = ScrollController();
  String? _endlessText;
  double? _originalTextWidth;
  Timer? _timer;
  bool _running = false;
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    final WidgetsBinding? binding = WidgetsBinding.instance;
    if (binding != null) {
      binding.addPostFrameCallback(_initScroller);
    }
  }

  @override
  void didUpdateWidget(covariant ScrollableText oldWidget) {
    _onUpdate(oldWidget);

    _setTimer();

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
        widget.intervalSpaces == null ||
            widget.mode == ScrollableTextMode.endless,
        'intervalSpaces is only available in ScrollableTextMode.endless mode');
    assert(
        !widget.fadedBorder ||
            (widget.fadedBorder &&
                widget.fadedBorderWidth != null &&
                widget.fadedBorderWidth! > 0 &&
                widget.fadedBorderWidth! <= 1),
        'fadedBorderInterval must be between 0 and 1 when fadedBorder is true');

    Widget baseWidget = Directionality(
      textDirection: widget.textDirection,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: widget.selectable
            ? SelectableText(
                _endlessText ?? widget.text,
                style: widget.style,
                textAlign: widget.textAlign,
              )
            : Text(
                _endlessText ?? widget.text,
                style: widget.style,
                textAlign: widget.textAlign,
              ),
      ),
    );

    Widget? fadeBorderWidget;

    if (widget.fadedBorder) {
      final List<Color> colors =
          List.generate(1 ~/ widget.fadedBorderWidth! - 1, (index) {
        return Colors.transparent;
      }, growable: true);

      if (widget.fadeBorderSide == FadeBorderSide.both ||
          widget.fadeBorderSide == FadeBorderSide.left) {
        colors.insert(0, Colors.black);
      } else {
        colors.add(Colors.transparent);
      }
      if (widget.fadeBorderSide == FadeBorderSide.both ||
          widget.fadeBorderSide == FadeBorderSide.right) {
        colors.add(Colors.black);
      } else {
        colors.add(Colors.transparent);
      }

      final List<double> stops =
          List.generate(1 ~/ widget.fadedBorderWidth!, (index) {
        return (index + 1) * widget.fadedBorderWidth!;
      }, growable: true);

      stops.insert(0, 0);

      final TextPainter textPrototype = TextPainter(
        text: TextSpan(
          text: _endlessText ?? widget.text,
          style: widget.style,
        ),
        textDirection: widget.textDirection,
        textScaleFactor: MediaQuery.of(context).textScaleFactor,
        textWidthBasis: TextWidthBasis.longestLine,
      )..layout();

      fadeBorderWidget = LayoutBuilder(
        builder: (context, constraints) {
          if (widget.fadeBorderVisibility == FadeBorderVisibility.always ||
              constraints.maxWidth < textPrototype.size.width) {
            return ShaderMask(
              blendMode: BlendMode.dstOut,
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: colors,
                  stops: stops,
                ).createShader(rect);
              },
              child: baseWidget,
            );
          } else {
            return baseWidget;
          }
        },
      );
    }

    return fadeBorderWidget ?? baseWidget;
  }

  Future<void> _initScroller(_) async {
    await _delayBefore();
    _setTimer();
  }

  void _setTimer() {
    _timer?.cancel();

    _running = false;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_available) {
        timer.cancel();
        return;
      }
      final int? maxReps = widget.numberOfReps;
      if (maxReps != null && _counter >= maxReps) {
        timer.cancel();
        return;
      }

      if (!_running) _run();
    });
  }

  Future<void> _run() async {
    _running = true;

    final int? maxReps = widget.numberOfReps;
    if (maxReps == null || _counter < maxReps) {
      _counter++;

      switch (widget.mode) {
        case ScrollableTextMode.bouncing:
          {
            await _animateBouncing();
            break;
          }
        default:
          {
            await _animateEndless();
          }
      }
    }
    _running = false;
  }

  Future<void> _animateEndless() async {
    if (!_available) return;

    final ScrollPosition position = _scrollController.position;
    final bool needsScrolling = position.maxScrollExtent > 0;
    if (!needsScrolling) {
      if (_endlessText != null) setState(() => _endlessText = null);
      return;
    }

    if (_endlessText == null || _originalTextWidth == null) {
      setState(() {
        _originalTextWidth =
            position.maxScrollExtent + position.viewportDimension;
        _endlessText =
            widget.text + _getSpaces(widget.intervalSpaces ?? 1) + widget.text;
      });

      return;
    }

    final double endlessTextWidth =
        position.maxScrollExtent + position.viewportDimension;
    final double singleRoundExtent = endlessTextWidth - _originalTextWidth!;
    final Duration duration = _getDuration(singleRoundExtent);
    if (duration == Duration.zero) return;

    if (!_available) return;
    await _scrollController.animateTo(
      singleRoundExtent,
      duration: duration,
      curve: Curves.linear,
    );
    if (!_available) return;
    _scrollController.jumpTo(position.minScrollExtent);

    if (widget.pauseBetween != null) {
      await Future.delayed(widget.pauseBetween!);
    }
  }

  Future<void> _animateBouncing() async {
    final double maxExtent = _scrollController.position.maxScrollExtent;
    final double minExtent = _scrollController.position.minScrollExtent;
    final double extent = maxExtent - minExtent;
    final Duration duration = _getDuration(extent);
    if (duration == Duration.zero) return;

    if (!_available) return;
    await _scrollController.animateTo(
      maxExtent,
      duration: duration,
      curve: Curves.linear,
    );
    if (widget.pauseOnBounce != null) {
      await Future.delayed(widget.pauseOnBounce!);
    }
    if (!_available) return;
    await _scrollController.animateTo(
      minExtent,
      duration: duration,
      curve: Curves.linear,
    );
    if (!_available) return;
    if (widget.pauseBetween != null) {
      await Future<dynamic>.delayed(widget.pauseBetween!);
    }
  }

  Future<void> _delayBefore() async {
    final Duration? delayBefore = widget.delayBefore;
    if (delayBefore == null) return;

    await Future<dynamic>.delayed(delayBefore);
  }

  Duration _getDuration(double extent) {
    if (widget.velocity.pixelsPerSecond.dx == 0) return Duration.zero;

    final int milliseconds =
        (extent * 1000 / widget.velocity.pixelsPerSecond.dx).round();

    return Duration(milliseconds: milliseconds);
  }

  void _onUpdate(ScrollableText oldWidget) {
    if (widget.text != oldWidget.text && _endlessText != null) {
      setState(() {
        _endlessText = null;
        _originalTextWidth = null;
      });
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    }
  }

  String _getSpaces(int number) {
    String spaces = '';
    for (int i = 0; i < number; i++) {
      spaces += '\u{00A0}';
    }

    return spaces;
  }

  bool get _available => mounted && _scrollController.hasClients;
}

enum ScrollableTextMode {
  bouncing,
  endless,
}

enum FadeBorderSide { left, right, both }

enum FadeBorderVisibility { always, auto }
