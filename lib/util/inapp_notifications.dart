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
        {Function(OSNotification notification)? notificationOpenedHandler}) =>
    _SimpleNotificationToast(
      notification: notification.body ?? '',
      key: Key(notification.notificationId),
      notificationOpenedHandler: () {
        if (notificationOpenedHandler != null) {
          notificationOpenedHandler(notification);
        }
      },
      addOnTextSpan: [
        TextSpan(
          text: ' ${'tap_to_view'.tr()}',
          style: Theme.of(context).textTheme.ppMori400FFYellow14,
        )
      ],
    );

Widget _inAppNotificationToast(BuildContext context, String body, String key,
        {Function()? notificationOpenedHandler}) =>
    _SimpleNotificationToast(
      notification: body,
      key: Key(key),
      notificationOpenedHandler: notificationOpenedHandler,
      addOnTextSpan: [
        TextSpan(
          text: ' ${'tap_to_view'.tr()}',
          style: Theme.of(context).textTheme.ppMori400FFYellow14,
        )
      ],
    );

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

class _NotificationToastWithLink extends StatelessWidget {
  const _NotificationToastWithLink({
    required Key key,
    required this.notification,
    this.notificationOpenedHandler,
    this.frontWidget,
    this.bottomRightWidget,
    this.addOnTextSpan,
  }) : super(key: key);
  final String notification;
  final Function()? notificationOpenedHandler;
  final Widget? frontWidget;
  final Widget? bottomRightWidget;
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
          padding: const EdgeInsets.fromLTRB(15, 40, 15, 10),
          decoration: BoxDecoration(
            color: theme.auGreyBackground,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (frontWidget != null) ...[
                    frontWidget!,
                    const SizedBox(width: 8),
                  ],
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
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  bottomRightWidget ?? const SizedBox(),
                ],
              ),
            ],
          ),
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

void showInAppNotifications(BuildContext context, String body, String key,
    {Function()? notificationOpenedHandler}) {
  showSimpleNotification(
    _inAppNotificationToast(context, body, '',
        notificationOpenedHandler: notificationOpenedHandler),
    background: Colors.transparent,
    duration: const Duration(seconds: 3),
    elevation: 0,
    key: Key(key),
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

void showInfoNotificationWithLink(
  Key key,
  String info, {
  Duration? duration,
  Widget? frontWidget,
  Widget? bottomRightWidget,
  dynamic Function()? openHandler,
  List<InlineSpan>? addOnTextSpan,
}) {
  showSimpleNotification(
      _NotificationToastWithLink(
        key: key,
        notification: info,
        notificationOpenedHandler: openHandler,
        frontWidget: frontWidget,
        bottomRightWidget: bottomRightWidget,
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
    log.warning('Cannot find overlay key: $key');
    return;
  }

  final overlayEntry = overlaySupport.getEntry(key: key);

  overlayEntry?.dismiss();
}
