import 'package:flutter/material.dart';

const appTextTheme = TextTheme(
  headline1: TextStyle(
      color: Colors.black,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      fontFamily: "AtlasGrotesk"),
  headline2: TextStyle(
      color: Colors.black,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      fontFamily: "AtlasGrotesk"),
  headline3: TextStyle(
      color: Colors.black,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      fontFamily: "AtlasGrotesk"),
  headline4: TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      fontFamily: "AtlasGrotesk-Bold",
      height: 1.377),
  headline5:
      TextStyle(color: Colors.black, fontSize: 12, fontFamily: "AtlasGrotesk"),
  button: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFamily: "IBMPlexMono"),
  caption: TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFamily: "IBMPlexMono"),
  bodyText1: TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontFamily: "AtlasGrotesk",
      height: 1.377),
  bodyText2: TextStyle(
      color: Color(0xFF6D6B6B), fontSize: 16, fontFamily: "IBMPlexMono"),
);

const copiedTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 12,
  fontFamily: "AtlasGrotesk-Bold",
  fontWeight: FontWeight.bold,
);

const bodySmall = TextStyle(
    color: Colors.black,
    fontSize: 14,
    fontFamily: "AtlasGrotesk",
    fontWeight: FontWeight.w300,
    height: 1.377);

const linkStyle = TextStyle(
  color: Colors.transparent,
  fontSize: 14,
  fontFamily: "AtlasGrotesk",
  height: 1.377,
  shadows: [Shadow(color: Colors.black, offset: Offset(0, -3))],
  decoration: TextDecoration.underline,
  decorationStyle: TextDecorationStyle.solid,
  decorationColor: Colors.black,
  decorationThickness: 1.2,
);

const paragraph = TextStyle(
    color: AppColorTheme.secondaryDimGrey,
    fontSize: 12,
    fontFamily: "AtlasGrotesk",
    fontWeight: FontWeight.w400,
    height: 1.4);

SizedBox addTitleSpace() {
  return const SizedBox(height: 40);
}

Divider addDivider() {
  return const Divider(height: 32.0);
}

const pageEdgeInsets =
    EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0);
const pageEdgeInsetsWithSubmitButton = EdgeInsets.fromLTRB(16, 16, 16, 40);

class AppColorTheme {
  static const scaffoldBackgroundColor = Colors.white;
  static const secondaryHeaderColor = Color(0xFF6D6B6B);
  static const primaryColor = Colors.grey;
  static const barBackgroundColor = Color(0xFF6D6B6B);
  static const errorColor = Color(0xFFA1200A);
  static const textColor = Colors.grey;
  static const secondaryDimGrey = Color(0xFF6D6B6B);
  static const secondaryDimGreyBackground = Color(0xFFEDEDED);
}

final grantPermissions = const [
  'View account balance and NFTs',
  'Request approval for transactions',
];

String polishSource(String source) {
  switch (source) {
    case 'feralfile':
      return 'Feral File';
    case 'ArtBlocks':
      return 'Art Blocks';
    default:
      return source;
  }
}
