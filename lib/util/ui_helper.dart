// ignore_for_file: public_member_api_docs, sort_constructors_first
//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/wc2_proposal.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_box_view.dart';
import 'package:autonomy_flutter/screen/survey/survey.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:jiffy/jiffy.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:share/share.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

enum ActionState { notRequested, loading, error, done }

const SHOW_DIALOG_DURATION = Duration(seconds: 2);
const SHORT_SHOW_DIALOG_DURATION = Duration(seconds: 1);

void doneOnboarding(BuildContext context) async {
  injector<IAPService>().restore();
  await injector<ConfigurationService>().setPendingSettings(true);
  await injector<ConfigurationService>().setDoneOnboarding(true);
  injector<MetricClientService>().mixPanelClient.initIfDefaultAccount();
  injector<NavigationService>()
      .navigateUntil(AppRouter.homePage, (route) => false);

  // await askForNotification();
  // Future.delayed(
  //     SHORT_SHOW_DIALOG_DURATION, () => showSurveysNotification(context));
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
      context, "take_survey".tr(), const Key(Survey.onboarding),
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
  static final metricClient = injector.get<MetricClientService>();

  static Future<void> showDialog(
      BuildContext context, String title, Widget content,
      {bool isDismissible = false,
      isRoundCorner = true,
      Color? backgroundColor,
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
      constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.isMobile
              ? double.infinity
              : Constants.maxWidthModalTablet),
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Container(
          color: Colors.transparent,
          child: ClipPath(
            clipper: isRoundCorner ? null : AutonomyTopRightRectangleClipper(),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? theme.auGreyBackground,
                borderRadius: isRoundCorner
                    ? const BorderRadius.only(
                        topRight: Radius.circular(20),
                      )
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.primaryTextTheme.ppMori700White24),
                    const SizedBox(height: 40),
                    content,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> showMessageAction(
    BuildContext context,
    String title,
    String description, {
    bool isDismissible = false,
    int autoDismissAfter = 0,
    String? closeButton,
    Function? onClose,
    FeedbackType? feedback = FeedbackType.selection,
    String? actionButton,
    Function? onAction,
    Widget? descriptionWidget,
  }) async {
    log.info("[UIHelper] showInfoDialog: $title, $description");
    final theme = Theme.of(context);

    if (autoDismissAfter > 0) {
      Future.delayed(
          Duration(seconds: autoDismissAfter), () => hideInfoDialog(context));
    }

    await showDialog(
      context,
      title,
      SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: theme.primaryTextTheme.ppMori400White14,
            ),
          ],
          descriptionWidget ?? const SizedBox.shrink(),
          const SizedBox(height: 40),
          if (onAction != null) ...[
            PrimaryButton(
              onTap: () => onAction.call(),
              text: actionButton ?? '',
            ),
            const SizedBox(height: 10),
          ],
          OutlineButton(
            onTap: () => onClose?.call() ?? Navigator.pop(context),
            text: closeButton ?? 'cancel_dialog'.tr(),
          ),
          const SizedBox(height: 15),
        ]),
      ),
      isDismissible: isDismissible,
      feedback: feedback,
    );
  }

  static Future<void> showMessageActionNew(
    BuildContext context,
    String title,
    String description, {
    bool isDismissible = false,
    int autoDismissAfter = 0,
    String? closeButton,
    Function? onClose,
    FeedbackType? feedback = FeedbackType.selection,
    String? actionButton,
    Function? onAction,
    Widget? descriptionWidget,
  }) async {
    log.info("[UIHelper] showInfoDialog: $title, $description");
    final theme = Theme.of(context);

    if (autoDismissAfter > 0) {
      Future.delayed(
          Duration(seconds: autoDismissAfter), () => hideInfoDialog(context));
    }

    await showDialog(
      context,
      title,
      SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              Text(
                description,
                style: theme.primaryTextTheme.ppMori400White14,
              ),
            ],
            descriptionWidget ?? const SizedBox.shrink(),
            const SizedBox(height: 40),
            if (onAction != null) ...[
              PrimaryButton(
                onTap: () => onAction.call(),
                text: actionButton ?? '',
              ),
              const SizedBox(
                height: 10,
              ),
            ],
            OutlineButton(
              onTap: () => onClose?.call() ?? Navigator.pop(context),
              text: closeButton ?? 'cancel_dialog'.tr(),
            ),
          ],
        ),
      ),
      isDismissible: isDismissible,
      feedback: feedback,
    );
  }

  static Future<void> showDialogAction(BuildContext context,
      {List<OptionItem>? options}) async {
    final theme = Theme.of(context);

    Widget optionRow({required String title, Function()? onTap}) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.primaryTextTheme.headline4),
              Icon(Icons.navigate_next, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      );
    }

    UIHelper.showDialog(
      context,
      "Options",
      ListView.separated(
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) =>
            index != options?.length
                ? optionRow(
                    title: options?[index].title ?? '',
                    onTap: options?[index].onTap)
                : TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "cancel".tr(),
                      style: theme.primaryTextTheme.button,
                    ),
                  ),
        itemCount: (options?.length ?? 0) + 1,
        separatorBuilder: (context, index) =>
            index == (options?.length ?? 0) - 1
                ? const SizedBox.shrink()
                : Divider(
                    height: 1,
                    thickness: 1.0,
                    color: theme.colorScheme.surface,
                  ),
      ),
      isDismissible: true,
    );
  }

  static Future<void> showInfoDialog(
      BuildContext context, String title, String description,
      {bool isDismissible = false,
      int autoDismissAfter = 0,
      String closeButton = "",
      VoidCallback? onClose,
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
      SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              Text(
                description,
                style: theme.primaryTextTheme.ppMori400White14,
              ),
            ],
            const SizedBox(height: 40),
            if (closeButton.isNotEmpty && onClose == null) ...[
              const SizedBox(height: 16),
              OutlineButton(
                onTap: () => Navigator.pop(context),
                text: closeButton,
              ),
              const SizedBox(height: 15),
            ] else if (closeButton.isNotEmpty && onClose != null) ...[
              const SizedBox(height: 16),
              OutlineButton(
                onTap: onClose,
                text: closeButton,
              ),
              const SizedBox(height: 15),
            ]
          ],
        ),
      ),
      isDismissible: isDismissible,
      feedback: feedback,
    );
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
      'link_requested'.tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                style: theme.primaryTextTheme.bodyText1,
                text: "au_sent_survey".tr(),
              ),
              TextSpan(
                style: theme.primaryTextTheme.headline4,
                text: "feral_file".tr(),
              ),
              TextSpan(
                style: theme.primaryTextTheme.bodyText1,
                text: "in_your_mobile".tr(),
              ),
            ]),
          ),
          const SizedBox(height: 67),
        ],
      ),
      isDismissible: true,
    );
  }

  static Future<void> showUnavailableCastDialog({
    required BuildContext context,
    Function()? dontShowAgain,
    AssetToken? assetToken,
  }) {
    final theme = Theme.of(context);
    final isPDFArtwork = assetToken?.mimeType == 'application/pdf';
    return showDialog(
      context,
      'unavailable_cast'.tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/images/cast_icon.svg',
                color: theme.disableColor,
              ),
              const SizedBox(
                width: 17,
              ),
              Expanded(
                child: Text(
                  isPDFArtwork
                      ? 'unavailable_cast_pdf_des'.tr()
                      : 'unavailable_cast_interactive_des'.tr(),
                  style: theme.textTheme.ppMori400Grey14,
                ),
              )
            ],
          ),
          const SizedBox(height: 40),
          OutlineButton(
            text: 'close'.tr(),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
        ],
      ),
      isDismissible: true,
    );
  }

  static Future showFFAccountLinked(BuildContext context, String alias,
      {bool inOnboarding = false}) {
    final theme = Theme.of(context);
    return showDialog(
      context,
      'account_linked'.tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                style: theme.primaryTextTheme.ppMori400White14,
                text: "au_receive_auth".tr(),
              ),
              TextSpan(
                style: theme.primaryTextTheme.ppMori700White16,
                text: alias,
              ),
              TextSpan(
                style: theme.primaryTextTheme.ppMori400White14,
                text:
                    "dot".tr(args: [inOnboarding ? 'please_finish'.tr() : '']),
              ),
            ]),
          ),
          const SizedBox(height: 67),
        ],
      ),
      isDismissible: true,
      autoDismissAfter: 5,
    );
  }

  static Future showAirdropNotStarted(BuildContext context) async {
    final theme = Theme.of(context);
    final error = FeralfileError(5006, "");
    metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
        data: {"message": error.dialogMessage});
    return UIHelper.showDialog(
      context,
      error.dialogTitle,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            error.dialogMessage,
            style: theme.primaryTextTheme.ppMori400White14,
          ),
          const SizedBox(
            height: 40,
          ),
          OutlineButton(
            text: "close".tr(),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      isDismissible: true,
    );
  }

  static Future showAirdropExpired(BuildContext context) async {
    final theme = Theme.of(context);
    final error = FeralfileError(3007, "");
    metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
        data: {"message": error.dialogMessage});
    return UIHelper.showDialog(
      context,
      error.dialogTitle,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            error.dialogMessage,
            style: theme.primaryTextTheme.bodyText1,
          ),
          const SizedBox(
            height: 40,
          ),
          AuFilledButton(
            text: "close".tr(),
            onPress: () {
              Navigator.of(context).pop();
            },
            textStyle: theme.primaryTextTheme.button,
          ),
        ],
      ),
      isDismissible: true,
    );
  }

  static Future showNoRemainingAirdropToken(
    BuildContext context, {
    required FFArtwork artwork,
  }) async {
    final error = FeralfileError(3009, "");
    metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
        data: {"message": error.dialogMessage});
    return showErrorDialog(
      context,
      error.getDialogTitle(artwork: artwork),
      error.getDialogMessage(artwork: artwork),
      "close".tr(),
    );
  }

  static Future showOtpExpired(BuildContext context) async {
    final error = FeralfileError(3013, "");
    metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
        data: {"message": error.dialogMessage});
    return showErrorDialog(
      context,
      error.dialogTitle,
      error.dialogMessage,
      "close".tr(),
    );
  }

  static Future showClaimTokenError(
    BuildContext context,
    Object e, {
    required FFArtwork artwork,
  }) async {
    if (e is AirdropExpired) {
      await showAirdropExpired(context);
    } else if (e is DioError) {
      final ffError = e.error as FeralfileError?;
      final message = ffError != null
          ? ffError.getDialogMessage(artwork: artwork)
          : "${e.response?.data ?? e.message}";

      metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
          data: {"message": message});
      await showErrorDialog(
        context,
        ffError?.getDialogTitle(artwork: artwork) ?? "error".tr(),
        message,
        "close".tr(),
      );
    } else if (e is NoRemainingToken) {
      await showNoRemainingAirdropToken(
        context,
        artwork: artwork,
      );
    }
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
            imageUrl: appIcons.firstOrNull ?? "",
            width: size,
            height: size,
            errorWidget: (context, url, error) => SizedBox(
              width: size,
              height: size,
              child: Image.asset("assets/images/walletconnect-alternative.png"),
            ),
          );
        }

      case 'walletConnect2':
        final appMetaData = AppMetadata.fromJson(jsonDecode(connection.data));
        final appIcons = appMetaData.icons;
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
      "generated".tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'multichain_generate'.tr(),
            style: theme.primaryTextTheme.ppMori400White14,
          ),
          const SizedBox(height: 16),
          Text(
            "ethereum_address".tr(),
            style: theme.primaryTextTheme.ppMori700White14,
          ),
          const SizedBox(height: 16),
          Text(
            "tezos_address".tr(),
            style: theme.primaryTextTheme.ppMori700White14,
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: "continue".tr(),
                  onTap: () => onContinue(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  static showImportedPersonaDialog(BuildContext context,
      {required Function() onContinue}) {
    final theme = Theme.of(context);

    showDialog(
        context,
        "imported".tr(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('multichain_generate'.tr(),
                style: theme.primaryTextTheme.headline5),
            const SizedBox(height: 16),
            Text("bitmark_address".tr(),
                style: theme.primaryTextTheme.headline4),
            const SizedBox(height: 16),
            Text("ethereum_address".tr(),
                style: theme.primaryTextTheme.headline4),
            const SizedBox(height: 16),
            Text("tezos_address".tr(), style: theme.primaryTextTheme.headline4),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "continue".tr().toUpperCase(),
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
        isHidden ? "art_hidden".tr() : "art_unhidden".tr(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isHidden
                ? RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        style: theme.textTheme.ppMori400White14,
                        text: "art_no_appear".tr(),
                      ),
                      TextSpan(
                        style: theme.textTheme.ppMori700White14,
                        text: "hidden_art".tr(),
                      ),
                      TextSpan(
                        style: theme.textTheme.ppMori400White14,
                        text: "section_setting".tr(),
                      ),
                    ]),
                  )
                : Text(
                    "art_visible".tr(),
                    style: theme.primaryTextTheme.ppMori400White14,
                  ),
            const SizedBox(height: 40),
            PrimaryButton(
              onTap: onOK,
              text: "ok".tr(),
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
        "identity".tr(),
        Flexible(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('alias'.tr(), style: theme.primaryTextTheme.headline5),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text(
                name,
                style: theme.primaryTextTheme.headline4,
                overflow: TextOverflow.ellipsis,
              )),
              GestureDetector(
                child:
                    Text("share".tr(), style: theme.primaryTextTheme.headline4),
                onTap: () => Share.share(address),
              )
            ]),
            const SizedBox(height: 16),
            Text(
              address,
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.ibmWhiteNormal14
                  : theme.textTheme.ibmWhiteNormal16,
            ),
            const SizedBox(height: 56),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "close".tr(),
                style: theme.primaryTextTheme.button,
              ),
            ),
            const SizedBox(height: 15),
          ],
        )));
  }

  static showConnectionSuccess(
    BuildContext context, {
    required Function() onClose,
  }) {
    final theme = Theme.of(context);

    showDialog(
      context,
      'connected'.tr(),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'connect_TV_success_des'.tr(),
              style: theme.primaryTextTheme.bodyText1,
            ),
            const SizedBox(
              height: 40,
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "close".tr(),
                    onPress: onClose,
                    color: theme.colorScheme.secondary,
                    textStyle: theme.textTheme.button,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  static showLoadingScreen(BuildContext context, {String text = ''}) {
    final theme = Theme.of(context);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => loadingScreen(
          theme,
          text,
        ),
      ),
    );
  }

  static showConnectionFaild(
    BuildContext context, {
    required Function() onClose,
  }) {
    final theme = Theme.of(context);

    showDialog(
      context,
      'expired'.tr(),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'expired_des'.tr(),
              style: theme.primaryTextTheme.bodyText1,
            ),
            const SizedBox(
              height: 40,
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "close".tr(),
                    onPress: onClose,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  static showAccountLinked(
      BuildContext context, Connection connection, String walletName) {
    UIHelper.showInfoDialog(
        context,
        "account_linked".tr(),
        "autonomy_has_received"
            .tr(args: [walletName, connection.accountNumber.mask(4)]));

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
        ErrorEvent(null, "already_linked".tr(), "al_you’ve_already".tr(),
            ErrorItemState.seeAccount), defaultAction: () {
      Navigator.of(context)
          .pushNamed(AppRouter.linkedAccountDetailsPage, arguments: connection);
    });
  }

  static showAbortedByUser(BuildContext context) {
    UIHelper.showInfoDialog(context, "aborted".tr(), "action_aborted".tr(),
        isDismissible: true, autoDismissAfter: 3);
  }

  static Future showFeatureRequiresSubscriptionDialog(BuildContext context,
      PremiumFeature feature, WCPeerMeta peerMeta, int id) {
    final theme = Theme.of(context);

    return showDialog(
      context,
      "h_subscribe".tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("require_subs".tr(), style: theme.primaryTextTheme.bodyText1),
          const SizedBox(height: 40),
          UpgradeBoxView.getMoreAutonomyWidget(theme, feature,
              peerMeta: peerMeta, id: id),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    injector<WalletConnectService>()
                        .rejectRequest(peerMeta, id);
                    injector<ConfigurationService>().deleteTVConnectData();
                    Navigator.pop(context);
                  },
                  child: Text(
                    "cancel".tr(),
                    style: theme.primaryTextTheme.button,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static Future<void> showDrawerAction(BuildContext context,
      {List<OptionItem>? options}) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<dynamic>(
        context: context,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.isMobile
                ? double.infinity
                : Constants.maxWidthModalTablet),
        barrierColor: Colors.black.withOpacity(0.5),
        isScrollControlled: true,
        builder: (context) {
          return Container(
            color: theme.auSuperTeal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      AuIcon.close,
                      size: 18,
                    ),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) =>
                      GestureDetector(
                    onTap: options?[index].onTap,
                    child: Container(
                      color: Colors.transparent,
                      width: MediaQuery.of(context).size.width,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 13,
                        ),
                        child: Row(
                          children: [
                            if (options?[index].icon != null)
                              options![index].icon!,
                            if (options?[index].icon != null)
                              const SizedBox(
                                width: 40,
                              ),
                            Text(
                              options?[index].title ?? '',
                              style: theme.textTheme.ppMori400Black14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  itemCount: options?.length ?? 0,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1.0,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          );
        });
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
    child: Text(
      title,
      style: ResponsiveLayout.isMobile
          ? theme.textTheme.ppMori400Black14
              .copyWith(decoration: TextDecoration.underline)
          : theme.textTheme.ppMori400Black16
              .copyWith(decoration: TextDecoration.underline),
    ),
  );
}

wantMoreSecurityWidget(BuildContext context, WalletApp walletApp) {
  var introText = 'you_can_get_all'.tr();
  if (walletApp == WalletApp.Kukai || walletApp == WalletApp.Temple) {
    introText += "_tezos".tr();
  }
  introText += "functionality".tr(args: [walletApp.rawValue]);
  final theme = Theme.of(context);
  return GestureDetector(
    onTap: () => Navigator.of(context).pushNamed(AppRouter.importAccountPage),
    child: Container(
      padding: const EdgeInsets.all(10),
      color: AppColor.secondaryDimGreyBackground,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "want_more_sec".tr(),
          style: ResponsiveLayout.isMobile
              ? theme.textTheme.atlasDimgreyBold14
              : theme.textTheme.atlasDimgreyBold16,
        ),
        const SizedBox(height: 5),
        Text(
          introText,
          style: ResponsiveLayout.isMobile
              ? theme.textTheme.atlasBlackNormal14
              : theme.textTheme.atlasBlackNormal16,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRouter.unsafeWebWalletPage),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text("learn_ex_unsafe".tr(), style: theme.textTheme.linkStyle),
        ),
      ]),
    ),
  );
}

Widget loadingScreen(ThemeData theme, String text) {
  return Scaffold(
    backgroundColor: AppColor.white,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/loading.gif",
            width: 52,
            height: 52,
          ),
          const SizedBox(height: 20),
          Text(
            text,
            style: theme.textTheme.ppMori400Black14,
          )
        ],
      ),
    ),
  );
}

Widget stepWidget(BuildContext context, String stepNumber, String stepGuide) {
  final theme = Theme.of(context);
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "$stepNumber.",
        style: theme.textTheme.ppMori400Black14,
      ),
      const SizedBox(
        width: 10,
      ),
      Expanded(
        child: Text(stepGuide, style: theme.textTheme.ppMori400Black14),
      )
    ],
  );
}

String getDateTimeRepresentation(DateTime dateTime) {
  return Jiffy(dateTime).fromNow();
}

class OptionItem {
  String? title;
  Function()? onTap;
  Widget? icon;

  OptionItem({
    this.title,
    this.onTap,
    this.icon,
  });
}
