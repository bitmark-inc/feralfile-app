//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_box_view.dart';
import 'package:autonomy_flutter/screen/survey/survey.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:share/share.dart';

enum ActionState { notRequested, loading, error, done }

const SHOW_DIALOG_DURATION = Duration(seconds: 2);
const SHORT_SHOW_DIALOG_DURATION = Duration(seconds: 1);

void doneOnboarding(BuildContext context) async {
  injector<ConfigurationService>().setDoneOnboarding(true);
  Navigator.of(context)
      .pushNamedAndRemoveUntil(AppRouter.homePage, (route) => false);

  await askForNotification();
  Future.delayed(
      SHORT_SHOW_DIALOG_DURATION, () => showSurveysNotification(context));
}

Future askForNotification() async {
  if (injector<ConfigurationService>().isNotificationEnabled() != null) {
    // Skip asking for notifications
    return;
  }

  await Future<dynamic>.delayed(const Duration(seconds: 1), () async {
    final context = injector<NavigationService>().navigatorKey.currentContext;
    if (context == null) return null;

    return await Navigator.of(context).pushNamed(
        AppRouter.notificationOnboardingPage,
        arguments: {"isOnboarding": false});
  });
}

void showSurveysNotification(BuildContext context) {
  if (!injector<ConfigurationService>().isDoneOnboarding()) {
    // If the onboarding is not finished, skip this time.
    return;
  }

  final finishedSurveys = injector<ConfigurationService>().getFinishedSurveys();
  if (finishedSurveys.contains(Survey.onboarding)) {
    return;
  }

  showCustomNotifications(
      context,
      "Take a one-question survey and be entered to win a Feral File artwork.",
      const Key(Survey.onboarding),
      notificationOpenedHandler: () =>
          injector<NavigationService>().navigateTo(SurveyPage.tag));
}

Future newAccountPageOrSkipInCondition(BuildContext context) async {
  if (memoryValues.linkedFFConnections?.isNotEmpty ?? false) {
    doneOnboarding(context);
  } else {
    Navigator.of(context).pushNamed(AppRouter.newAccountPage);
  }
}

class UIHelper {
  static String currentDialogTitle = '';

  static Future<void> showDialog(
      BuildContext context, String title, Widget content,
      {bool isDismissible = false,
      int autoDismissAfter = 0,
      FeedbackType? feedback = FeedbackType.selection}) async {
    log.info("[UIHelper] showInfoDialog: $title");
    currentDialogTitle = title;
    final theme = Theme.of(context);

    if (autoDismissAfter > 0) {
      Future.delayed(
          Duration(seconds: autoDismissAfter), () => hideInfoDialog(context));
    }

    if (feedback != null) {
      Vibrate.feedback(feedback);
    }

    await showModalBottomSheet<dynamic>(
        context: context,
        isDismissible: isDismissible,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            color: Colors.transparent,
            child: ClipPath(
              clipper: AutonomyTopRightRectangleClipper(),
              child: Container(
                color: theme.colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.primaryTextTheme.headline1),
                      const SizedBox(height: 40),
                      content,
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  static Future<void> showInfoDialog(
      BuildContext context, String title, String description,
      {bool isDismissible = false,
      int autoDismissAfter = 0,
      String closeButton = "",
      FeedbackType? feedback = FeedbackType.selection}) async {
    log.info("[UIHelper] showInfoDialog: $title, $description");
    final theme = Theme.of(context);

    if (autoDismissAfter > 0) {
      Future.delayed(
          Duration(seconds: autoDismissAfter), () => hideInfoDialog(context));
    }

    await showDialog(
        context,
        title,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              Text(
                description,
                style: theme.primaryTextTheme.bodyText1,
              ),
            ],
            const SizedBox(height: 40),
            if (closeButton.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        closeButton,
                        style: theme.primaryTextTheme.button,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ]
          ],
        ),
        isDismissible: isDismissible,
        feedback: feedback);
  }

  static hideInfoDialog(BuildContext context) {
    currentDialogTitle = '';
    try {
      Navigator.popUntil(context, (route) => route.settings.name != null);
    } catch (_) {}
  }

