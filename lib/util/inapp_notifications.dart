import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:overlay_support/src/overlay_state_finder.dart';

Widget _notificationToast(OSNotification notification,
    {Function(OSNotification notification)? notificationOpenedHandler}) {
  return _simpleNotificationToast(
      notification.body ?? "", Key(notification.notificationId),
      notificationOpenedHandler: () {
    if (notificationOpenedHandler != null) {
      notificationOpenedHandler(notification);
    }
  });
}

Widget _simpleNotificationToast(String notification, Key key,
    {Function()? notificationOpenedHandler}) {
  return ClipPath(
      clipper: AutonomyButtonClipper(),
      child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 68),
          child: GestureDetector(
              onTap: () {
                hideOverlay(key);
                if (notificationOpenedHandler != null)
                  notificationOpenedHandler();
              },
              child: Container(
                color: Colors.black.withOpacity(0.8),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Center(
                    child: Text(
                  notification,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: "IBMPlexMono"),
                )),
              ))));
}

void showNotifications(OSNotification notification,
    {Function(OSNotification notification)? notificationOpenedHandler}) {
  showSimpleNotification(
      _notificationToast(notification,
          notificationOpenedHandler: notificationOpenedHandler),
      background: Colors.transparent,
      duration: Duration(seconds: 3),
      elevation: 0,
      autoDismiss: true,
      key: Key(notification.notificationId),
      slideDismissDirection: DismissDirection.up);
  Vibrate.feedback(FeedbackType.warning);
}

void showCustomNotifications(String notification, Key key,
    {Function()? notificationOpenedHandler}) {
  showSimpleNotification(
      _simpleNotificationToast(notification, key,
          notificationOpenedHandler: notificationOpenedHandler),
      background: Colors.transparent,
      elevation: 0,
      autoDismiss: false,
      key: key,
      slideDismissDirection: DismissDirection.up);
  Vibrate.feedback(FeedbackType.warning);
}

void hideOverlay(Key key) {
  final OverlaySupportState? overlaySupport = findOverlayState();
  if (overlaySupport == null) {
    log.warning("Cannot find overlay key: $key");
    return;
  }

  final overlayEntry = overlaySupport.getEntry(key: key);

  overlayEntry?.dismiss(animate: true);
}
