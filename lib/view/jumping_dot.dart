///
/// Clone from https://github.com/rezam92/jumping_dot
///
import 'package:flutter/material.dart';

class DotWidget extends StatelessWidget {
  final Color? color;
  final double? radius;

  const DotWidget({
    Key? key,
    @required this.color,
    @required this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      height: radius,
      width: radius,
    );
  }
}

/// Jumping Dot.
///
/// [numberOfDots] number of dots,
/// [color] color of dots.
/// [radius] radius of dots.
/// [animationDuration] animation duration in milliseconds
class JumpingDots extends StatefulWidget {
  final int numberOfDots;
  final Color color;
  final double radius;
  final double innerPadding;
  final Duration animationDuration;

  const JumpingDots({
    Key? key,
    this.numberOfDots = 3,
    this.radius = 10,
    this.innerPadding = 1.2,
    this.animationDuration = const Duration(milliseconds: 500),
    this.color = const Color(0xfff2c300),
  }) : super(key: key);

  @override
  State createState() => _JumpingDotsState();
}

class _JumpingDotsState extends State<JumpingDots>
    with TickerProviderStateMixin {
  List<AnimationController>? _animationControllers;

  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers!) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initAnimation() {
    _animationControllers = List.generate(
      widget.numberOfDots,
      (index) {
        return AnimationController(
            vsync: this, duration: widget.animationDuration);
      },
    ).toList();

    for (int i = 0; i < widget.numberOfDots; i++) {
      _animations.add(
          Tween<double>(begin: 0, end: -3).animate(_animationControllers![i]));
    }

    for (int i = 0; i < widget.numberOfDots; i++) {
      _animationControllers![i].addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationControllers![i].reverse();
          if (i != widget.numberOfDots - 1) {
            _animationControllers![i + 1].forward();
          }
        }
        if (i == widget.numberOfDots - 1 &&
            status == AnimationStatus.dismissed) {
          _animationControllers![0].forward();
        }
      });
    }
    _animationControllers!.first.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: List.generate(widget.numberOfDots, (index) {
          return AnimatedBuilder(
            animation: _animationControllers![index],
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.all(widget.innerPadding),
                child: Transform.translate(
                  offset: Offset(0, _animations[index].value),
                  child: DotWidget(color: widget.color, radius: widget.radius),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
