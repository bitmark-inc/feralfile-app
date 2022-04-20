import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:overlay_support/overlay_support.dart';

Widget _notificationToast(OSNotification notification) {
  return ClipPath(
      clipper: AutonomyButtonClipper(),
      child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 68),
          child: Container(
            color: Colors.black.withOpacity(0.8),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Center(
                child: Text(
              notification.body?.toUpperCase() ?? "",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: "IBMPlexMono"),
            )),
          )));
}

void showNotifications(OSNotification notification) {
  showSimpleNotification(_notificationToast(notification),
      background: Colors.transparent,
      duration: Duration(seconds: 3),
      elevation: 0,
      slideDismissDirection: DismissDirection.up);
  Vibrate.feedback(FeedbackType.warning);
}
