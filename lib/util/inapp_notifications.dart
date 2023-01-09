//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:overlay_support/overlay_support.dart';
// ignore: implementation_imports
import 'package:overlay_support/src/overlay_state_finder.dart';

Widget _notificationToast(BuildContext context, OSNotification notification,
    {Function(OSNotification notification)? notificationOpenedHandler}) {
  return _SimpleNotificationToast(
    notification: notification.body ?? "",
    key: Key(notification.notificationId),
    notificationOpenedHandler: () {
      if (notificationOpenedHandler != null) {
        notificationOpenedHandler(notification);
      }
    },
    addOnTextSpan: [
      TextSpan(
        text: ' ${'tap_to_view'.tr()}',
        style: Theme.of(context).textTheme.ppMori400Green14,
      )
    ],
  );
}

class _SimpleNotificationToast extends StatelessWidget {
  const _SimpleNotificationToast({
    required Key key,
    required this.notification,
    this.notificationOpenedHandler,
    this.frontWidget,
    this.addOnTextSpan,
  }) : super(key: key);
  final String notification;
  final Function()? notificationOpenedHandler;
  final Widget? frontWidget;
  final List<InlineSpan>? addOnTextSpan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: GestureDetector(
        onTap: () {
          hideOverlay(key!);
          if (notificationOpenedHandler != null) {
            notificationOpenedHandler?.call();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 60),
          decoration: BoxDecoration(
            color: theme.auGreyBackground,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              frontWidget ?? const SizedBox(),
              SizedBox(
                width: frontWidget != null ? 8 : 0,
              ),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    text: notification,
                    style: theme.textTheme.ppMori400White14,
                    children: addOnTextSpan,
                  ),
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

void showNotifications(BuildContext context, OSNotification notification,
    {Function(OSNotification notification)? notificationOpenedHandler}) {
  showSimpleNotification(
    _notificationToast(context, notification,
        notificationOpenedHandler: notificationOpenedHandler),
    background: Colors.transparent,
    duration: const Duration(seconds: 3),
    elevation: 0,
    key: Key(notification.notificationId),
    slideDismissDirection: DismissDirection.up,
  );
  Vibrate.feedback(FeedbackType.warning);
}

void showInfoNotification(
  Key key,
  String info, {
  Duration? duration,
  Widget? frontWidget,
  dynamic Function()? openHandler,
  List<InlineSpan>? addOnTextSpan,
}) {
  showSimpleNotification(
      _SimpleNotificationToast(
        key: key,
        notification: info,
        notificationOpenedHandler: openHandler,
        frontWidget: frontWidget,
        addOnTextSpan: addOnTextSpan,
      ),
      key: key,
      background: Colors.transparent,
      duration: duration ?? const Duration(seconds: 3),
      elevation: 0,
      slideDismissDirection: DismissDirection.up);

  Vibrate.feedback(FeedbackType.light);
}

void showCustomNotifications(BuildContext context, String notification, Key key,
    {Function()? notificationOpenedHandler}) {
  showSimpleNotification(
      _SimpleNotificationToast(
          notification: notification,
          key: key,
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

  overlayEntry?.dismiss();
}
