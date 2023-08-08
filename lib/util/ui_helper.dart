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
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
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
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/confetti.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/transparent_router.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:jiffy/jiffy.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher_string.dart';
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

  static Future<dynamic> showDialog(
    BuildContext context,
    String title,
    Widget content, {
    bool isDismissible = false,
    isRoundCorner = true,
    Color? backgroundColor,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
    EdgeInsets? padding,
    EdgeInsets? paddingTitle,
  }) async {
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

    return await showModalBottomSheet<dynamic>(
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
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: paddingTitle ?? const EdgeInsets.all(0),
                      child: Text(title,
                          style: theme.primaryTextTheme.ppMori700White24),
                    ),
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

  static Future<void> showDialogWithConfetti(
    BuildContext context,
    String title,
    Widget content, {
    bool isDismissible = false,
    isRoundCorner = true,
    Color? backgroundColor,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
    EdgeInsets? padding,
    EdgeInsets? paddingTitle,
  }) async {
    log.info("[UIHelper] showInfoDialog: $title");
    currentDialogTitle = title;
    final theme = Theme.of(context);
    final confettiController =
        ConfettiController(duration: const Duration(seconds: 15));
    Future.delayed(const Duration(milliseconds: 300), () {
      confettiController.play();
    });
    if (autoDismissAfter > 0) {
      Future.delayed(
          Duration(seconds: autoDismissAfter), () => hideInfoDialog(context));
    }

    if (feedback != null) {
      Vibrate.feedback(feedback);
    }

    await Navigator.push(
      context,
      TransparentRoute(
        color: AppColor.primaryBlack.withOpacity(0.4),
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.transparent,
                    child: ClipPath(
                      clipper: isRoundCorner
                          ? null
                          : AutonomyTopRightRectangleClipper(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundColor ?? theme.auGreyBackground,
                          borderRadius: isRoundCorner
                              ? const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                )
                              : null,
                        ),
                        padding: padding ??
                            const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 32),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    paddingTitle ?? const EdgeInsets.all(0),
                                child: Text(title,
                                    style: theme
                                        .primaryTextTheme.ppMori700White24),
                              ),
                              const SizedBox(height: 40),
                              content,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AllConfettiWidget(controller: confettiController),
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<void> showScrollableDialog(
    BuildContext context,
    Widget content, {
    bool isDismissible = false,
    isRoundCorner = true,
    Color? backgroundColor,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
  }) async {
    final theme = Theme.of(context);

    if (autoDismissAfter > 0) {
      Future.delayed(
          Duration(seconds: autoDismissAfter), () => hideInfoDialog(context));
    }

    if (feedback != null) {
      Vibrate.feedback(feedback);
    }

    final height = MediaQuery.of(context).size.height > 800 ? 689 : 600;

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
          height: height.toDouble(),
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
              child: content,
            ),
          ),
        );
      },
    );
  }

  static Future<void> showFlexibleDialog(
    BuildContext context,
    Widget content, {
    bool isDismissible = false,
    isRoundCorner = true,
    Color? backgroundColor,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
  }) async {
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
          padding: const EdgeInsets.only(top: 200),
          child: ClipPath(
            clipper: isRoundCorner ? null : AutonomyTopRightRectangleClipper(),
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
              decoration: BoxDecoration(
                color: backgroundColor ?? theme.auGreyBackground,
                borderRadius: isRoundCorner
                    ? const BorderRadius.only(
                        topRight: Radius.circular(20),
                      )
                    : null,
              ),
              child: content,
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
              Text(title, style: theme.primaryTextTheme.headlineMedium),
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
                      style: theme.primaryTextTheme.labelLarge,
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
                style: theme.primaryTextTheme.bodyLarge,
                text: "au_sent_survey".tr(),
              ),
              TextSpan(
                style: theme.primaryTextTheme.headlineMedium,
                text: "feral_file".tr(),
              ),
              TextSpan(
                style: theme.primaryTextTheme.bodyLarge,
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
                colorFilter:
                    ColorFilter.mode(theme.disableColor, BlendMode.srcIn),
              ),
              const SizedBox(
                width: 17,
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.ppMori400Grey14,
                    children: <TextSpan>[
                      TextSpan(
                        text: 'software_artwork_connect_cast'.tr(),
                      ),
                      TextSpan(
                        text: 'tv_app'.tr(),
                        style: theme.textTheme.ppMori400Green14,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchUrlString(TV_APP_STORE_URL,
                                mode: LaunchMode.externalApplication);
                          },
                      ),
                      TextSpan(
                        text: 'on_google_app_store'.tr(),
                      ),
                    ],
                  ),
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

  static Future showAirdropNotStarted(
      BuildContext context, String? artworkId) async {
    final theme = Theme.of(context);
    final error = FeralfileError(5006, "");
    metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
        data: {"message": error.dialogMessage, "id": artworkId});
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

  static Future showAirdropExpired(
      BuildContext context, String? artworkId) async {
    final theme = Theme.of(context);
    final error = FeralfileError(3007, "");
    metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
        data: {"message": error.dialogMessage, "id": artworkId});
    return UIHelper.showDialog(
      context,
      error.dialogTitle,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            error.dialogMessage,
            style: theme.primaryTextTheme.bodyLarge,
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

  static Future showNoRemainingAirdropToken(
    BuildContext context, {
    required FFSeries series,
  }) async {
    final error = FeralfileError(3009, "");
    metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
        data: {"message": error.dialogMessage, "id": series.id});
    return showErrorDialog(
      context,
      error.getDialogTitle(),
      error.getDialogMessage(series: series),
      "close".tr(),
    );
  }

  static Future showNoRemainingActivationToken(
    BuildContext context, {
    required String id,
  }) async {
    final error = FeralfileError(3009, "");
    metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
        data: {"message": error.dialogMessage, "id": id});
    return showErrorDialog(
      context,
      error.getDialogTitle(),
      error.getDialogMessage(),
      "close".tr(),
    );
  }

  static Future showOtpExpired(BuildContext context, String? artworkId) async {
    final error = FeralfileError(3013, "");
    metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
        data: {"message": error.dialogMessage, "id": artworkId});
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
    required FFSeries series,
  }) async {
    if (e is AirdropExpired) {
      await showAirdropExpired(context, series.id);
    } else if (e is DioException) {
      final ffError = e.error as FeralfileError?;
      final message = ffError != null
          ? ffError.getDialogMessage(series: series)
          : "${e.response?.data ?? e.message}";

      metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
          data: {"message": message, "id": series.id});
      await showErrorDialog(
        context,
        ffError?.getDialogTitle() ?? "error".tr(),
        message,
        "close".tr(),
      );
    } else if (e is NoRemainingToken) {
      await showNoRemainingAirdropToken(
        context,
        series: series,
      );
    }
  }

  static Future showActivationError(
      BuildContext context, Object e, String id) async {
    if (e is AirdropExpired) {
      await showAirdropExpired(context, id);
    } else if (e is DioException) {
      final ffError = e.error as FeralfileError?;
      final message = ffError != null
          ? ffError.dialogMessage
          : "${e.response?.data ?? e.message}";

      metricClient.addEvent(MixpanelEvent.acceptOwnershipFail,
          data: {"message": message, "id": id});
      await showErrorDialog(
        context,
        ffError?.dialogMessage ?? "error".tr(),
        message,
        "close".tr(),
      );
    } else if (e is NoRemainingToken) {
      await showNoRemainingActivationToken(context, id: id);
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
      case 'dappConnect2':
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
            Text("imported_success".tr(),
                style: theme.textTheme.ppMori400White14),
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
                        text: "hidden_artwork".tr(),
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name.isNotEmpty) ...[
                    Text(
                      name,
                      style: theme.textTheme.ppMori700White14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    address,
                    style: theme.textTheme.ppMori400White14,
                  ),
                ],
              )),
              const SizedBox(width: 24),
              IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Share.share(address),
                  icon: SvgPicture.asset(
                    'assets/images/Share.svg',
                    colorFilter:
                        const ColorFilter.mode(AppColor.white, BlendMode.srcIn),
                  )),
            ]),
            const SizedBox(height: 40),
            OutlineButton(
              onTap: () {
                Navigator.of(context).pop();
              },
              text: "close".tr(),
            ),
            const SizedBox(height: 15),
          ],
        )));
  }

  static showConnectionSuccess(
    BuildContext context, {
    required Function() onClose,
  }) {
    showDialog(
      context,
      'connected'.tr(),
      ConnectedTV(
        onTap: onClose,
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

  static showConnectionFailed(
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
              style: theme.primaryTextTheme.bodyLarge,
            ),
            const SizedBox(
              height: 40,
            ),
            AuSecondaryButton(
              onPressed: onClose,
              text: 'close'.tr(),
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

  static showCenterSheet(BuildContext context,
      {required Widget content,
      String? actionButton,
      Function()? actionButtonOnTap,
      String? exitButton,
      Function()? exitButtonOnTap}) {
    UIHelper.hideInfoDialog(context);
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 128),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.auSuperTeal,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 15, 5, 15),
                  child: Column(
                    children: [
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 5,
                          radius: const Radius.circular(10),
                          scrollbarOrientation: ScrollbarOrientation.right,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  content,
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (actionButtonOnTap != null)
                        Column(
                          children: [
                            AuSecondaryButton(
                              text: actionButton ?? "",
                              onPressed: actionButtonOnTap,
                              borderColor: AppColor.primaryBlack,
                              textColor: AppColor.primaryBlack,
                              backgroundColor: AppColor.auSuperTeal,
                            ),
                            const SizedBox(
                              height: 15,
                            )
                          ],
                        ),
                      AuSecondaryButton(
                        text: exitButton ?? "close".tr(),
                        onPressed: exitButtonOnTap ??
                            () {
                              Navigator.pop(context);
                            },
                        borderColor: AppColor.primaryBlack,
                        textColor: AppColor.primaryBlack,
                        backgroundColor: AppColor.auSuperTeal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  static showLoadingIndicator(
    BuildContext context,
  ) {
    UIHelper.hideInfoDialog(context);
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return Center(
            child: loadingIndicator(),
          );
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
          Text("require_subs".tr(), style: theme.primaryTextTheme.bodyLarge),
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
                    style: theme.primaryTextTheme.labelLarge,
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
                  itemBuilder: (BuildContext context, int index) {
                    final child = Container(
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
                              SizedBox(width: 30, child: options![index].icon!),
                            if (options?[index].icon != null)
                              const SizedBox(
                                width: 34,
                              ),
                            Text(
                              options?[index].title ?? '',
                              style: theme.textTheme.ppMori400Black14,
                            ),
                          ],
                        ),
                      ),
                    );
                    if (options?[index].builder != null) {
                      return options?[index].builder!.call(context, child);
                    }
                    return GestureDetector(
                      onTap: options?[index].onTap,
                      child: child,
                    );
                  },
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

  static Future showAlreadyDelivered(BuildContext context) async {
    final title = "already_delivered".tr();
    final description = "it_seems_that".tr();
    return showErrorDialog(context, title, description, "close".tr());
  }

  static Future showDeclinedGeolocalization(BuildContext context) async {
    final title = "unable_to_stamp_postcard".tr();
    final description = "sharing_your_geolocation".tr();
    return showErrorDialog(context, title, description, "close".tr());
  }

  static Future showWeakGPSSignal(BuildContext context) async {
    final title = "unable_to_stamp_postcard".tr();
    final description = "we_are_unable_to_stamp".tr();
    return showErrorDialog(context, title, description, "close".tr());
  }

  static Future showMockedLocation(BuildContext context) async {
    final title = "gps_spoofing_detected".tr();
    final description = "gps_is_mocked".tr();
    return showInfoDialog(context, title, description,
        closeButton: "close".tr());
  }

  static showReceivePostcardFailed(
      BuildContext context, DioException error) async {
    return showErrorDialog(context, "accept_postcard_failed".tr(),
        error.response?.data['message'], "close".tr());
  }

  static showSharePostcardFailed(
      BuildContext context, DioException error) async {
    return showErrorDialog(context, "Share Failed",
        "${error.response?.data['message']}", "close".tr());
  }

  static Future<void> showInvalidURI(BuildContext context) async {
    await UIHelper.showDialog(
      context,
      "invalid_uri".tr(),
      Column(
        children: [
          Text("invalid_uri_desc".tr(),
              style: Theme.of(context).textTheme.ppMori400White14),
          const SizedBox(height: 40),
          OutlineButton(
            onTap: () => Navigator.pop(context),
            text: "close".tr(),
          ),
        ],
      ),
    );
  }

  static Future<void> showPostcardUpdates(BuildContext context) async {
    await UIHelper.showDialog(
        context,
        "postcard_updates".tr(),
        Column(
          children: [
            Text(
              "postcard_updates_content".tr(),
              style: Theme.of(context).textTheme.ppMori400White14,
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              text: "enable_noti".tr(),
              onTap: () {
                Navigator.of(context)
                    .popAndPushNamed(AppRouter.preferencesPage);
              },
            ),
          ],
        ),
        isDismissible: true);
  }

  static showAirdropClaimFailed(BuildContext context) async {
    return showErrorDialog(
        context, "airdrop_claim_failed".tr(), "", "close".tr());
  }

  static showAirdropAlreadyClaim(BuildContext context) async {
    return showErrorDialog(context, "already_claimed".tr(),
        "already_claimed_desc".tr(), "close".tr());
  }

  static showAirdropJustOnce(BuildContext context) async {
    return showErrorDialog(
        context, "just_once".tr(), "just_once_desc".tr(), "close".tr());
  }

  static showAirdropCannotShare(BuildContext context) async {
    return showErrorDialog(context, "already_claimed".tr(),
        "cannot_share_aridrop_desc".tr(), "close".tr());
  }

  static Future<void> showPostcardShareLinkExpired(BuildContext context) async {
    await UIHelper.showDialog(
      context,
      "claim_has_expired".tr(),
      Column(
        children: [
          Text("claim_has_expired_desc".tr(),
              style: Theme.of(context).textTheme.ppMori400White14),
          const SizedBox(height: 40),
          OutlineButton(
            onTap: () => Navigator.pop(context),
            text: "close".tr(),
          ),
        ],
      ),
    );
  }
}

class ConnectedTV extends StatefulWidget {
  final Function() onTap;

  const ConnectedTV({
    super.key,
    required this.onTap,
  });

  @override
  State<ConnectedTV> createState() => _ConnectedTVState();
}

class _ConnectedTVState extends State<ConnectedTV> {
  late Timer _timer;
  int _countdown = 5;

  @override
  void initState() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown != 0) {
        setState(() {
          _countdown--;
        });
      } else {
        widget.onTap.call();
        _timer.cancel();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'connect_TV_success_des'.tr(),
            style: theme.primaryTextTheme.bodyLarge,
          ),
          const SizedBox(
            height: 40,
          ),
          PrimaryButton(
            onTap: widget.onTap,
            text: _countdown != 0
                ? 'close_seconds'.tr(args: [_countdown.toString()])
                : 'close'.tr(),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
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
  return Jiffy.parseFromDateTime(dateTime).fromNow();
}

class OptionItem {
  String? title;
  Function()? onTap;
  Widget? icon;
  Widget Function(BuildContext context, Widget child)? builder;

  OptionItem({
    this.title,
    this.onTap,
    this.icon,
    this.builder,
  });
}