  static Future<void> showLinkRequestedDialog(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog(
        context,
        'Link requested',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  style: theme.primaryTextTheme.bodyText1,
                  text: "Autonomy has sent a request to ",
                ),
                TextSpan(
                  style: theme.primaryTextTheme.headline4,
                  text: "Feral File",
                ),
                TextSpan(
                  style: theme.primaryTextTheme.bodyText1,
                  text:
                      " in your mobile browser to link to your account. Please make sure you are signed in and authorize the request.",
                ),
              ]),
            ),
            const SizedBox(height: 67),
          ],
        ),
        isDismissible: true);
  }

  static Future showFFAccountLinked(BuildContext context, String alias,
      {bool inOnboarding = false}) {
    final theme = Theme.of(context);
    return showDialog(
        context,
        'Account linked',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  style: theme.primaryTextTheme.bodyText1,
                  text:
                      "Autonomy has received authorization to link to your Feral File account ",
                ),
                TextSpan(
                  style: theme.primaryTextTheme.headline4,
                  text: alias,
                ),
                TextSpan(
                  style: theme.primaryTextTheme.bodyText1,
                  text:
                      ". ${inOnboarding ? 'Please finish onboarding to view your collection.' : ''}",
                ),
              ]),
            ),
            const SizedBox(height: 67),
          ],
        ),
        isDismissible: true,
        autoDismissAfter: 5);
  }

  // MARK: - Connection
  static Widget buildConnectionAppWidget(Connection connection, double size) {
    switch (connection.connectionType) {
      case 'dappConnect':
        final remotePeerMeta =
            connection.wcConnection?.sessionStore.remotePeerMeta;
        final appIcons = remotePeerMeta?.icons ?? [];
        if (appIcons.isEmpty) {
          return SizedBox(
              width: size,
              height: size,
              child:
                  Image.asset("assets/images/walletconnect-alternative.png"));
        } else {
          return CachedNetworkImage(
            imageUrl: appIcons.first,
            width: size,
            height: size,
            errorWidget: (context, url, error) => SizedBox(
              width: size,
              height: size,
              child: Image.asset("assets/images/walletconnect-alternative.png"),
            ),
          );
        }

      case 'beaconP2PPeer':
        final appIcon = connection.beaconConnectConnection?.peer.icon;
        if (appIcon == null || appIcon.isEmpty) {
          return SvgPicture.asset(
            "assets/images/tezos_social_icon.svg",
            width: size,
            height: size,
          );
        } else {
          return CachedNetworkImage(
            imageUrl: appIcon,
            width: size,
            height: size,
            errorWidget: (context, url, error) => SvgPicture.asset(
              "assets/images/tezos_social_icon.svg",
              width: size,
              height: size,
            ),
          );
        }

      default:
        return const SizedBox();
    }
  }

  // MARK: - Persona
  static showGeneratedPersonaDialog(BuildContext context,
      {required Function() onContinue}) {
    final theme = Theme.of(context);

    showDialog(
        context,
        "Generated!",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MULTI-CHAIN ACCOUNT GENERATED WITH:',
                style: theme.primaryTextTheme.headline5),
            const SizedBox(height: 16),
            Text('• Bitmark address', style: theme.primaryTextTheme.headline4),
            const SizedBox(height: 16),
            Text('• Ethereum address', style: theme.primaryTextTheme.headline4),
            const SizedBox(height: 16),
            Text('• Tezos address', style: theme.primaryTextTheme.headline4),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "CONTINUE",
                    onPress: () => onContinue(),
                    color: theme.colorScheme.secondary,
                    textStyle: theme.textTheme.button,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ));
  }

  static showImportedPersonaDialog(BuildContext context,
      {required Function() onContinue}) {
    final theme = Theme.of(context);

    showDialog(
        context,
        "Imported!",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MULTI-CHAIN ACCOUNT GENERATED WITH:',
                style: theme.primaryTextTheme.headline5),
            const SizedBox(height: 16),
            Text('• Bitmark address', style: theme.primaryTextTheme.headline4),
            const SizedBox(height: 16),
            Text('• Ethereum address', style: theme.primaryTextTheme.headline4),
            const SizedBox(height: 16),
            Text('• Tezos address', style: theme.primaryTextTheme.headline4),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "CONTINUE",
                    onPress: () => onContinue(),
                    color: theme.colorScheme.secondary,
                    textStyle: theme.textTheme.button,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ));
  }

  static showHideArtworkResultDialog(BuildContext context, bool isHidden,
      {required Function() onOK}) {
    final theme = Theme.of(context);

    showDialog(
        context,
        isHidden ? "Artwork hidden" : "Artwork unhidden",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isHidden
                ? RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        style: theme.primaryTextTheme.bodyText1,
                        text:
                            "This artwork will no longer appear in your collection. You can still find it in the ",
                      ),
                      TextSpan(
                        style: theme.primaryTextTheme.headline4,
                        text: "Hidden artworks >",
                      ),
                      TextSpan(
                        style: theme.primaryTextTheme.bodyText1,
                        text:
                            " section of settings if you want to view it or unhide it.",
                      ),
                    ]),
                  )
                : Text(
                    "This artwork will now be visible in your collection.",
                    style: theme.primaryTextTheme.bodyText1,
                  ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "OK",
                    onPress: onOK,
                    color: theme.primaryColor,
                    textStyle: theme.primaryTextTheme.button,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ));
  }

  static showIdentityDetailDialog(BuildContext context,
      {required String name, required String address}) {
    final theme = Theme.of(context);

    showDialog(
        context,
        "Identity",
        Flexible(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ALIAS', style: theme.primaryTextTheme.headline5),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text(
                name,
                style: theme.primaryTextTheme.headline4,
                overflow: TextOverflow.ellipsis,
              )),
              GestureDetector(
                child: Text("Share", style: theme.primaryTextTheme.headline4),
                onTap: () => Share.share(address),
              )
            ]),
            const SizedBox(height: 16),
            Text(
              address,
              style: theme.textTheme.ibmWhiteNormal14,
            ),
            const SizedBox(height: 56),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "CLOSE",
                style: theme.primaryTextTheme.button,
              ),
            ),
            const SizedBox(height: 15),
          ],
        )));
  }

  static showAccountLinked(
      BuildContext context, Connection connection, String walletName) {
    UIHelper.showInfoDialog(context, "Account linked",
        "Autonomy has received autorization to link to your NFTs in $walletName.");

    Future.delayed(const Duration(seconds: 3), () {
      UIHelper.hideInfoDialog(context);

      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context)
            .pushNamed(AppRouter.nameLinkedAccountPage, arguments: connection);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.nameLinkedAccountPage, (route) => false,
            arguments: connection);
      }
    });
  }

  static showAlreadyLinked(BuildContext context, Connection connection) {
    UIHelper.hideInfoDialog(context);
    showErrorDiablog(
        context,
        ErrorEvent(
            null,
            "Already linked",
            "You’ve already linked this account to Autonomy.",
            ErrorItemState.seeAccount), defaultAction: () {
      Navigator.of(context)
          .pushNamed(AppRouter.linkedAccountDetailsPage, arguments: connection);
    });
  }

  static showAbortedByUser(BuildContext context) {
    UIHelper.showInfoDialog(
        context, "Aborted", "The action was aborted by the user.",
        isDismissible: true, autoDismissAfter: 3);
  }

  static Future showFeatureRequiresSubscriptionDialog(
      BuildContext context, PremiumFeature feature) {
    final theme = Theme.of(context);

    return showDialog(
        context,
        "Subscribe",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This feature requires subscription',
                style: theme.primaryTextTheme.bodyText1),
            const SizedBox(height: 40),
            UpgradeBoxView.getMoreAutonomyWidget(theme, feature),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CANCEL",
                      style: theme.primaryTextTheme.button,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
        isDismissible: true);
  }
}

