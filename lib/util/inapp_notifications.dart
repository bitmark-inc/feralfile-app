import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:overlay_support/overlay_support.dart';

Widget _notificationToast(OSNotification notification) {
  return Container(
    color: AppColorTheme.primaryColor,
    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notification.title != null) ...[
          Text(
            notification.title!,
            textAlign: TextAlign.left,
            style: appTextTheme.headline4,
          ),
        ],
        SizedBox(
          height: 12.0,
        ),
        if (notification.body != null) ...[
          Text(
            notification.body!,
            textAlign: TextAlign.left,
            style: appTextTheme.bodyText1,
          ),
        ]
      ],
    ),
  );
}

void showNotifications(OSNotification notification) {
  showSimpleNotification(_notificationToast(notification),
      background: Colors.transparent,
      duration: Duration(seconds: 2),
      elevation: 0,
      slideDismissDirection: DismissDirection.up);
}
