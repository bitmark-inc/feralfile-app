import 'dart:math';

import 'package:autonomy_flutter/util/style.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class AllConfettiWidget extends StatefulWidget {
  final ConfettiController controller;

  const AllConfettiWidget({
    required this.controller,
    super.key,
  });

  @override
  State<AllConfettiWidget> createState() => _AllConfettiWidgetState();
}

class _AllConfettiWidgetState extends State<AllConfettiWidget> {
  final double blastDirection = -pi / 2;

  @override
  Widget build(BuildContext context) => buildConfetti();

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
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: widget.controller,
        colors: moMAColors,
        blastDirectionality: BlastDirectionality.explosive,
        emissionFrequency: 0,
        numberOfParticles: 50,
      ),
    );
  }
}
