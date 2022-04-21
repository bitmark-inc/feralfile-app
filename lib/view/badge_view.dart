import 'package:flutter/material.dart';

class BadgeView extends StatelessWidget {
  final int number;
  const BadgeView({Key? key, required this.number}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
        child: Text(
          '$number',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: "AtlasGrotesk",
              fontWeight: FontWeight.w700,
              height: 1.377),
        ));
  }
}
