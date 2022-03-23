import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';

class LockingOverlay extends ModalRoute<void> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  List<BiometricType> _availableBiometrics = List.empty();
  @override
  Duration get transitionDuration => Duration(milliseconds: 300);

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  void install() {
    super.install();
    _getAvailableBiometrics();
  }

  @override
  TickerFuture didPush() {
    Future.delayed(Duration(milliseconds: 700), _authenticate);
    return super.didPush();
  }

  void _getAvailableBiometrics() async {
    _availableBiometrics = await _localAuth.getAvailableBiometrics();
    setState(() {});
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This makes sure that text and other content follows the material style
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Center(
            child: _logo(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  child: _authenticationView(),
                  onTap: _authenticate,
                ),
              ),
              SizedBox(height: 40),
            ],
          )
        ],
      ),
    );
  }

  Widget _logo() {
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.asset(
              "assets/images/lock_penrose_appcenter.png",
              width: 165,
              fit: BoxFit.contain,
            );
          } else {
            return SvgPicture.asset(
              "assets/images/lock_penrose.svg",
              fit: BoxFit.contain,
            );
          }
        });
  }

  Widget _authenticationView() {
    if (Platform.isIOS) {
      if (_availableBiometrics.contains(BiometricType.face)) {
        // Face ID.
        return SvgPicture.asset('assets/images/face_id.svg',
            height: 64, width: 64);
      } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
        // Touch ID.
        return SvgPicture.asset('assets/images/touch_id.svg',
            height: 64, width: 64);
      }
    }

    return Text("ENTER PASSCODE",
        style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: "IBMPlexMono"));
  }

  Future<void> _authenticate() async {
    bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authentication for "Autonomy"');

    if (didAuthenticate) {
      injector<NavigationService>().unlockScreen();
    }
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
