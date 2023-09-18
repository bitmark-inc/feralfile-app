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
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/confetti.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/postcard_common_widget.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/transparent_router.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:jiffy/jiffy.dart';
import 'package:share/share.dart';

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

  static Future<dynamic> showPostCardDialog(
    BuildContext context,
    String title,
    Widget content, {
    bool isDismissible = false,
    isRoundCorner = true,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
    EdgeInsets? padding,
  }) async {
    log.info("[UIHelper] showPostcardInfoDialog: $title");
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
                color: Colors.white,
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
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(title,
                          style: theme.primaryTextTheme.moMASans700Black18),
                    ),
                    addDivider(height: 40, color: AppColor.chatPrimaryColor),
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

  static Future<void> showRawDialog(
    BuildContext context,
    Widget content, {
    bool isDismissible = true,
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
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      return options?[index]
                          .builder!
                          .call(context, options[index]);
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

  static Future<void> showAutoDismissDialog(BuildContext context,
      {required Function() showDialog,
      required Duration autoDismissAfter}) async {
    Future.delayed(autoDismissAfter, () => hideInfoDialog(context));
    await showDialog();
  }

  static Future<void> showPostcardDrawerAction(BuildContext context,
      {required List<OptionItem> options}) async {
    const backgroundColor = AppColor.white;
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
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: backgroundColor,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final item = options[index];
                      const defaultSeparator = Divider(
                        height: 1,
                        thickness: 1.0,
                        color: Color.fromRGBO(227, 227, 227, 1),
                      );
                      return Column(
                        children: [
                          Builder(builder: (context) {
                            if (item.builder != null) {
                              final child = Container(
                                color: Colors.transparent,
                                width: MediaQuery.of(context).size.width,
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: item.builder!.call(context, item)),
                              );
                              return GestureDetector(
                                onTap: options[index].onTap,
                                child: child,
                              );
                            }
                            return PostcardDrawerItem(item: item);
                          }),
                          item.separator ?? defaultSeparator,
                        ],
                      );
                    },
                    itemCount: options.length,
                  ),
                ],
              ),
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

  static showAlreadyClaimedPostcard(
      BuildContext context, DioException error) async {
    return showErrorDialog(context, "you_already_claimed_this_postcard".tr(),
        "send_it_to_someone_else".tr(), "close".tr());
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
    bool isProcessing = false;
    await UIHelper.showPostCardDialog(context, "postcard_notifications".tr(),
        StatefulBuilder(builder: (context, buttonState) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              "postcard_updates_content".tr(),
              style: Theme.of(context).textTheme.moMASans700AuGrey18,
            ),
          ),
          const SizedBox(height: 40),
          PostcardButton(
            text: "enable".tr(),
            color: AppColor.momaGreen,
            isProcessing: isProcessing,
            onTap: () async {
              buttonState(() {
                isProcessing = true;
              });
              try {
                await registerPushNotifications(askPermission: true);
                injector<ConfigurationService>().setPendingSettings(false);
              } catch (error) {
                log.warning("Error when setting notification: $error");
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      );
    }), isDismissible: true);
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

  static Future<void> showPostcardShareLinkInvalid(BuildContext context) async {
    await UIHelper.showDialog(
      context,
      "link_expired_or_claimed".tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("link_expired_or_claimed_desc".tr(),
              style: Theme.of(context).textTheme.ppMori400White14),
          const SizedBox(height: 40),
          OutlineButton(
            onTap: () => Navigator.pop(context),
            text: "close".tr(),
          ),
        ],
      ),
      isDismissible: true,
    );
  }

  static showCustomDialog(
      {required BuildContext context,
      required Widget child,
      bool isDismissible = false,
      Color? backgroundColor,
      EdgeInsets? padding,
      BorderRadius? borderRadius}) async {
    final theme = Theme.of(context);
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
          child: Container(
            decoration: BoxDecoration(
                color: backgroundColor ?? theme.auGreyBackground,
                borderRadius: borderRadius ??
                    const BorderRadius.only(
                      topRight: Radius.circular(20),
                    )),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
            child: SingleChildScrollView(
              child: child,
            ),
          ),
        );
      },
    );
  }

  static showLocationExplain(BuildContext context) async {
    final theme = Theme.of(context);
    return showCustomDialog(
      context: context,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset("assets/images/postcard_location_explain_3.png"),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset("assets/images/location.svg"),
                        Text(
                          "web".tr(),
                          style: theme.textTheme.moMASans400Black16
                              .copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "plus_distance".tr(namedArgs: {
                      "distance": DistanceFormatter().format(distance: 0),
                    }),
                    style: theme.textTheme.moMASans400Black16.copyWith(
                        fontSize: 18,
                        color: const Color.fromRGBO(131, 79, 196, 1)),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text("if_your_location_is_not_enabled".tr(),
              style: theme.textTheme.moMASans700Black16.copyWith(fontSize: 18)),
          const SizedBox(height: 40),
        ],
      ),
      isDismissible: true,
      backgroundColor: AppColor.chatPrimaryColor,
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10), topRight: Radius.circular(10)),
    );
  }

  static Future<void> showPostcardRunOut(BuildContext context) async {
    await await UIHelper.showDialog(
      context,
      "postcards_ran_out".tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("postcards_ran_out_desc".tr(),
              style: Theme.of(context)
                  .textTheme
                  .ppMori400White14
                  .copyWith(height: 2)),
          const SizedBox(height: 40),
          PrimaryButton(
            onTap: () => Navigator.pop(context),
            text: "close".tr(),
          ),
        ],
      ),
      isDismissible: true,
    );
  }

  static Future<void> showPostcardStampSaved(BuildContext context) async {
    final options = [
      OptionItem(
        title: "stamp_saved".tr(),
        icon: SvgPicture.asset("assets/images/download.svg"),
        onTap: () {},
      ),
    ];
    await showAutoDismissDialog(context, showDialog: () async {
      return showPostcardDrawerAction(context, options: options);
    }, autoDismissAfter: const Duration(seconds: 2));
  }

  static Future<void> showPostcardStampPhotoAccessFailed(
      BuildContext context) async {
    final options = [
      OptionItem(
        title: "stamp_could_not_be_saved".tr(),
        titleStyle: Theme.of(context)
            .textTheme
            .moMASans700Black16
            .copyWith(fontSize: 18, color: MoMAColors.moMA3),
        icon: SvgPicture.asset("assets/images/postcard_hide.svg"),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    ];
    await showAutoDismissDialog(context, showDialog: () async {
      return showPostcardDrawerAction(context, options: options);
    }, autoDismissAfter: const Duration(seconds: 2));
  }

  static Future<void> showPostcardStampSavedFailed(BuildContext context) async {
    final theme = Theme.of(context);
    final options = [
      OptionItem(
        title: "stamp_save_failed".tr(),
        titleStyle: theme.textTheme.moMASans700Black16
            .copyWith(fontSize: 18, color: MoMAColors.moMA3),
        icon: SvgPicture.asset("assets/images/exit.svg"),
        onTap: () {},
      ),
    ];
    await showAutoDismissDialog(context, showDialog: () async {
      return showPostcardDrawerAction(context, options: options);
    }, autoDismissAfter: const Duration(seconds: 2));
  }

  static Future<void> showPostcardCancelInvitation(BuildContext context,
      {Function()? onConfirm, Function()? onBack}) async {
    final theme = Theme.of(context);
    final options = [
      OptionItem(
          builder: (context, _) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "cancel_invitation".tr(),
                    style: theme.textTheme.moMASans700Black16
                        .copyWith(fontSize: 18),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text("cancel_invitation_desc".tr(),
                      style: theme.textTheme.moMASans400Black16
                          .copyWith(fontSize: 12)),
                ],
              ),
            );
          },
          separator: const Divider(
            color: AppColor.auGrey,
            height: 1,
            thickness: 1.0,
          )),
      OptionItem(
        title: "ok".tr(),
        titleStyle: theme.textTheme.moMASans700Black16
            .copyWith(fontSize: 18, color: MoMAColors.moMA3),
        titleStyleOnPrecessing: theme.textTheme.moMASans700Black16
            .copyWith(fontSize: 18, color: MoMAColors.moMA3Disable),
        onTap: onConfirm,
      ),
      OptionItem(
        title: "go_back".tr(),
        onTap: onBack,
      ),
    ];
    await showPostcardDrawerAction(context, options: options);
  }
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

String getDateTimeRepresentation(DateTime dateTime) {
  return Jiffy.parseFromDateTime(dateTime).fromNow();
}

class OptionItem {
  String? title;
  TextStyle? titleStyle;
  TextStyle? titleStyleOnPrecessing;
  Function()? onTap;
  Widget? icon;
  Widget? iconOnProcessing;
  Widget Function(BuildContext context, OptionItem item)? builder;
  Widget? separator;

  OptionItem({
    this.title,
    this.titleStyle,
    this.titleStyleOnPrecessing,
    this.onTap,
    this.icon,
    this.iconOnProcessing,
    this.builder,
    this.separator,
  });
}
