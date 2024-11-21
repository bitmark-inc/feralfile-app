// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: unawaited_futures, discarded_futures
// ignore_for_file: constant_identifier_names
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
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/user_interactivity_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/confetti.dart';
import 'package:autonomy_flutter/view/passkey/passkey_login_view.dart';
import 'package:autonomy_flutter/view/passkey/passkey_register_view.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/postcard_common_widget.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/slide_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension/moma_sans.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:jiffy/jiffy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';

enum ActionState { notRequested, loading, error, done }

const SHOW_DIALOG_DURATION = Duration(seconds: 2);
const SHORT_SHOW_DIALOG_DURATION = Duration(seconds: 1);

void nameContinue(BuildContext context) {
  Navigator.of(context).popUntil((route) =>
      route.settings.name == AppRouter.tbConnectPage ||
      route.settings.name == AppRouter.wc2ConnectPage ||
      route.settings.name == AppRouter.homePage ||
      route.settings.name == AppRouter.homePageNoTransition ||
      route.settings.name == AppRouter.walletPage);
}

class UIHelper {
  static String currentDialogTitle = '';
  static final metricClient = injector.get<MetricClientService>();
  static const String ignoreBackLayerPopUpRouteName = 'popUp.ignoreBackLayer';

  static Future<dynamic> showDialog(
    BuildContext context,
    String title,
    Widget content, {
    bool isDismissible = false,
    bool isRoundCorner = true,
    Color? backgroundColor,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
    EdgeInsets? padding,
    EdgeInsets? paddingTitle,
    bool withCloseIcon = false,
    double spacing = 40,
  }) async {
    log.info('[UIHelper] showDialog: $title');
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
      routeSettings: const RouteSettings(name: ignoreBackLayerPopUpRouteName),
      builder: (context) => Container(
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(title,
                              style: theme.primaryTextTheme.ppMori700White24),
                        ),
                        if (withCloseIcon)
                          IconButton(
                            onPressed: () => hideInfoDialog(context),
                            icon: SvgPicture.asset(
                              'assets/images/circle_close.svg',
                              width: 22,
                              height: 22,
                            ),
                          )
                      ],
                    ),
                  ),
                  SizedBox(height: spacing),
                  content,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<dynamic> showPostCardDialog(
    BuildContext context,
    String title,
    Widget content, {
    bool isDismissible = false,
    bool isRoundCorner = true,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
    EdgeInsets? padding,
  }) async {
    log.info('[UIHelper] showPostcardInfoDialog: $title');
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
      builder: (context) => Container(
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
      ),
    );
  }

  static Future<void> showPostcardDialogWithConfetti(
    BuildContext context,
    List<Widget> contents, {
    bool isDismissible = true,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
  }) async {
    log.info('[UIHelper] showPostcardDialogWithConfetti');
    currentDialogTitle = 'showPostcardDialogWithConfetti';

    const backgroundColor = AppColor.white;
    const defaultSeparator = Divider(
      height: 1,
      thickness: 1,
      color: Color.fromRGBO(227, 227, 227, 1),
    );
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
      SlidableRoute(
        color: AppColor.primaryBlack.withOpacity(0.4),
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        hideInfoDialog(context);
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        color: backgroundColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, bottom: 50),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (BuildContext context, int index) {
                                final item = contents[index];

                                return Column(
                                  children: [
                                    item,
                                    defaultSeparator,
                                  ],
                                );
                              },
                              itemCount: contents.length,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AllConfettiWidget(controller: confettiController),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showPostcardFinish15Stamps(
      BuildContext context, String distance,
      {dynamic Function()? onShareTap}) async {
    final theme = Theme.of(context);
    final contents = [
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'congratulations'.tr(),
              style: theme.primaryTextTheme.moMASans700Black18,
            ),
            const SizedBox(height: 20),
            Text(
              'your_group_stamped_15'.tr(args: [distance]),
              style: theme.primaryTextTheme.moMASans400Black12,
            ),
          ],
        ),
      ),
      PostcardDrawerItem(
        item: OptionItem(
          title: 'share_on_'.tr(),
          icon: SvgPicture.asset(
            'assets/images/globe.svg',
            width: 24,
            height: 24,
          ),
          iconOnProcessing: SvgPicture.asset(
            'assets/images/globe.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColor.disabledColor,
              BlendMode.srcIn,
            ),
          ),
          onTap: onShareTap,
        ),
      ),
    ];
    await showPostcardDialogWithConfetti(context, contents);
  }

  static Future<void> showScrollableDialog(
    BuildContext context,
    Widget content, {
    bool isDismissible = false,
    bool isRoundCorner = true,
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
      builder: (context) => Container(
        color: Colors.transparent,
        height: height.toDouble(),
        child: ClipPath(
          clipper: isRoundCorner ? null : AutonomyTopRightRectangleClipper(),
          child: DecoratedBox(
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
      ),
    );
  }

  static Future<void> showRawDialog(
    BuildContext context,
    Widget content, {
    bool isDismissible = true,
    bool isRoundCorner = true,
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
      builder: (context) => Container(
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
      ),
    );
  }

  static Future<T?> showRetryDialog<T>(BuildContext context,
      {required String description,
      FutureOr<T> Function()? onRetry,
      ValueNotifier<bool>? dynamicRetryNotifier}) async {
    final theme = Theme.of(context);
    final hasRetry = onRetry != null;
    return await showDialog(
      context,
      'network_issue'.tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: theme.primaryTextTheme.ppMori400White14,
            ),
          ],
          const SizedBox(height: 40),
          if (hasRetry) ...[
            ValueListenableBuilder(
              valueListenable: dynamicRetryNotifier ?? ValueNotifier(true),
              builder: (context, value, child) => value
                  ? Column(
                      children: [
                        PrimaryButton(
                          onTap: () {
                            hideDialogWithResult<FutureOr<T>>(
                                context, onRetry());
                          },
                          text: 'retry_now'.tr(),
                          color: AppColor.feralFileLightBlue,
                        ),
                        const SizedBox(height: 15),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
          OutlineButton(
            onTap: () => hideInfoDialog(context),
            text: 'dismiss'.tr(),
          ),
        ],
      ),
    );
  }

  static Future<void> showFlexibleDialog(
    BuildContext context,
    Widget content, {
    bool isDismissible = false,
    bool isRoundCorner = true,
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
      routeSettings: const RouteSettings(name: ignoreBackLayerPopUpRouteName),
      builder: (context) => ClipPath(
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
    log.info('[UIHelper] showMessageAction: $title, $description');
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
    log.info('[UIHelper] showMessageActionNew: $title, $description');
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
                color: AppColor.feralFileLightBlue,
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

    Widget optionRow({required String title, Function()? onTap}) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.primaryTextTheme.headlineMedium),
                Icon(Icons.navigate_next, color: theme.colorScheme.secondary),
              ],
            ),
          ),
        );

    await UIHelper.showDialog(
      context,
      'Options',
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
                      'cancel'.tr(),
                      style: theme.primaryTextTheme.labelLarge,
                    ),
                  ),
        itemCount: (options?.length ?? 0) + 1,
        separatorBuilder: (context, index) =>
            index == (options?.length ?? 0) - 1
                ? const SizedBox.shrink()
                : Divider(
                    height: 1,
                    thickness: 1,
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
      String closeButton = '',
      VoidCallback? onClose,
      FeedbackType? feedback = FeedbackType.selection}) async {
    log.info('[UIHelper] showInfoDialog: $title, $description');
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

  static void hideInfoDialog(BuildContext context) {
    currentDialogTitle = '';
    try {
      Navigator.popUntil(
          context,
          (route) =>
              route.settings.name != null &&
              !route.settings.name!.toLowerCase().contains('popup'));
    } catch (_) {}
  }

  static void hideDialogWithResult<T>(BuildContext context, T result) {
    currentDialogTitle = '';
    Navigator.pop(context, result);
  }

  static Future showAppReportBottomSheet(
      BuildContext context, PairingMetadata? metadata) {
    String buildReportMessage() => 'suspicious_app_report'.tr(namedArgs: {
          'name': metadata?.name ?? '',
          'url': metadata?.url ?? '',
          'iconUrl': metadata?.icons.first ?? '',
          'description': metadata?.description ?? ''
        });

    return showDrawerAction(
      context,
      options: [
        OptionItem(
          title: 'report'.tr(),
          icon: SvgPicture.asset(
            'assets/images/warning.svg',
            colorFilter:
                const ColorFilter.mode(AppColor.primaryBlack, BlendMode.srcIn),
          ),
          onTap: () async {
            Navigator.of(context).pop();
            unawaited(injector<NavigationService>().navigateTo(
              AppRouter.supportThreadPage,
              arguments: NewIssuePayload(
                reportIssueType: ReportIssueType.Bug,
                defaultMessage: buildReportMessage(),
              ),
            ));
          },
        ),
        OptionItem(),
      ],
    );
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
                  Image.asset('assets/images/walletconnect-alternative.png'));
        } else {
          return CachedNetworkImage(
            imageUrl: appIcons.firstOrNull ?? '',
            width: size,
            height: size,
            errorWidget: (context, url, error) => SizedBox(
              width: size,
              height: size,
              child: Image.asset('assets/images/walletconnect-alternative.png'),
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
                  Image.asset('assets/images/walletconnect-alternative.png'));
        } else {
          return CachedNetworkImage(
            imageUrl: appIcons.first,
            width: size,
            height: size,
            errorWidget: (context, url, error) => SizedBox(
              width: size,
              height: size,
              child: Image.asset('assets/images/walletconnect-alternative.png'),
            ),
          );
        }

      case 'beaconP2PPeer':
        final appIcon = connection.beaconConnectConnection?.peer.icon;
        if (appIcon == null || appIcon.isEmpty) {
          return SvgPicture.asset(
            'assets/images/tezos_social_icon.svg',
            width: size,
            height: size,
          );
        } else {
          return CachedNetworkImage(
            imageUrl: appIcon,
            width: size,
            height: size,
            errorWidget: (context, url, error) => SvgPicture.asset(
              'assets/images/tezos_social_icon.svg',
              width: size,
              height: size,
            ),
          );
        }

      default:
        return const SizedBox();
    }
  }

  static Future<void> showHideArtworkResultDialog(
      BuildContext context, bool isHidden,
      {required Function() onOK}) async {
    final theme = Theme.of(context);

    await showDialog(
        context,
        isHidden ? 'art_hidden'.tr() : 'art_unhidden'.tr(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHidden)
              RichText(
                textScaler: MediaQuery.textScalerOf(context),
                text: TextSpan(children: [
                  TextSpan(
                    style: theme.textTheme.ppMori400White14,
                    text: 'art_no_appear'.tr(),
                  ),
                  TextSpan(
                    style: theme.textTheme.ppMori700White14,
                    text: 'hidden_artwork'.tr(),
                  ),
                  TextSpan(
                    style: theme.textTheme.ppMori400White14,
                    text: 'section_setting'.tr(),
                  ),
                ]),
              )
            else
              Text(
                'art_visible'.tr(),
                style: theme.primaryTextTheme.ppMori400White14,
              ),
            const SizedBox(height: 40),
            PrimaryButton(
              onTap: onOK,
              text: 'ok'.tr(),
            ),
            const SizedBox(height: 15),
          ],
        ));
  }

  static Future<void> showIdentityDetailDialog(BuildContext context,
      {required String name, required String address}) async {
    final theme = Theme.of(context);

    await showDialog(
        context,
        'identity'.tr(),
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
              text: 'close'.tr(),
            ),
            const SizedBox(height: 15),
          ],
        )));
  }

  static Future<void> showLoadingScreen(BuildContext context,
      {String text = ''}) async {
    final theme = Theme.of(context);
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => loadingScreen(
          theme,
          text,
        ),
      ),
    );
  }

  static Future<dynamic> showPasskeyRegisterDialog(
          BuildContext context) async =>
      await showRawCenterSheet(
        context,
        content: const PasskeyRegisterView(),
      );

  static Future<dynamic> showPasskeyLoginDialog(
          BuildContext context, Future<dynamic> Function() onRetry) async =>
      await showRawCenterSheet(
        context,
        content: PasskeyLoginRetryView(onRetry: onRetry),
      );

  static Future<dynamic> showRawCenterSheet(
    BuildContext context, {
    required Widget content,
    double horizontalPadding = 20,
    Color boxColor = AppColor.white,
    Color backgroundColor = Colors.transparent,
  }) async {
    log.info('[UIHelper] showRawCenterSheet');
    UIHelper.hideInfoDialog(context);
    return await showCupertinoModalPopup(
        context: context,
        builder: (context) => Scaffold(
              backgroundColor: backgroundColor,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        content,
                      ],
                    ),
                  ),
                ),
              ),
            ));
  }

  static Future<void> showCenterSheet(BuildContext context,
      {required Widget content,
      String? actionButton,
      Function()? actionButtonOnTap,
      String? exitButton,
      Function()? exitButtonOnTap,
      double horizontalPadding = 20,
      double verticalPadding = 128,
      bool withExitButton = true,
      Color backgroundColor = AppColor.feralFileHighlight}) async {
    UIHelper.hideInfoDialog(context);
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(5),
              ),
              constraints: const BoxConstraints(
                maxHeight: 600,
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  const SizedBox(height: 20),
                  if (actionButtonOnTap != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                      child: PrimaryButton(
                        text: actionButton ?? '',
                        onTap: actionButtonOnTap,
                        textColor: AppColor.primaryBlack,
                        color: AppColor.feralFileLightBlue,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    )
                  ],
                  if (withExitButton) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PrimaryButton(
                          text: exitButton ?? 'close'.tr(),
                          onTap: exitButtonOnTap ??
                              () {
                                Navigator.pop(context);
                              },
                          textColor: AppColor.primaryBlack,
                          color: AppColor.feralFileLightBlue),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<dynamic> showLiveWithArtIntro(BuildContext context) async {
    final theme = Theme.of(context);
    final infoStyle = theme.textTheme.ppMori400White14;
    return await showCenterSheet(
      context,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'live_with_art'.tr(),
              style: theme.textTheme.ppMori700White18,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Swiper(
              itemCount: 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('live_with_art_first'.tr(), style: infoStyle),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('live_with_art_second'.tr(), style: infoStyle),
                  );
                }
              },
              loop: false,
              pagination: const SwiperPagination(
                alignment: Alignment.bottomCenter,
                builder: DotSwiperPaginationBuilder(
                  color: AppColor.secondaryDimGrey,
                  activeColor: AppColor.white,
                  size: 6,
                  activeSize: 6,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColor.auGreyBackground,
      horizontalPadding: 30,
      exitButton: 'view_today_daily'.tr(),
      exitButtonOnTap: () {
        Navigator.pop(context);
        injector<ConfigurationService>().setDidShowLiveWithArt(true);
      },
    );
  }

  static Future<dynamic> showCenterEmptySheet(BuildContext context,
      {required Widget content}) async {
    UIHelper.hideInfoDialog(context);
    return await showCupertinoModalPopup(
        context: context,
        builder: (context) => Scaffold(
              backgroundColor: Colors.transparent,
              appBar: getDarkEmptyAppBar(),
              body: Stack(
                children: [
                  GestureDetector(
                    child: Container(
                      color: AppColor.primaryBlack.withOpacity(0.8),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 128),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        content,
                      ],
                    ),
                  ),
                ],
              ),
            ));
  }

  static Future<dynamic> showCenterDialog(BuildContext context,
      {required Widget content}) async {
    UIHelper.hideInfoDialog(context);
    final theme = Theme.of(context);
    return await showCupertinoModalPopup(
        context: context,
        builder: (context) => Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  GestureDetector(
                    child: Container(
                      color: AppColor.primaryBlack.withOpacity(0.5),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.auGreyBackground,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        constraints: const BoxConstraints(
                          maxHeight: 600,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 15),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              content,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ));
  }

  static Future<void> showCenterMenu(BuildContext context,
      {required List<OptionItem> options}) async {
    final theme = Theme.of(context);
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColor.auGreyBackground,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final option = options[index];
                    final child = Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 13,
                      ),
                      child: Row(
                        children: [
                          if (option.icon != null)
                            SizedBox(
                                width: 30,
                                child: IconTheme(
                                    data: const IconThemeData(
                                      color: AppColor.white,
                                    ),
                                    child: option.icon!)),
                          if (option.icon != null)
                            const SizedBox(
                              width: 39,
                            ),
                          Text(
                            option.title ?? '',
                            style: option.titleStyle ??
                                theme.textTheme.ppMori400White14
                                    .copyWith(decoration: TextDecoration.none),
                          ),
                        ],
                      ),
                    );
                    if (option.builder != null) {
                      return option.builder!.call(context, option);
                    }
                    return GestureDetector(
                      onTap: () {
                        option.onTap?.call();
                      },
                      child: Stack(
                        children: [
                          child,
                          Positioned.fill(
                              child: Container(
                            color: Colors.transparent,
                          )),
                        ],
                      ),
                    );
                  },
                  itemCount: options.length,
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13),
                    child: Divider(
                      height: 1,
                      color: AppColor.primaryBlack,
                      thickness: 1,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showDrawerAction(BuildContext context,
      {required List<OptionItem> options}) async {
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
        routeSettings: const RouteSettings(name: ignoreBackLayerPopUpRouteName),
        builder: (context) => Container(
              color: AppColor.auGreyBackground,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(
                        maxWidth: 44,
                        maxHeight: 44,
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: const Icon(
                        AuIcon.close,
                        size: 18,
                        color: AppColor.white,
                      ),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final option = options[index];
                      if (option.builder != null) {
                        return option.builder!.call(context, option);
                      }
                      return DrawerItem(
                        item: option,
                        color: AppColor.white,
                      );
                    },
                    itemCount: options.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColor.primaryBlack,
                    ),
                  ),
                ],
              ),
            ));
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
        builder: (context) => DecoratedBox(
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
                          thickness: 1,
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
            ));
  }

  static Future showAlreadyDelivered(BuildContext context) async {
    final title = 'already_delivered'.tr();
    final description = 'it_seems_that'.tr();
    return showErrorDialog(context, title, description, 'close'.tr());
  }

  static Future showDeclinedGeolocalization(BuildContext context) async {
    final title = 'unable_to_stamp_postcard'.tr();
    final description = 'sharing_your_geolocation'.tr();
    return showErrorDialog(context, title, description, 'close'.tr());
  }

  static Future showWeakGPSSignal(BuildContext context) async {
    final message = 'gps_too_weak'.tr();
    return await _showPostcardError(context, message: message);
  }

  static Future showMockedLocation(BuildContext context) async {
    final title = 'gps_spoofing_detected'.tr();
    final description = 'gps_is_mocked'.tr();
    return showInfoDialog(context, title, description,
        closeButton: 'close'.tr());
  }

  static Future<void> showReceivePostcardFailed(
          BuildContext context, DioException error) async =>
      await showErrorDialog(context, 'accept_postcard_failed'.tr(),
          'postcard_has_been_claimed'.tr(), 'close'.tr());

  static Future<void> showAlreadyClaimedPostcard(
          BuildContext context, DioException error) async =>
      await showErrorDialog(context, 'you_already_claimed_this_postcard'.tr(),
          'send_it_to_someone_else'.tr(), 'close'.tr());

  static Future<void> showSharePostcardFailed(
          BuildContext context, DioException error) async =>
      await _showPostcardError(
        context,
        message: 'cannot_send_postcard'.tr(),
      );

  static Future<void> showInvalidURI(BuildContext context) async {
    await UIHelper.showDialog(
      context,
      'invalid_uri'.tr(),
      Column(
        children: [
          Text('invalid_uri_desc'.tr(),
              style: Theme.of(context).textTheme.ppMori400White14),
          const SizedBox(height: 40),
          OutlineButton(
            onTap: () => Navigator.pop(context),
            text: 'close'.tr(),
          ),
        ],
      ),
    );
  }

  static Future<void> showPostcardUpdates(BuildContext context) async {
    final result = await showPostCardDialog(
        context,
        'postcard_notifications'.tr(),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text(
                'postcard_updates_content'.tr(),
                style: Theme.of(context).textTheme.moMASans700AuGrey18,
              ),
            ),
            const SizedBox(height: 40),
            PostcardAsyncButton(
              text: 'enable'.tr(),
              color: AppColor.momaGreen,
              onTap: () async {
                bool result = false;
                try {
                  result = await registerPushNotifications(askPermission: true);
                } catch (error) {
                  log.warning('Error when setting notification: $error');
                }
                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context, result);
              },
            ),
          ],
        ),
        isDismissible: true);
    if (result) {
      if (!context.mounted) {
        return;
      }
      await _showPostcardInfo(context, message: 'postcard_noti_enabled'.tr());
    }
  }

  static Future<void> showPostcardShareLinkExpired(BuildContext context) async {
    await UIHelper.showDialog(
      context,
      'claim_has_expired'.tr(),
      Column(
        children: [
          Text('claim_has_expired_desc'.tr(),
              style: Theme.of(context).textTheme.ppMori400White14),
          const SizedBox(height: 40),
          OutlineButton(
            onTap: () => Navigator.pop(context),
            text: 'close'.tr(),
          ),
        ],
      ),
    );
  }

  static Future<void> showPostcardShareLinkInvalid(BuildContext context) async {
    await UIHelper.showDialog(
      context,
      'link_expired_or_claimed'.tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('link_expired_or_claimed_desc'.tr(),
              style: Theme.of(context).textTheme.ppMori400White14),
          const SizedBox(height: 40),
          OutlineButton(
            onTap: () => Navigator.pop(context),
            text: 'close'.tr(),
          ),
        ],
      ),
      isDismissible: true,
    );
  }

  static Future<dynamic> showCustomDialog(
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
      builder: (context) => Container(
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
      ),
    );
  }

  static Future<void> showLocationExplain(BuildContext context) async {
    final theme = Theme.of(context);
    return showCustomDialog(
      context: context,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset('assets/images/postcard_location_explain_3.png'),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset('assets/images/location.svg'),
                        Text(
                          'web'.tr(),
                          style: theme.textTheme.moMASans400Black16
                              .copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'plus_distance'.tr(namedArgs: {
                      'distance': DistanceFormatter().format(distance: 0),
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
          Text('if_your_location_is_not_enabled'.tr(),
              style: theme.textTheme.moMASans400Black16.copyWith(fontSize: 18)),
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
      'postcards_ran_out'.tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('postcards_ran_out_desc'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .ppMori400White14
                  .copyWith(height: 2)),
          const SizedBox(height: 40),
          PrimaryButton(
            onTap: () => Navigator.pop(context),
            text: 'close'.tr(),
          ),
        ],
      ),
      isDismissible: true,
    );
  }

  static Future<void> showPostcardQRExpired(BuildContext context) async {
    await await UIHelper.showDialog(
      context,
      'qr_code_expired'.tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('qr_code_expired_scan_again'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .ppMori400White14
                  .copyWith(height: 2)),
          const SizedBox(height: 40),
          PrimaryButton(
            onTap: () => Navigator.pop(context),
            text: 'close'.tr(),
          ),
        ],
      ),
      isDismissible: true,
    );
  }

  static Future<void> openSnackBarExistFullScreen(BuildContext context) async {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColor.feralFileHighlight.withOpacity(0.9),
            borderRadius: BorderRadius.circular(64),
          ),
          child: Text(
            'shake_exit'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.ppMori600Black12,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static Future<void> showPostcardStampSaved(BuildContext context) async =>
      await _showFileSaved(context, title: 'stamp'.tr());

  static Future<void> showPostcardSaved(BuildContext context) async =>
      await _showFileSaved(context, title: 'postcard'.tr());

  static Future<void> showFeralfileArtworkSaved(BuildContext context) async =>
      await _showFileSaved(context, title: '_artwork'.tr());

  static Future<void> _showFileSaved(BuildContext context,
      {required String title}) async {
    final options = [
      OptionItem(
        title: '_saved'.tr(args: [title]),
        icon: SvgPicture.asset('assets/images/download.svg'),
        onTap: () {},
      ),
    ];
    await showAutoDismissDialog(context,
        showDialog: () async =>
            showPostcardDrawerAction(context, options: options),
        autoDismissAfter: const Duration(seconds: 2));
  }

  static Future<void> showPostcardStampFailed(
    final BuildContext context,
  ) async {
    await _showPostcardError(context, message: 'postcard_stamp_failed'.tr());
  }

  static Future<void> showPostcardClaimLimited(
    final BuildContext context,
  ) async {
    await _showPostcardError(context, message: 'postcard_claim_limited'.tr());
  }

  static Future<void> showPostcardNotInMiami(
    final BuildContext context,
  ) async {
    await _showPostcardError(context,
        message: 'miami_error_message'.tr(), lastInSec: 5);
  }

  static Future<void> _showPostcardError(BuildContext context,
      {String message = '', Widget? icon, int lastInSec = 3}) async {
    final options = [
      OptionItem(
        title: message,
        icon: icon,
        titleStyle: Theme.of(context)
            .textTheme
            .moMASans700Black16
            .copyWith(fontSize: 18, color: MoMAColors.moMA3),
      ),
    ];
    await showAutoDismissDialog(context,
        showDialog: () async =>
            showPostcardDrawerAction(context, options: options),
        autoDismissAfter: Duration(seconds: lastInSec));
  }

  static Future<void> _showPostcardInfo(BuildContext context,
      {String message = '', Widget? icon}) async {
    final options = [
      OptionItem(
        title: message,
        icon: icon,
      ),
    ];
    await showAutoDismissDialog(context,
        showDialog: () async =>
            showPostcardDrawerAction(context, options: options),
        autoDismissAfter: const Duration(seconds: 2));
  }

  static Future<void> showPostcardStampPhotoAccessFailed(
          BuildContext context) async =>
      await _showPhotoAccessFailed(context, title: 'stamp'.tr());

  static Future<void> showPostcardPhotoAccessFailed(
          BuildContext context) async =>
      await _showPhotoAccessFailed(context, title: 'postcard'.tr());

  static Future<void> _showPhotoAccessFailed(BuildContext context,
          {required String title}) async =>
      await _showPostcardError(
        context,
        message: '_could_not_be_saved'.tr(args: [title]),
        icon: SvgPicture.asset('assets/images/postcard_hide.svg'),
      );

  static Future<void> showPostcardStampSavedFailed(
          BuildContext context) async =>
      await _showFileSaveFailed(context, title: 'stamp'.tr());

  static Future<void> showPostcardSavedFailed(BuildContext context) async =>
      await _showFileSaveFailed(context, title: 'postcard'.tr());

  static Future<void> showFeralfileArtworkSavedFailed(
          BuildContext context) async =>
      await _showFileSaveFailed(context, title: '_artwork'.tr());

  static Future<void> _showFileSaveFailed(BuildContext context,
          {required String title}) async =>
      await _showPostcardError(context,
          message: '_save_failed'.tr(args: [title]),
          icon: SvgPicture.asset('assets/images/exit.svg'));

  static Future<void> showConnectFailed(BuildContext context,
          {required String message}) async =>
      await showErrorDialog(
          context, 'connect_failed'.tr(), message, 'close'.tr());

  static Future<void> showTVConnectError(
      BuildContext context, FeralfileError error) async {
    final description = '${error.code}: ${error.message}';
    await showInfoDialog(context, 'tv_connection_issue'.tr(), description,
        onClose: () {}, isDismissible: true);
  }

  static void showUpgradedNotification() {
    final currentContext = injector<NavigationService>().context;
    if (!currentContext.mounted) {
      return;
    }
    showInAppNotifications(
      currentContext,
      'upgraded_notification_body'.tr(),
      'subscription_upgraded',
    );
  }

  static Future<dynamic> showNotificationPrompt(
      EnableNotificationPromptType type) async {
    final context = injector<NavigationService>().context;
    if (!context.mounted) {
      return null;
    }
    return await showCenterDialog(
      context,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.title, style: Theme.of(context).textTheme.ppMori700White24),
          const SizedBox(height: 20),
          Text(type.description,
              style: Theme.of(context).textTheme.ppMori400White14),
          const SizedBox(height: 20),
          PrimaryButton(
            onTap: () async {
              Navigator.of(context).pop(true);
              openAppSettings();
            },
            text: 'go_to_notifications'.tr(),
          ),
        ],
      ),
    );
  }
}

Widget loadingScreen(ThemeData theme, String text) => Scaffold(
      backgroundColor: AppColor.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/loading.gif',
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

String getDateTimeRepresentation(DateTime dateTime) =>
    Jiffy.parseFromDateTime(dateTime).fromNow();

class OptionItem {
  String? title;
  TextStyle? titleStyle;
  TextStyle? titleStyleOnPrecessing;
  TextStyle? titleStyleOnDisable;
  Function()? onTap;
  bool isEnable;
  Widget? icon;
  Widget? iconOnProcessing;
  Widget? iconOnDisable;
  Widget Function(BuildContext context, OptionItem item)? builder;
  Widget? separator;

  OptionItem({
    this.title,
    this.titleStyle,
    this.titleStyleOnPrecessing,
    this.titleStyleOnDisable,
    this.onTap,
    this.isEnable = true,
    this.icon,
    this.iconOnProcessing,
    this.iconOnDisable,
    this.builder,
    this.separator,
  });

  static OptionItem emptyOptionItem = OptionItem(title: '');
}
