import 'dart:math';

import 'package:autonomy_flutter/util/style.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class AllConfettiWidget extends StatefulWidget {
  final ConfettiController controller;

  const AllConfettiWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);
  @override
  State<AllConfettiWidget> createState() => _AllConfettiWidgetState();
}

class _AllConfettiWidgetState extends State<AllConfettiWidget> {
  final double blastDirection = pi / 2;

  @override
  Widget build(BuildContext context) {
    return buildConfetti();
  }

  Widget buildConfetti() {
    List<Color> moMAColors = [
      MomaPallet.pink,
      MomaPallet.red,
      MomaPallet.brick,
      MomaPallet.lightBrick,
      MomaPallet.orange,
      MomaPallet.lightYellow,
      MomaPallet.bananaYellow,
      MomaPallet.green,
      MomaPallet.riverGreen,
      MomaPallet.cloudBlue,
      MomaPallet.blue,
      MomaPallet.purple,
    ];
    return Align(
      child: ConfettiWidget(
        confettiController: widget.controller,
        colors: moMAColors,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: true,
        emissionFrequency: 0.0,
        numberOfParticles: 30,
      ),
    );
  }
}
