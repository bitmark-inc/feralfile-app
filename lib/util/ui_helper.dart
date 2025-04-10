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

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/user_interactivity_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/confetti.dart';
import 'package:autonomy_flutter/view/passkey/passkey_login_view.dart';
import 'package:autonomy_flutter/view/passkey/passkey_register_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/slide_router.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:confetti/confetti.dart';
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

enum ActionState { notRequested, loading, error, done }

const SHOW_DIALOG_DURATION = Duration(seconds: 2);
const SHORT_SHOW_DIALOG_DURATION = Duration(seconds: 1);

void nameContinue(BuildContext context) {
  Navigator.of(context).popUntil(
    (route) =>
        route.settings.name == AppRouter.homePage ||
        route.settings.name == AppRouter.homePageNoTransition ||
        route.settings.name == AppRouter.walletPage,
  );
}

class UIHelper {
  static String currentDialogTitle = '';
  static final metricClient = injector.get<MetricClientService>();
  static const String ignoreBackLayerPopUpRouteName = 'popUp.ignoreBackLayer';
  static const String homeMenu = 'homeMenu';
  static const String artDisplaySettingModal = 'artDisplaySettingModal';
  static const String artistArtworkDisplaySettingModal =
      'artistArtworkDisplaySettingModal';

  static Future<dynamic> showDialog(
    BuildContext context,
    String title,
    Widget content, {
    bool isDismissible = true,
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
    final bottomSheetKey = GlobalKey();

    if (autoDismissAfter > 0) {
      Future.delayed(
        Duration(seconds: autoDismissAfter),
        () => hideInfoDialog(context),
      );
    }

    if (feedback != null) {
      Vibrate.feedback(feedback);
    }

    return showModalBottomSheet<dynamic>(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      constraints: BoxConstraints(
        maxWidth: ResponsiveLayout.isMobile
            ? double.infinity
            : Constants.maxWidthModalTablet,
      ),
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.5),
      routeSettings: RouteSettings(
        name: ignoreBackLayerPopUpRouteName,
        arguments: {
          'key': bottomSheetKey,
        },
      ),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 150),
        reverseDuration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeOutQuart,
      ),
      builder: (context) => Container(
        key: bottomSheetKey,
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
                          child: Text(
                            title,
                            style: theme.primaryTextTheme.ppMori700White24,
                          ),
                        ),
                        if (withCloseIcon)
                          IconButton(
                            onPressed: () => hideInfoDialog(context),
                            icon: SvgPicture.asset(
                              'assets/images/circle_close.svg',
                              width: 22,
                              height: 22,
                            ),
                          ),
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
        Duration(seconds: autoDismissAfter),
        () => hideInfoDialog(context),
      );
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
            : Constants.maxWidthModalTablet,
      ),
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
                    child: Text(
                      title,
                      style: theme.primaryTextTheme.moMASans700Black18,
                    ),
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
    Future.delayed(const Duration(milliseconds: 300), confettiController.play);
    if (autoDismissAfter > 0) {
      Future.delayed(
        Duration(seconds: autoDismissAfter),
        () => hideInfoDialog(context),
      );
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
                          left: 15,
                          right: 15,
                          bottom: 50,
                        ),
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
        Duration(seconds: autoDismissAfter),
        () => hideInfoDialog(context),
      );
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
            : Constants.maxWidthModalTablet,
      ),
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
    bool closeable = true,
    bool isRoundCorner = true,
    String? title,
    Color? backgroundColor,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
    String? name,
  }) async {
    final theme = Theme.of(context);
    final bottomSheetKey = GlobalKey();

    if (autoDismissAfter > 0) {
      Future.delayed(
        Duration(seconds: autoDismissAfter),
        () => hideInfoDialog(context),
      );
    }

    if (feedback != null) {
      Vibrate.feedback(feedback);
    }

    return showModalBottomSheet<dynamic>(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      constraints: BoxConstraints(
        maxWidth: ResponsiveLayout.isMobile
            ? double.infinity
            : Constants.maxWidthModalTablet,
      ),
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.5),
      routeSettings: RouteSettings(
        name: name ?? ignoreBackLayerPopUpRouteName,
        arguments: {
          'key': bottomSheetKey,
        },
      ),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 150),
        reverseDuration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeOutQuart,
      ),
      builder: (context) => ColoredBox(
        key: bottomSheetKey,
        color: Colors.transparent,
        child: ClipPath(
          clipper: isRoundCorner ? AutonomyTopRightRectangleClipper() : null,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? theme.auGreyBackground,
              borderRadius: isRoundCorner
                  ? const BorderRadius.only(
                      topRight: Radius.circular(20),
                    )
                  : null,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (closeable) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title ?? '',
                            style: theme.textTheme.ppMori700White14,
                          ),
                          IconButton(
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
                        ],
                      ),
                    ),
                  ],
                  content,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<T?> showRetryDialog<T>(
    BuildContext context, {
    required String description,
    FutureOr<T> Function()? onRetry,
    ValueNotifier<bool>? dynamicRetryNotifier,
  }) async {
    final theme = Theme.of(context);
    final hasRetry = onRetry != null;
    final res = await showDialog(
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
                              context,
                              onRetry(),
                            );
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
    return res as T?;
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
    final bottomSheetKey = GlobalKey();
    if (autoDismissAfter > 0) {
      Future.delayed(
        Duration(seconds: autoDismissAfter),
        () => hideInfoDialog(context),
      );
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
            : Constants.maxWidthModalTablet,
      ),
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.5),
      routeSettings: RouteSettings(
        name: ignoreBackLayerPopUpRouteName,
        arguments: {
          'key': bottomSheetKey,
        },
      ),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 150),
        reverseDuration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeOutQuart,
      ),
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
        Duration(seconds: autoDismissAfter),
        () => hideInfoDialog(context),
      );
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
              const SizedBox(height: 10),
            ],
            OutlineButton(
              onTap: () => onClose?.call() ?? Navigator.pop(context),
              text: closeButton ?? 'cancel_dialog'.tr(),
            ),
            const SizedBox(height: 15),
          ],
        ),
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
        Duration(seconds: autoDismissAfter),
        () => hideInfoDialog(context),
      );
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

  static Future<void> showDialogAction(
    BuildContext context, {
    List<OptionItem>? options,
  }) async {
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
                    onTap: options?[index].onTap,
                  )
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
    BuildContext context,
    String title,
    String description, {
    bool isDismissible = true,
    int autoDismissAfter = 0,
    String closeButton = '',
    VoidCallback? onClose,
    FeedbackType? feedback = FeedbackType.selection,
  }) async {
    log.info('[UIHelper] showInfoDialog: $title, $description');
    final theme = Theme.of(context);

    if (autoDismissAfter > 0) {
      Future.delayed(
        Duration(seconds: autoDismissAfter),
        () => hideInfoDialog(context),
      );
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
            ],
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
            !route.settings.name!.toLowerCase().contains('popup'),
      );
    } catch (_) {}
  }

  static void hideDialogWithResult<T>(BuildContext context, T result) {
    currentDialogTitle = '';
    Navigator.pop(context, result);
  }

  static Future<void> showHideArtworkResultDialog(
    BuildContext context,
    bool isHidden, {
    required Function() onOK,
  }) async {
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
              text: TextSpan(
                children: [
                  TextSpan(
                    style: theme.textTheme.ppMori400White14,
                    text: '${'art_no_appear'.tr()} ',
                  ),
                  TextSpan(
                    style: theme.textTheme.ppMori700White14,
                    text: 'hidden_artwork'.tr(),
                  ),
                  TextSpan(
                    style: theme.textTheme.ppMori400White14,
                    text: ' ${'section_setting'.tr()}',
                  ),
                ],
              ),
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
      ),
    );
  }

  static Future<void> showIdentityDetailDialog(
    BuildContext context, {
    required String name,
    required String address,
  }) async {
    final theme = Theme.of(context);

    await showDialog(
      context,
      'identity'.tr(),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Share.share(address),
                  icon: SvgPicture.asset(
                    'assets/images/Share.svg',
                    colorFilter:
                        const ColorFilter.mode(AppColor.white, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            OutlineButton(
              onTap: () {
                Navigator.of(context).pop();
              },
              text: 'close'.tr(),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  static Future<void> showLoadingScreen(
    BuildContext context, {
    String text = '',
  }) async {
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

  static Future<JWT?> showPasskeyRegisterDialog(
    BuildContext context,
  ) async {
    final jwt = await showRawCenterSheet(
      context,
      content: const PasskeyRegisterView(),
    );
    return jwt as JWT?;
  }

  static Future<JWT?> showPasskeyLoginDialog(
    BuildContext context,
    Future<JWT?> Function() onRetry,
  ) async {
    final jwt = await showRawCenterSheet(
      context,
      content: PasskeyLoginRetryView(onRetry: onRetry),
    ) as JWT?;
    return jwt;
  }

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
                vertical: 20,
                horizontal: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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

  static Future<void> showCenterSheet(
    BuildContext context, {
    required Widget content,
    String? actionButton,
    Function()? actionButtonOnTap,
    String? exitButton,
    Function()? exitButtonOnTap,
    double horizontalPadding = 20,
    double verticalPadding = 128,
    bool withExitButton = true,
    Color backgroundColor = AppColor.feralFileHighlight,
  }) async {
    UIHelper.hideInfoDialog(context);
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
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
                    ),
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
                        color: AppColor.feralFileLightBlue,
                      ),
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

  static Future<dynamic> showCenterEmptySheet(
    BuildContext context, {
    required Widget content,
  }) async {
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
                horizontal: 15,
                vertical: 128,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  content,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<dynamic> showCenterDialog(
    BuildContext context, {
    required Widget content,
  }) async {
    // UIHelper.hideInfoDialog(context);
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
                    vertical: 20,
                    horizontal: 15,
                  ),
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
      ),
    );
  }

  static Future<void> showCenterMenu(
    BuildContext context, {
    required List<OptionItem> options,
    RouteSettings? routeSettings,
  }) async {
    final theme = Theme.of(context);
    await showCupertinoModalPopup(
      routeSettings: routeSettings,
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
                                child: option.icon!,
                              ),
                            ),
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
                            ),
                          ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showDrawerAction(
    BuildContext context, {
    required List<OptionItem> options,
    String? title,
  }) async {
    final theme = Theme.of(context);
    final bottomSheetKey = GlobalKey();

    await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      constraints: BoxConstraints(
        maxWidth: ResponsiveLayout.isMobile
            ? double.infinity
            : Constants.maxWidthModalTablet,
      ),
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      routeSettings: RouteSettings(
        name: ignoreBackLayerPopUpRouteName,
        arguments: {
          'key': bottomSheetKey,
        },
      ),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 150),
        reverseDuration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeOutQuart,
      ),
      builder: (context) => ColoredBox(
        key: bottomSheetKey,
        color: AppColor.auGreyBackground,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title ?? '',
                    style: theme.textTheme.ppMori700White14,
                  ),
                  IconButton(
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
                ],
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
      ),
    );
  }

  static Future<void> showAutoDismissDialog(
    BuildContext context, {
    required Function() showDialog,
    required Duration autoDismissAfter,
  }) async {
    Future.delayed(autoDismissAfter, () => hideInfoDialog(context));
    await showDialog();
  }

  static Future showAlreadyDelivered(BuildContext context) async {
    final title = 'already_delivered'.tr();
    final description = 'it_seems_that'.tr();
    return showErrorDialog(context, title, description, 'close'.tr());
  }

  static Future<void> showInvalidURI(BuildContext context) async {
    await UIHelper.showDialog(
      context,
      'invalid_uri'.tr(),
      Column(
        children: [
          Text(
            'invalid_uri_desc'.tr(),
            style: Theme.of(context).textTheme.ppMori400White14,
          ),
          const SizedBox(height: 40),
          OutlineButton(
            onTap: () => Navigator.pop(context),
            text: 'close'.tr(),
          ),
        ],
      ),
    );
  }

  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = false,
    Color? backgroundColor,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    String? name,
  }) async {
    final theme = Theme.of(context);
    return showModalBottomSheet<T>(
      routeSettings: RouteSettings(
        name: name ?? ignoreBackLayerPopUpRouteName,
      ),
      context: context,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      constraints: BoxConstraints(
        maxWidth: ResponsiveLayout.isMobile
            ? double.infinity
            : Constants.maxWidthModalTablet,
      ),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 500),
        reverseDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeOutQuart,
      ),
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
                ),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
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

  static Future<void> showTVConnectError(
    BuildContext context,
    FeralfileError error,
  ) async {
    final description = '${error.code}: ${error.message}';
    await showInfoDialog(
      context,
      'tv_connection_issue'.tr(),
      description,
      onClose: () {},
      isDismissible: true,
    );
  }

  static void showUpgradedNotification() {
    final currentContext = injector<NavigationService>().context;
    if (!currentContext.mounted) {
      return;
    }
    showSimpleNotificationToast(
      key: const Key('subscription_upgraded'),
      content: 'upgraded_notification_body'.tr(),
      vibrateFeedbackType: FeedbackType.warning,
    );
  }

  static Future<dynamic> showNotificationPrompt(
    EnableNotificationPromptType type,
  ) async {
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
          Text(
            type.description,
            style: Theme.of(context).textTheme.ppMori400White14,
          ),
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

  static Future<JWT?> showRegisterOrLoginDialog(BuildContext context,
      {required FutureOr<JWT?> Function() onRegister,
      required FutureOr<JWT?> Function() onLogin}) async {
    final jwt = await showCenterDialog(
      context,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'register_or_login'.tr(),
            style: Theme.of(context).textTheme.ppMori700White24,
          ),
          const SizedBox(height: 20),
          Text(
            'register_or_login_desc'.tr(),
            style: Theme.of(context).textTheme.ppMori400White14,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            onTap: () async {
              final jwt = await onRegister();
              if (context.mounted) {
                Navigator.of(context).pop(jwt);
              }
            },
            text: 'register'.tr(),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            onTap: () async {
              final jwt = await onLogin();
              if (context.mounted) {
                Navigator.of(context).pop(jwt);
              }
            },
            text: 'login'.tr(),
          ),
        ],
      ),
    );
    return jwt as JWT?;
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
            ),
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
  FutureOr<dynamic> Function()? onTap;
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
