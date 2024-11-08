//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/account/recovery_phrase_page.dart';
import 'package:autonomy_flutter/screen/alumni_details/alumni_details_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
import 'package:autonomy_flutter/screen/github_doc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/shared.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/feral_file_custom_tab.dart';
import 'package:autonomy_flutter/util/feral_file_helper.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/subscription_detail_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/display_instruction_view.dart';
import 'package:autonomy_flutter/view/membership_card.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/stream_device_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:libauk_dart/libauk_dart.dart';
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
      showEventErrorDialog(
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
      AppRouter.alumniDetailsPage,
      arguments: AlumniDetailsPagePayload(alumniID: id),
    );
  }

  Future<void> openFeralFileCuratorPage(String id) async {
    if (id.contains(',') || id.isEmpty) {
      return;
    }
    await Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppRouter.alumniDetailsPage,
      arguments: AlumniDetailsPagePayload(alumniID: id),
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
      case AppRouter.organizePage:
        route = AppRouter.homePageNoTransition;
        homeNavigationTab = HomeNavigatorTab.collection;
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

  Future<void> openPlaylist({required PlayListModel playlist}) async {
    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return;
    }
    await navigatorKey.currentState?.pushNamed(
      AppRouter.viewPlayListPage,
      arguments: ViewPlaylistScreenPayload(playListModel: playlist),
    );
  }

  Future<void> showALreadyClaimPlaylist(
      {required PlayListModel playlist}) async {
    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return;
    }
    await UIHelper.showMessageActionNew(
      context,
      'already_claimed_playlist'.tr(),
      'already_claimed_playlist_desc'.tr(),
      onClose: () => UIHelper.hideInfoDialog(context),
      isDismissible: true,
      actionButton: 'view_playlist'.tr(),
      onAction: () {
        goBack();
        openPlaylist(playlist: playlist);
      },
    );
  }

  Future<void>? showPlaylistActivationExpired() async {
    if (navigatorKey.currentState?.mounted != true ||
        navigatorKey.currentContext == null) {
      return;
    }
    await UIHelper.showMessageActionNew(
      context,
      'activation_expired'.tr(),
      'activation_expired_desc'.tr(),
      isDismissible: true,
    );
  }

  Future<void> showFlexibleDialog(
    Widget content, {
    bool isDismissible = false,
    bool isRoundCorner = true,
    Color? backgroundColor,
    int autoDismissAfter = 0,
    FeedbackType? feedback = FeedbackType.selection,
  }) async {
    await UIHelper.showFlexibleDialog(
      context,
      content,
      isDismissible: isDismissible,
      isRoundCorner: isRoundCorner,
      backgroundColor: backgroundColor,
      autoDismissAfter: autoDismissAfter,
      feedback: feedback,
    );
  }

  Widget _stepBuilder(BuildContext context, int step, Widget child) {
    final numberFormater = NumberFormat('00');
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numberFormater.format(step),
          style: theme.textTheme.ppMori700White14,
        ),
        const SizedBox(width: 30),
        Expanded(child: child),
      ],
    );
  }

  Widget _getStep1(BuildContext context, SupportedDisplayBranch displayBranch) {
    final theme = Theme.of(context);
    switch (displayBranch) {
      case SupportedDisplayBranch.samsung:
        return RichText(
          textScaler: MediaQuery.textScalerOf(context),
          text: TextSpan(
            style: theme.textTheme.ppMori400White14,
            children: [
              TextSpan(
                text: "${'search_for'.tr()} ",
              ),
              WidgetSpan(
                baseline: TextBaseline.alphabetic,
                alignment: PlaceholderAlignment.baseline,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColor.white),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    textScaler: const TextScaler.linear(1),
                    'feral_file'.tr(),
                    style: theme.textTheme.ppMori700White14,
                  ),
                ),
              ),
              TextSpan(
                text: " ${'app_from_samsung'.tr()}.",
              ),
            ],
          ),
        );
      case SupportedDisplayBranch.lg:
        return const SizedBox();
      case SupportedDisplayBranch.chromecast:
      case SupportedDisplayBranch.sony:
      case SupportedDisplayBranch.Hisense:
      case SupportedDisplayBranch.TCL:
        return RichText(
          textScaler: MediaQuery.textScalerOf(context),
          text: TextSpan(
            style: theme.textTheme.ppMori400White14,
            children: [
              TextSpan(
                text: "${'search_for'.tr()} ",
              ),
              WidgetSpan(
                baseline: TextBaseline.alphabetic,
                alignment: PlaceholderAlignment.baseline,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColor.white),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    textScaler: const TextScaler.linear(1),
                    'feral_file'.tr(),
                    style: theme.textTheme.ppMori700White14,
                  ),
                ),
              ),
              TextSpan(
                text: " ${'in_app_store_section'.tr()}",
              ),
            ],
          ),
        );
      case SupportedDisplayBranch.other:
        return RichText(
          textScaler: MediaQuery.textScalerOf(context),
          text: TextSpan(
            style: theme.textTheme.ppMori400White14,
            children: [
              TextSpan(
                text: "${'type'.tr()} ",
              ),
              WidgetSpan(
                baseline: TextBaseline.alphabetic,
                alignment: PlaceholderAlignment.baseline,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColor.white),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    textScaler: const TextScaler.linear(1),
                    'https://display.feralfile.com',
                    style: theme.textTheme.ppMori700White14,
                  ),
                ),
              ),
              TextSpan(
                text: " ${'on_tv_browser'.tr()}.",
              ),
            ],
          ),
        );
    }
  }

  Widget _getStep2(BuildContext context, SupportedDisplayBranch displayBranch) {
    final theme = Theme.of(context);
    switch (displayBranch) {
      case SupportedDisplayBranch.lg:
        return const SizedBox();
      case SupportedDisplayBranch.samsung:
      case SupportedDisplayBranch.chromecast:
      case SupportedDisplayBranch.sony:
      case SupportedDisplayBranch.Hisense:
      case SupportedDisplayBranch.TCL:
        return Text(
          'install_and_launch_tv_app'.tr(),
          style: theme.textTheme.ppMori400White14,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case SupportedDisplayBranch.other:
        return Text(
          'open_url_and_discover_daily'.tr(),
          style: theme.textTheme.ppMori400White14,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Widget _getStep(SupportedDisplayBranch displayBranch, Function? onScanQRTap) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepBuilder(
          context,
          1,
          _getStep1(
            context,
            displayBranch,
          ),
        ),
        const SizedBox(height: 10),
        _stepBuilder(
          context,
          2,
          _getStep2(
            context,
            displayBranch,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        _stepBuilder(
          context,
          3,
          RichText(
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              style: theme.textTheme.ppMori400White14,
              children: [
                TextSpan(
                  text: 'go_to_setting_tv'.tr(),
                ),
                TextSpan(
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      onScanQRTap?.call();
                    },
                  text: 'scan_the_qr_code'.tr(),
                  style: onScanQRTap != null
                      ? const TextStyle(
                          decoration: TextDecoration.underline,
                        )
                      : null,
                ),
                TextSpan(
                  text: " ${'on_your_TV'.tr()}.",
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> showHowToDisplay(
    SupportedDisplayBranch displayBranch,
    Function? onScanQRTap,
  ) async {
    Widget child;
    final theme = Theme.of(context);
    child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Art on',
                      style: theme.textTheme.ppMori700White24,
                    ),
                    const SizedBox(height: 6),
                    displayBranch.logo,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  injector<NavigationService>().showStreamAction('', null);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 22, bottom: 22),
                  child: SvgPicture.asset('assets/images/left-arrow.svg',
                      width: 22,
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        AppColor.white,
                        BlendMode.srcIn,
                      )),
                ),
              )
            ],
          ),
          const SizedBox(height: 36),
          displayBranch.demoPicture(context),
          const SizedBox(height: 36),
          if (displayBranch.isComingSoon)
            const SizedBox(
              height: 125,
            )
          else
            _getStep(displayBranch, onScanQRTap),
        ],
      ),
    );
    Navigator.pop(context);
    unawaited(injector<NavigationService>().showFlexibleDialog(
      child,
      isDismissible: true,
    ));
  }

  Future<void> showStreamAction(String displayKey,
      Function(CanvasDevice device)? onDeviceSelected) async {
    keyboardManagerKey.currentState?.hideKeyboard();
    await injector<NavigationService>().showFlexibleDialog(
      BlocProvider.value(
        value: injector<CanvasDeviceBloc>(),
        child: StreamDeviceView(
          displayKey: displayKey,
          onDeviceSelected: (canvasDevice) {
            onDeviceSelected?.call(canvasDevice);
          },
        ),
      ),
      isDismissible: true,
    );
  }

  Future<void> openUrl(Uri uri) async {
    await _browser.openUrl(uri.toString());
  }

  Future<void> showBackupRecoveryPhraseDialog() async {
    final primaryAddressInfo =
        await injector<AddressService>().getPrimaryAddressInfo();
    final uuid = primaryAddressInfo?.uuid;
    final walletStorage = uuid == null ? null : WalletStorage(uuid);
    if (context.mounted) {
      await UIHelper.showCenterSheet(context,
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'upgrade_required'.tr(),
                  style: Theme.of(context).textTheme.ppMori700White24,
                ),
                const SizedBox(height: 50),
                Text(
                  'your_device_not_support_passkey_desc'.tr(),
                  style: Theme.of(context).textTheme.ppMori400White14,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. ',
                          style: Theme.of(context).textTheme.ppMori400White14),
                      Expanded(
                        child: Text(
                          'step_1_backup_recovery'.tr(),
                          style: Theme.of(context).textTheme.ppMori400White14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2. ',
                          style: Theme.of(context).textTheme.ppMori400White14),
                      Expanded(
                        child: Text(
                          'step_2_move_to_another_wallet'.tr(),
                          style: Theme.of(context).textTheme.ppMori400White14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    PrimaryButton(
                      text: 'backup_recovery_phrase'.tr(),
                      onTap: walletStorage == null
                          ? null
                          : () {
                              navigateTo(AppRouter.recoveryPhrasePage,
                                  arguments: RecoveryPhrasePayload(
                                      wallet: walletStorage));
                            },
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      child: Text('need_help'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .ppMori400White14
                              .copyWith(
                                color: AppColor.auQuickSilver,
                                decoration: TextDecoration.underline,
                              )),
                      onTap: () {
                        navigateTo(
                          AppRouter.supportThreadPage,
                          arguments: NewIssuePayload(
                              reportIssueType: ReportIssueType.Bug),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          backgroundColor: AppColor.auGreyBackground,
          withExitButton: false,
          verticalPadding: 0);
    }
  }
}
