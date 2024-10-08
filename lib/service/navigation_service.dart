//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/artist_details/artist_details_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
import 'package:autonomy_flutter/screen/github_doc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/shared.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/feral_file_custom_tab.dart';
import 'package:autonomy_flutter/util/feral_file_helper.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/subscription_detail_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/membership_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/database/nft_collection_database.dart';
import 'package:nft_collection/models/asset_token.dart'; // ignore_for_file: implementation_imports
import 'package:overlay_support/src/overlay_state_finder.dart';
import 'package:sentry/sentry.dart';
import 'package:url_launcher/url_launcher_string.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  PageController? _pageController;

  static const Key contactingKey = Key('tezos_beacon_contacting');

  // to prevent showing duplicate ConnectPage
  // workaround solution for unknown reason
  // ModalRoute(navigatorKey.currentContext) returns nil
  bool _isWCConnectInShow = false;
  final _browser = FeralFileBrowser();

  PageController? get pageController => _pageController;

  void setGlobalHomeTabController(PageController? controller) {
    _pageController = controller;
  }

  BuildContext get context => navigatorKey.currentContext!;

  bool get mounted => navigatorKey.currentContext?.mounted == true;

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    log.info('NavigationService.navigateTo: $routeName');

    if ((routeName == AppRouter.tbConnectPage ||
            routeName == AppRouter.wc2ConnectPage) &&
        _isWCConnectInShow) {
      log.info('[NavigationService] skip because WCConnectPage is in showing');
      return null;
    }

    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return null;
    }

    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic>? popAndPushNamed(String routeName, {Object? arguments}) {
    log.info('NavigationService.popAndPushNamed: $routeName');

    if ((routeName == AppRouter.wc2ConnectPage ||
            routeName == AppRouter.tbConnectPage) &&
        _isWCConnectInShow) {
      log.info(
          // ignore: lines_longer_than_80_chars
          '[NavigationService] skip popAndPushNamed because WCConnectPage is in showing');
      return null;
    }

    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return null;
    }

    return navigatorKey.currentState
        ?.popAndPushNamed(routeName, arguments: arguments);
  }

  Future<void> selectPromptsThenStamp(
      BuildContext context, AssetToken asset, String? shareCode) async {
    final prompt = asset.postcardMetadata.prompt;

    await popAndPushNamed(
        prompt == null ? AppRouter.promptPage : AppRouter.designStamp,
        arguments: DesignStampPayload(asset, true, shareCode));
  }

  Future<dynamic>? navigateUntil(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    log.info('NavigationService.navigateTo: $routeName');

    if ((routeName == AppRouter.tbConnectPage ||
            routeName == AppRouter.wc2ConnectPage) &&
        _isWCConnectInShow) {
      log.info('[NavigationService] skip because WCConnectPage is in showing');
      return null;
    }

    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return null;
    }

    return navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(routeName, predicate);
  }

  NavigatorState navigatorState() => Navigator.of(navigatorKey.currentContext!);

  void showErrorDialog(
    ErrorEvent event, {
    Function()? defaultAction,
    Function()? cancelAction,
  }) {
    log.info('NavigationService.showErrorDialog');

    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      showErrorDiablog(
        navigatorKey.currentContext!,
        event,
        defaultAction: defaultAction,
        cancelAction: cancelAction,
      );
    }
  }

  void hideInfoDialog() {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      UIHelper.hideInfoDialog(navigatorKey.currentContext!);
    }
  }

  Future<void> showAppLoadError() async {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      if (isShowErrorDialogWorking != null) {
        // pop the error dialog if it is showing
        isShowErrorDialogWorking = null;
        UIHelper.hideInfoDialog(navigatorKey.currentContext!);
      }
      isShowErrorDialogWorking = DateTime.now();
      final theme = Theme.of(context);
      unawaited(Sentry.captureMessage('App Load Error'));
      await UIHelper.showDialog(
        context,
        'App Load Error',
        Column(
          children: [
            Text(
              'it_seem_loading_issue'.tr(),
              style: theme.textTheme.ppMori400White14,
            ),
            const SizedBox(height: 24),
            RichText(
                text: TextSpan(
              style: theme.textTheme.ppMori400White14,
              children: <TextSpan>[
                TextSpan(
                  text: 'if_issue_persist'.tr(),
                ),
                TextSpan(
                  text: 'feralfile@support.com'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      log.info('send email to feralfile@support.com');
                      const href = 'mailto:support@feralfile.com';
                      launchUrlString(href);
                    },
                ),
                TextSpan(
                  text: 'for_assistance'.tr(),
                ),
              ],
            ))
          ],
        ),
        isDismissible: true,
      );

      await Future.delayed(const Duration(seconds: 1), () {
        isShowErrorDialogWorking = null;
      });
    }
  }

  void goBack({Object? result}) {
    log.info('NavigationService.goBack');
    return navigatorKey.currentState?.pop(result);
  }

  void popUntilHome() {
    navigatorKey.currentState?.popUntil((route) =>
        route.settings.name == AppRouter.homePage ||
        route.settings.name == AppRouter.homePageNoTransition);
  }

  void popUntilHomeOrSettings() {
    navigatorKey.currentState?.popUntil((route) =>
        route.settings.name == AppRouter.settingsPage ||
        route.settings.name == AppRouter.homePage ||
        route.settings.name == AppRouter.homePageNoTransition);
  }

  void setIsWCConnectInShow(bool appeared) {
    _isWCConnectInShow = appeared;
  }

  Future<void> showContactingDialog() async {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      bool dialogShowed = false;
      showInfoNotificationWithLink(
        contactingKey,
        'establishing_contact'.tr(),
        frontWidget: loadingIndicator(valueColor: AppColor.white),
        bottomRightWidget: GestureDetector(
          onTap: () {
            dialogShowed = true;
            waitTooLongDialog();
          },
          child: Text(
            'taking_too_long'.tr(),
            style: Theme.of(navigatorKey.currentContext!)
                .textTheme
                .ppMori400White12
                .copyWith(
                  color: AppColor.auQuickSilver,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColor.auQuickSilver,
                ),
          ),
        ),
        duration: const Duration(seconds: 15),
      );
      final OverlaySupportState? overlaySupport = findOverlayState();
      Future.delayed(const Duration(seconds: 4), () {
        if (!dialogShowed &&
            overlaySupport != null &&
            overlaySupport.getEntry(key: contactingKey) != null) {
          dialogShowed = true;
          waitTooLongDialog();
        }
      });
    }
  }

  Future<void> waitTooLongDialog() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(
        navigatorKey.currentContext!,
        'taking_too_long'.tr(),
        'if_take_too_long'.tr(),
        closeButton: 'cancel'.tr(),
        isDismissible: true,
        autoDismissAfter: 20,
        onClose: () {
          hideInfoDialog();
        },
      );
    }
  }

  Future<void> showQRExpired() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(
          context, 'qr_code_expired'.tr(), 'qr_code_expired_desc'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> addressNotFoundError() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(
          context, 'error'.tr(), 'can_not_find_address'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> showCannotConnectTv() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(context, 'can_not_connect_to_tv'.tr(),
          'can_not_connect_to_tv_desc'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> showUnknownLink() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(
          context, 'unknown_link'.tr(), 'unknown_link_desc'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> showCannotResolveBranchLink() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(context, 'can_not_resolve_branch_link'.tr(),
          'can_not_resolve_branch_link_desc'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> showMembershipGiftCodeEmpty() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(context, 'can_not_get_gift_code'.tr(),
          'can_not_get_gift_code_desc'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> showFailToRedeemMembership() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(context, 'fail_to_redeem_membership'.tr(),
          'fail_to_redeem_membership_desc'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> showRedeemMembershipCodeUsed() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(context, 'fail_to_redeem_membership'.tr(),
          'redeem_code_used_desc'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> showPremiumUserCanNotClaim() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(context, 'fail_to_redeem_membership'.tr(),
          'premium_user_can_not_claim'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> showRedeemMembershipSuccess() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showInfoDialog(context, 'redeem_membership_success'.tr(),
          'redeem_membership_success_desc'.tr(),
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }

  Future<void> showDeclinedGeolocalization() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showDeclinedGeolocalization(navigatorKey.currentContext!);
    }
  }

  Future<void> showSeeMoreArtNow(
      SubscriptionDetails subscriptionDetails) async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      final price = subscriptionDetails.price;
      final renewDate = subscriptionDetails.renewDate;
      await UIHelper.showDialog(
        context,
        'see_more_art_now'.tr(),
        withCloseIcon: true,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'see_more_art_now_desc'.tr(),
              style: Theme.of(context).textTheme.ppMori400White14,
            ),
            const SizedBox(height: 20),
            MembershipCard(
              type: MembershipCardType.premium,
              price: price,
              isProcessing: false,
              isEnable: false,
              onTap: (_) {},
              isCompleted: true,
              renewDate: renewDate,
            ),
          ],
        ),
        isDismissible: true,
      );
    }
  }

  Future<void> openPostcardReceivedPage(
      {required AssetToken asset, required String shareCode}) async {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      await navigatorKey.currentState?.pushNamed(
        AppRouter.receivePostcardPage,
        arguments: ReceivePostcardPageArgs(asset: asset, shareCode: shareCode),
      );
    } else {
      await Future.value(0);
    }
  }

  Future<void> gotoExhibitionDetailsPage(String exhibitionID) async {
    popUntilHome();
    await Future.delayed(const Duration(seconds: 1), () async {
      await (homePageKey.currentState ?? homePageNoTransactionKey.currentState)
          ?.openExhibition(exhibitionID);
    });
  }

  Future<void> popToCollection() async {
    popUntilHome();
    await injector<NavigationService>().openCollection();
  }

  Future<void> gotoArtworkDetailsPage(String indexID) async {
    popUntilHome();
    final tokens = await injector<NftCollectionDatabase>()
        .assetTokenDao
        .findAllAssetTokensByTokenIDs([indexID]);
    final owner = tokens.first.owner;
    final artworkDetailPayload =
        ArtworkDetailPayload(ArtworkIdentity(indexID, owner));
    if (context.mounted) {
      unawaited(Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
          arguments: artworkDetailPayload));
    }
  }

  Future<dynamic> goToIRLWebview(IRLWebScreenPayload payload) async {
    if (navigatorKey.currentState?.mounted == true &&
        navigatorKey.currentContext != null) {
      return await navigateTo(AppRouter.irlWebView, arguments: payload);
    } else {
      return {'result': false};
    }
  }

  Future<void> showAlreadyDeliveredPostcard() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showAlreadyDelivered(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardShareLinkExpired() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardShareLinkExpired(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardShareLinkInvalid() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardShareLinkInvalid(navigatorKey.currentContext!);
    }
  }

  Future<void> showLocationExplain() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showLocationExplain(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardRunOut() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardRunOut(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardQRCodeExpired() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardQRExpired(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardClaimLimited() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardClaimLimited(navigatorKey.currentContext!);
    }
  }

  Future<void> showPostcardNotInMiami() async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      await UIHelper.showPostcardNotInMiami(navigatorKey.currentContext!);
    }
  }

  Future<void> openAutonomyDocument(String href, String title) async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      final uri = Uri.parse(href.autonomyRawDocumentLink);
      final document = uri.pathSegments.last;
      final prefix =
          uri.pathSegments.sublist(0, uri.pathSegments.length - 1).join('/');
      await Navigator.of(navigatorKey.currentContext!).pushNamed(
        AppRouter.githubDocPage,
        arguments: GithubDocPayload(
          title: title,
          prefix: '/$prefix',
          document: '/$document',
        ),
      );
    }
  }

  Future<void> openFeralFileArtistPage(String id) async {
    if (id.contains(',') || id.isEmpty) {
      return;
    }
    await Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppRouter.userDetailsPage,
      arguments: UserDetailsPagePayload(userId: id),
    );
  }

  Future<void> openFeralFileCuratorPage(String id) async {
    if (id.contains(',') || id.isEmpty) {
      return;
    }
    await Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppRouter.userDetailsPage,
      arguments: UserDetailsPagePayload(userId: id),
    );
  }

  Future<void> openFeralFileExhibitionNotePage(String exhibitionSlug) async {
    if (exhibitionSlug.isEmpty) {
      return;
    }
    final url = FeralFileHelper.getExhibitionNoteUrl(exhibitionSlug);
    await _browser.openUrl(url);
  }

  Future<void> openCollection() async {
    await navigateTo(AppRouter.collectionPage);
  }

  Future<void> openFeralFilePostPage(Post post, String exhibitionID) async {
    if (post.slug.isEmpty || exhibitionID.isEmpty) {
      return;
    }
    final url = FeralFileHelper.getPostUrl(post, exhibitionID);
    await _browser.openUrl(url);
  }

  Future<void> navigatePath(String? path) async {
    final pair = _resolvePath(path);
    if (pair == null) {
      return;
    }
    late String route;
    HomeNavigatorTab? homeNavigationTab;
    FeralfileHomeTab? exploreTab;

    switch (pair.first) {
      case AppRouter.dailyWorkPage:
        route = AppRouter.homePageNoTransition;
        homeNavigationTab = HomeNavigatorTab.daily;
      case AppRouter.featuredPage:
        route = AppRouter.homePageNoTransition;
        homeNavigationTab = HomeNavigatorTab.explore;
        exploreTab = FeralfileHomeTab.featured;
      case AppRouter.artworksPage:
        route = AppRouter.homePageNoTransition;
        homeNavigationTab = HomeNavigatorTab.explore;
        exploreTab = FeralfileHomeTab.artworks;
      case AppRouter.exhibitionsPage:
        route = AppRouter.homePageNoTransition;
        homeNavigationTab = HomeNavigatorTab.explore;
        exploreTab = FeralfileHomeTab.exhibitions;
      case AppRouter.artistsPage:
        route = AppRouter.homePageNoTransition;
        homeNavigationTab = HomeNavigatorTab.explore;
        exploreTab = FeralfileHomeTab.artists;
      case AppRouter.curatorsPage:
        route = AppRouter.homePageNoTransition;
        homeNavigationTab = HomeNavigatorTab.explore;
        exploreTab = FeralfileHomeTab.curators;
      case AppRouter.rAndDPage:
        route = AppRouter.homePageNoTransition;
        homeNavigationTab = HomeNavigatorTab.explore;
        exploreTab = FeralfileHomeTab.rAndD;
      default:
        route = pair.first;
        unawaited(navigateTo(route, arguments: pair.second));
        return;
    }

    popUntilHome();

    await Future.delayed(const Duration(milliseconds: 300), () async {
      if (homeNavigationTab != null) {
        unawaited(
            (homePageKey.currentState ?? homePageNoTransactionKey.currentState)
                ?.onItemTapped(homeNavigationTab.index));

        await Future.delayed(const Duration(milliseconds: 300), () {
          if (exploreTab != null) {
            feralFileHomeKey.currentState?.jumpToTab(exploreTab);
          }
        });
      }
    });
  }

  Pair<String, dynamic>? _resolvePath(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }
    final parts = path.split('/')..removeWhere((element) => element.isEmpty);
    if (parts.isEmpty) {
      return null;
    }
    if (parts.length == 1) {
      return Pair(parts[0], null);
    }

    return Pair(parts[0], _resolveArgument(parts[1]));
  }

  dynamic _resolveArgument(String? argument) {
    if (argument == null || argument.isEmpty) {
      return null;
    }
    return argument;
  }

  Future<void> showEnvKeyIsMissing(List<String> keys) async {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentState?.mounted == true) {
      log.info('showEnvKeyIsMissing: $keys');
      await UIHelper.showInfoDialog(
          context, 'error'.tr(), 'Error while reading ${keys.join(', ')}',
          onClose: () => UIHelper.hideInfoDialog(context), isDismissible: true);
    }
  }
}
