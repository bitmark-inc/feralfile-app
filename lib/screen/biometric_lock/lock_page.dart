import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:overlay_support/overlay_support.dart';

Duration kLockingAnimationDuration = const Duration(milliseconds: 300);
const _authenticationReason = 'Authentication for "Autonomy"';
OverlaySupportEntry? _currentLockingScreen;

class LockingOverlay extends StatelessWidget {
  final LocalAuthentication localAuth;
  final double progress;

  LockingOverlay({Key? key, required this.progress, required this.localAuth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
        opacity: progress,
        child: Container(
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
        ));
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
    return FutureBuilder<List<BiometricType>>(
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (Platform.isIOS) {
            if (snapshot.data!.contains(BiometricType.face)) {
              // Face ID.
              return SvgPicture.asset('assets/images/face_id.svg',
                  height: 64, width: 64);
            } else if (snapshot.data!.contains(BiometricType.fingerprint)) {
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
        } else {
          return SizedBox();
        }
      },
      future: localAuth.getAvailableBiometrics(),
    );
  }

  Future<void> _authenticate() async {
    bool didAuthenticate =
        await localAuth.authenticate(localizedReason: _authenticationReason);

    if (didAuthenticate) _hideOverlayLockingScreen();
  }
}

Future<dynamic>? showOverlayLockingScreen({
  BuildContext? context,
}) {
  final overlayKey = ValueKey<String>("locking_screen");
  final localAuthentication = LocalAuthentication();
  _currentLockingScreen = showOverlay(
    (context, t) {
      return LockingOverlay(
        progress: t,
        localAuth: localAuthentication,
      );
    },
    animationDuration: kLockingAnimationDuration,
    reverseAnimationDuration: kLockingAnimationDuration,
    duration: Duration(),
    key: overlayKey,
    context: context,
  );

  Future.delayed(
      kLockingAnimationDuration,
      () => localAuthentication.authenticate(
          localizedReason: _authenticationReason)).then((didAuthenticate) {
    if (didAuthenticate) _hideOverlayLockingScreen();
  });

  return _currentLockingScreen?.dismissed;
}

void _hideOverlayLockingScreen() {
  _currentLockingScreen?.dismiss(animate: true);
}