learnMoreAboutAutonomySecurityWidget(BuildContext context,
    {String title = 'Learn more about Autonomy security ...'}) {
  final theme = Theme.of(context);
  return TextButton(
    onPressed: () =>
        Navigator.of(context).pushNamed(AppRouter.autonomySecurityPage),
    style: TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(title, style: theme.textTheme.linkStyle),
  );
}

wantMoreSecurityWidget(BuildContext context, WalletApp walletApp) {
  var introText = 'You can get all the';
  if (walletApp == WalletApp.Kukai || walletApp == WalletApp.Temple) {
    introText += ' Tezos';
  }
  introText +=
      ' functionality of ${walletApp.rawValue} in a mobile app by importing your account to Autonomy. Tap to do this now.';
  final theme = Theme.of(context);
  return GestureDetector(
    onTap: () => Navigator.of(context).pushNamed(AppRouter.importAccountPage),
    child: Container(
      padding: const EdgeInsets.all(10),
      color: AppColor.secondaryDimGreyBackground,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Want more security and portability?',
            style: theme.textTheme.atlasDimgreyBold14),
        const SizedBox(height: 5),
        Text(introText, style: theme.textTheme.atlasBlackNormal14),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRouter.unsafeWebWalletPage),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Learn why browse-extension wallets are unsafe...',
              style: theme.textTheme.linkStyle),
        ),
      ]),
    ),
  );
}

String getDateTimeRepresentation(DateTime dateTime) {
  return Jiffy(dateTime).fromNow();
}

// From chat_ui/util
String getVerboseDateTimeRepresentation(
  DateTime dateTime, {
  DateFormat? dateFormat,
  String? dateLocale,
  DateFormat? timeFormat,
}) {
  final formattedDate = dateFormat != null
      ? dateFormat.format(dateTime)
      : DateFormat.MMMd(dateLocale).format(dateTime);
  final formattedTime = timeFormat != null
      ? timeFormat.format(dateTime)
      : DateFormat.Hm(dateLocale).format(dateTime);
  final localDateTime = dateTime.toLocal();
  final now = DateTime.now();

  if (localDateTime.day == now.day &&
      localDateTime.month == now.month &&
      localDateTime.year == now.year) {
    return formattedTime;
  }

  if (Jiffy(localDateTime).week == Jiffy(now).week) {
    return Jiffy(localDateTime).format("EE");
  }

  return '$formattedDate, $formattedTime';
}
