import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class DotsLoading extends StatefulWidget {
  final int numberOfDots;
  final Widget Function()? activeDotBuilder;
  final Widget Function()? inactiveDotBuilder;
  final double innerPadding;

  const DotsLoading(
      {super.key,
      this.numberOfDots = 3,
      this.activeDotBuilder,
      this.inactiveDotBuilder,
      this.innerPadding = 2.0});

  @override
  State<StatefulWidget> createState() => _DotsLoadingState();
}

class _DotsLoadingState extends State<DotsLoading> {
  late Timer? _timer;
  final _duration = const Duration(milliseconds: 500);
  late int _selected;

  @override
  void initState() {
    _selected = 0;
    _timer = Timer.periodic(_duration, (timer) {
      setState(() {
        _selected = (_selected + 1) % widget.numberOfDots;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _selectedDefaultLoadingDot() {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
    );
  }

  Widget _unselectedDefaultLoadingDot() {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.numberOfDots, (index) {
        return [
          (index == _selected)
              ? (widget.activeDotBuilder?.call() ??
                  _selectedDefaultLoadingDot())
              : (widget.inactiveDotBuilder?.call() ??
                  _unselectedDefaultLoadingDot()),
          (index != widget.numberOfDots - 1)
              ? SizedBox(width: widget.innerPadding)
              : null
        ];
      }).flattened.whereNotNull().toList(),
    );
  }
}
