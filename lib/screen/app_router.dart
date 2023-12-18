//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/account/access_method_page.dart';
import 'package:autonomy_flutter/screen/account/link_manually_page.dart';
import 'package:autonomy_flutter/screen/account/recovery_phrase_page.dart';
import 'package:autonomy_flutter/screen/account/select_account_page.dart';
import 'package:autonomy_flutter/screen/account/test_artwork_screen.dart';
import 'package:autonomy_flutter/screen/autonomy_security_page.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/bug_bounty_page.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
import 'package:autonomy_flutter/screen/claim/activation/activation_token_detail_page.dart';
import 'package:autonomy_flutter/screen/claim/activation/claim_activation_page.dart';
import 'package:autonomy_flutter/screen/claim/activation/preview_activation_claim.dart';
import 'package:autonomy_flutter/screen/claim/airdrop/claim_airdrop_page.dart';
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/screen/claim/select_account_page.dart';
import 'package:autonomy_flutter/screen/claim/token_detail_page.dart';
import 'package:autonomy_flutter/screen/cloud/cloud_android_page.dart';
import 'package:autonomy_flutter/screen/cloud/cloud_page.dart';
import 'package:autonomy_flutter/screen/connection/connection_details_page.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/screen/customer_support/support_customer_page.dart';
import 'package:autonomy_flutter/screen/customer_support/support_list_page.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/customer_support/tutorial_videos_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_help_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/keyboard_control_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/touchpad_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_primer.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_bloc.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/screen/github_doc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_navigation_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/claim_empty_postcard/claim_empty_postcard_screen.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/claim_empty_postcard/pay_to_mint_postcard_screen.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/hand_signature_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_get_location.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/prompt_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_bloc.dart';
import 'package:autonomy_flutter/screen/irl_screen/sign_message_screen.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_bloc.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_page.dart';
import 'package:autonomy_flutter/screen/notification_onboarding_page.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/import_seeds.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/name_address_persona.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/select_addresses.dart';
import 'package:autonomy_flutter/screen/onboarding/new_address/address_alias.dart';
import 'package:autonomy_flutter/screen/onboarding/new_address/choose_chain_page.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/name_view_only_page.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/screen/onboarding_page.dart';
import 'package:autonomy_flutter/screen/participate_user_test_page.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist.dart';
import 'package:autonomy_flutter/screen/playlists/edit_playlist/edit_playlist.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/screen/release_notes_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_select_account_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/linked_wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/data_management/data_management_page.dart';
import 'package:autonomy_flutter/screen/settings/help_us/help_us_page.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/screen/settings/hidden_artworks/hidden_artworks_bloc.dart';
import 'package:autonomy_flutter/screen/settings/hidden_artworks/hidden_artworks_page.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_page.dart';
import 'package:autonomy_flutter/screen/settings/settings_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/subscription_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/au_sign_message_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/screen/unsafe_web_wallet_page.dart';
import 'package:autonomy_flutter/screen/wallet/wallet_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/v2/wc2_permission_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/view/transparent_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:page_transition/page_transition.dart';

class AppRouter {
  static const createPlayListPage = 'createPlayList';
  static const viewPlayListPage = 'viewPlayList';
  static const editPlayListPage = 'editPlayList';
  static const previewPrimerPage = 'preview_primer';
  static const onboardingPage = 'onboarding';
  static const notificationOnboardingPage = 'notification_onboarding';
  static const nameLinkedAccountPage = 'name_linked_account';
  static const homePage = 'home_page';
  static const homePageNoTransition = 'home_page_NoTransition';
  static const artworkPreviewPage = 'artwork_preview';
  static const artworkDetailsPage = 'artwork_detail';
  static const claimedPostcardDetailsPage = 'claimed_postcard_detail';
  static const galleryPage = 'galleryPage';
  static const settingsPage = 'settings';
  static const personaConnectionsPage = 'persona_connections';
  static const connectionDetailsPage = 'connection_details';
  static const linkedAccountDetailsPage = 'linked_account_details';
  static const walletDetailsPage = 'wallet_detail';
  static const linkedWalletDetailsPage = 'linked_wallet_detail';
  static const scanQRPage = 'qr_scanner';
  static const globalReceivePage = 'global_receive';
  static const recoveryPhrasePage = 'recovery_phrase';
  static const wcConnectPage = 'wc_connect';
  static const cloudPage = 'cloud_page';
  static const cloudAndroidPage = 'cloud_android_page';
  static const linkManually = 'link_manually';
  static const testArtwork = 'test_artwork';
  static const autonomySecurityPage = 'autonomy_security';
  static const unsafeWebWalletPage = 'unsafeWebWalletPage';
  static const releaseNotesPage = 'releaseNotesPage';
  static const hiddenArtworksPage = 'hidden_artworks';
  static const supportCustomerPage = 'supportCustomerPage';
  static const supportListPage = 'supportListPage';
  static const supportThreadPage = 'supportThreadPage';
  static const bugBountyPage = 'bugBountyPage';
  static const participateUserTestPage = 'participateUserTestPage';
  static const keySyncPage = 'key_sync_page';
  static const githubDocPage = 'github_doc_page';
  static const sendArtworkPage = 'send_artwork_page';
  static const sendArtworkReviewPage = 'send_artwork_review_page';
  static const claimFeralfileTokenPage = 'claim_feralfile_token_page';
  static const claimSelectAccountPage = 'claim_select_account_page';
  static const airdropTokenDetailPage = 'airdrop_token_detail_page';
  static const wc2ConnectPage = 'wc2_connect_page';
  static const wc2PermissionPage = 'wc2_permission_page';
  static const preferencesPage = 'preferences_page';
  static const walletPage = 'wallet_page';
  static const subscriptionPage = 'subscription_page';
  static const dataManagementPage = 'data_management_page';
  static const helpUsPage = 'help_us_page';
  static const inappWebviewPage = 'inapp_webview_page';
  static const postcardExplain = 'postcard_explain_screen';
  static const designStamp = 'design_stamp_screen';
  static const promptPage = 'prompt_page';
  static const choosePromptPage = 'choose_prompt_page';
  static const handSignaturePage = 'hand_signature_page';
  static const stampPreview = 'stamp_preview';
  static const claimEmptyPostCard = 'claim_empty_postcard';
  static const payToMintPostcard = 'pay_to_mint_postcard';
  static const selectAddressScreen = 'select_address_screen';
  static const receivePostcardPage = 'receive_postcard_page';
  static const receivePostcardSelectAccountPage =
      'receive_postcard_select_account_page';
  static const irlWebView = 'irl_web_claim';
  static const irlSignMessage = 'irl_sign_message';
  static const postcardConfirmingPage = 'postcard_confirming_page';
  static const canvasHelpPage = 'canvas_help_page';
  static const keyboardControlPage = 'keyboard_control_page';
  static const touchPadPage = 'touch_pad_page';
  static const claimAirdropPage = 'claim_airdrop_page';
  static const activationTokenDetailPage = 'activation_token_detail_page';
  static const claimActivationPage = 'claim_activation_page';
  static const previewActivationClaimPage = 'preview_activation_claim_page';
  static const postcardLeaderboardPage = 'postcard_leaderboard_page';
  static const postcardLocationExplain = 'postcard_location_explain';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final ethereumBloc = EthereumBloc(injector(), injector());
    final tezosBloc = TezosBloc(injector(), injector());
    final usdcBloc = USDCBloc(injector());
    final accountsBloc = AccountsBloc(injector(), injector());
    final personaBloc = PersonaBloc(
      injector<CloudDatabase>(),
      injector(),
      injector<AuditService>(),
    );
    final identityBloc = IdentityBloc(injector<AppDatabase>(), injector());
    final postcardDetailBloc = PostcardDetailBloc(
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
      injector(),
    );

    switch (settings.name) {
      case viewPlayListPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
            create: (_) => CanvasDeviceBloc(
              injector(),
            ),
            child: ViewPlaylistScreen(
              playListModel: settings.arguments as PlayListModel?,
            ),
          ),
        );
      case createPlayListPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => AddNewPlaylistScreen(
            playListModel: settings.arguments as PlayListModel?,
          ),
        );
      case editPlayListPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => EditPlaylistScreen(
            playListModel: settings.arguments as PlayListModel?,
          ),
        );
      case onboardingPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(providers: [
            BlocProvider(
              create: (_) => RouterBloc(
                injector(),
                injector(),
                injector(),
                injector<CloudDatabase>(),
                injector(),
                injector<AuditService>(),
                injector(),
              ),
            ),
          ], child: const OnboardingPage()),
        );

      case previewPrimerPage:
        return PageTransition(
            type: PageTransitionType.fade,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            settings: settings,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => identityBloc),
              ],
              child: PreviewPrimerPage(
                token: settings.arguments! as AssetToken,
              ),
            ));

      case homePageNoTransition:
        return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation1, animation2) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                        create: (_) => HomeBloc(
                              injector(),
                            )),
                    BlocProvider(create: (_) => identityBloc),
                    BlocProvider(
                      create: (_) => personaBloc,
                    ),
                  ],
                  child: const HomeNavigationPage(fromOnboarding: true),
                ),
            transitionDuration: const Duration());

      case homePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                        create: (_) => HomeBloc(
                              injector(),
                            )),
                    BlocProvider(create: (_) => identityBloc),
                    BlocProvider(
                      create: (_) => personaBloc,
                    ),
                  ],
                  child: const HomeNavigationPage(),
                ));

      case ChatThreadPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => ChatThreadPage(
              payload: settings.arguments! as ChatThreadPagePayload),
        );

      case postcardExplain:
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: PostcardExplain(
              payload: settings.arguments! as PostcardExplainPayload),
        );

      case designStamp:
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: DesignStampPage(
              payload: settings.arguments! as DesignStampPayload),
        );

      case promptPage:
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: PromptPage(payload: settings.arguments! as DesignStampPayload),
        );

      case AccessMethodPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => const AccessMethodPage(),
        );
      case handSignaturePage:
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: HandSignaturePage(
            payload: settings.arguments! as HandSignaturePayload,
          ),
        );

      case AppRouter.stampPreview:
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => identityBloc),
              BlocProvider(create: (_) => postcardDetailBloc),
            ],
            child: StampPreview(
                payload: settings.arguments! as StampPreviewPayload),
          ),
        );

      case notificationOnboardingPage:
        return CupertinoPageRoute(
          settings: settings,
          fullscreenDialog: true,
          builder: (context) => const NotificationOnboardingPage(),
        );

      case AppRouter.testArtwork:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => const TestArtworkScreen(),
        );

      case AppRouter.nameLinkedAccountPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider.value(
                value: accountsBloc,
                child: NameViewOnlyAddressPage(
                    connection: settings.arguments! as Connection)));

      case wcConnectPage:
        final argument = settings.arguments;
        if (argument is ConnectionRequest) {
          return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: accountsBloc),
              ],
              child: WCConnectPage(
                connectionRequest: argument,
              ),
            ),
          );
        }
        throw Exception('Invalid route: ${settings.name}');

      case WCSignMessagePage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => WCSignMessagePage(
              args: settings.arguments! as WCSignMessagePageArgs),
        );

      case WCSendTransactionPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
            create: (_) => WCSendTransactionBloc(
              injector(),
              injector(),
              injector(),
              injector(),
            ),
            child: WCSendTransactionPage(
                args: settings.arguments! as WCSendTransactionPageArgs),
          ),
        );
      case ScanQRPage.tag:
        return PageTransition(
            settings: settings,
            type: PageTransitionType.topToBottom,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            child: ScanQRPage(scannerItem: settings.arguments! as ScannerItem));

      case settingsPage:
        return CupertinoPageRoute(
            settings: settings,
            fullscreenDialog: true,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(create: (_) => personaBloc),
                  BlocProvider.value(value: ethereumBloc),
                  BlocProvider.value(value: tezosBloc),
                  BlocProvider(create: (_) => identityBloc),
                ], child: const SettingsPage()));

      case personaConnectionsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: accountsBloc),
                      BlocProvider.value(value: ethereumBloc),
                      BlocProvider.value(value: tezosBloc),
                      BlocProvider.value(value: usdcBloc),
                      BlocProvider.value(
                          value: ConnectionsBloc(
                        injector<CloudDatabase>(),
                        injector(),
                        injector(),
                        injector(),
                      ))
                    ],
                    child: PersonaConnectionsPage(
                        payload:
                            settings.arguments! as PersonaConnectionsPayload)));

      case connectionDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => ConnectionsBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                      injector(),
                    ),
                child: ConnectionDetailsPage(
                  connectionItem: settings.arguments! as ConnectionItem,
                )));

      case walletDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: accountsBloc),
                    BlocProvider.value(value: usdcBloc),
                    BlocProvider.value(
                        value: ConnectionsBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                      injector(),
                    )),
                    BlocProvider(
                        create: (_) => WalletDetailBloc(
                            injector(), injector(), injector())),
                  ],
                  child: WalletDetailPage(
                      payload: settings.arguments! as WalletDetailsPayload),
                ));
      case linkedWalletDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: usdcBloc),
                    BlocProvider(
                        create: (_) => WalletDetailBloc(
                            injector(), injector(), injector())),
                  ],
                  child: LinkedWalletDetailPage(
                      payload:
                          settings.arguments! as LinkedWalletDetailsPayload),
                ));
      case SendCryptoPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => SendCryptoBloc(
                      injector(),
                      injector(),
                      injector(),
                      (settings.arguments! as SendData).type,
                      injector()),
                  child: SendCryptoPage(data: settings.arguments! as SendData),
                ));
      case SendReviewPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => SendReviewPage(
                  payload: settings.arguments! as SendCryptoPayload,
                ));
      case artworkPreviewPage:
        return PageTransition(
            type: PageTransitionType.fade,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            settings: settings,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => ArtworkPreviewBloc(
                    injector(),
                    injector(),
                    injector(),
                  ),
                ),
                BlocProvider(
                  create: (_) => identityBloc,
                ),
                BlocProvider(
                  create: (_) => CanvasDeviceBloc(
                    injector(),
                  ),
                ),
                BlocProvider(create: (_) => postcardDetailBloc),
              ],
              child: ArtworkPreviewPage(
                payload: settings.arguments! as ArtworkDetailPayload,
              ),
            ));

      case ChooseChainPage.tag:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const ChooseChainPage());

      case ViewExistingAddress.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => ViewExistingAddress(
                  payload: settings.arguments! as ViewExistingAddressPayload,
                ));
      case ImportSeedsPage.tag:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const ImportSeedsPage());

      case SelectAddressesPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => ScanWalletBloc(injector(), injector()),
                  child: SelectAddressesPage(
                      payload: settings.arguments! as SelectAddressesPayload),
                ));

      case NameAddressPersona.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => NameAddressPersona(
                  payload: settings.arguments! as NameAddressPersonaPayload,
                ));

      case AddressAlias.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => personaBloc,
                  child: AddressAlias(
                      payload: settings.arguments! as AddressAliasPayload),
                ));

      case galleryPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                          create: (_) => GalleryBloc(injector(), injector())),
                      BlocProvider(create: (_) => identityBloc),
                    ],
                    child: GalleryPage(
                      payload: settings.arguments! as GalleryPagePayload,
                    )));

      case artworkDetailsPage:
        return PageTransition(
            type: PageTransitionType.fade,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            settings: settings,
            child: MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(create: (_) => identityBloc),
                  BlocProvider(
                      create: (_) => ArtworkDetailBloc(
                            injector(),
                            injector(),
                            injector(),
                            injector(),
                            injector(),
                            injector(),
                          )),
                ],
                child: ArtworkDetailPage(
                    payload: settings.arguments! as ArtworkDetailPayload)));

      case claimedPostcardDetailsPage:
        final payload = settings.arguments! as PostcardDetailPagePayload;
        return PageTransition(
            type: PageTransitionType.fade,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            settings: settings,
            child: MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(create: (_) => identityBloc),
                  BlocProvider(create: (_) => TravelInfoBloc()),
                  BlocProvider(create: (_) => postcardDetailBloc),
                ],
                child: ClaimedPostcardDetailPage(
                    key: payload.key, payload: payload)));
      case TBSignMessagePage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              TBSignMessagePage(request: settings.arguments! as BeaconRequest),
        );
      case AUSignMessagePage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              AUSignMessagePage(request: settings.arguments! as Wc2Request),
        );
      case TBSendTransactionPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => TBSendTransactionPage(
              request: settings.arguments! as BeaconRequest),
        );

      case recoveryPhrasePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => RecoveryPhrasePage(
                  words: settings.arguments! as List<String>,
                ));

      case cloudPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => CloudPage(
                  payload: settings.arguments! as CloudPagePayload,
                ));

      case cloudAndroidPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => CloudAndroidPage(
                  payload: settings.arguments! as CloudAndroidPagePayload,
                ));

      case globalReceivePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(
                    create: (_) => personaBloc,
                  ),
                  BlocProvider.value(value: ethereumBloc),
                  BlocProvider.value(value: tezosBloc),
                ], child: const GlobalReceivePage()));

      case GlobalReceiveDetailPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => GlobalReceiveDetailPage(
                  payload: settings.arguments! as GlobalReceivePayload,
                ));

      case autonomySecurityPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const AutonomySecurityPage());

      case unsafeWebWalletPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const UnsafeWebWalletPage());

      case releaseNotesPage:
        return PageTransition(
            settings: settings,
            type: PageTransitionType.bottomToTop,
            curve: Curves.easeIn,
            child: ReleaseNotesPage(
              releaseNotes: settings.arguments! as String,
            ));

      case supportCustomerPage:
        return PageTransition(
            settings: settings,
            type: PageTransitionType.topToBottom,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            child: const SupportCustomerPage());

      case supportListPage:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const SupportListPage());

      case TutorialVideo.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => TutorialVideo(
                  payload: settings.arguments! as TutorialVideosPayload,
                ));

      case supportThreadPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => SupportThreadPage(
                payload: settings.arguments! as SupportThreadPayload));

      case bugBountyPage:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const BugBountyPage());

      case participateUserTestPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const ParticipateUserTestPage());

      case hiddenArtworksPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => HiddenArtworksBloc(
                          injector<ConfigurationService>(), injector()),
                    ),
                  ],
                  child: const HiddenArtworksPage(),
                ));

      case githubDocPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => GithubDocPage(
                payload: settings.arguments! as Map<String, String>));

      case keySyncPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => KeySyncBloc(injector(), injector()),
                  child: const KeySyncPage(),
                ));

      case sendArtworkPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider(
                    create: (_) => SendArtworkBloc(
                        injector(),
                        injector(),
                        injector(),
                        injector(),
                        (settings.arguments! as SendArtworkPayload).asset)),
                BlocProvider(create: (_) => identityBloc),
              ],
              child: SendArtworkPage(
                  payload: settings.arguments! as SendArtworkPayload)),
        );

      case sendArtworkReviewPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => identityBloc,
                  child: SendArtworkReviewPage(
                      payload: settings.arguments! as SendArtworkReviewPayload),
                ));

      case claimFeralfileTokenPage:
        final args = settings.arguments! as ClaimTokenPageArgs;
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => ClaimTokenPage(
                  series: args.series,
                  otp: args.otp,
                  allowViewOnlyClaim: args.allowViewOnlyClaim,
                ));

      case airdropTokenDetailPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => TokenDetailPage(
                  series: settings.arguments! as FFSeries,
                ));

      case claimSelectAccountPage:
        final args = settings.arguments! as SelectAccountPageArgs;
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider.value(
                  value: accountsBloc,
                  child: SelectAccountPage(
                    blockchain: args.blockchain,
                    artwork: args.artwork,
                    otp: args.otp,
                    fromWebview: args.fromWebview,
                    withViewOnly: args.withViewOnly,
                  ),
                ));

      case wc2ConnectPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountsBloc),
              BlocProvider(
                create: (_) => personaBloc,
              ),
            ],
            child: WCConnectPage(
              connectionRequest: settings.arguments! as Wc2Proposal,
            ),
          ),
        );

      case linkManually:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) =>
                LinkManuallyPage(type: settings.arguments! as String));

      case wc2PermissionPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: accountsBloc),
                      BlocProvider(
                        create: (_) => personaBloc,
                      ),
                    ],
                    child: Wc2RequestPage(
                        request: settings.arguments! as Wc2Request)));

      case walletPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: accountsBloc),
                    BlocProvider(
                      create: (_) => personaBloc,
                    ),
                  ],
                  child: const WalletPage(),
                ));
      case preferencesPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider(
                    create: (_) => PreferencesBloc(injector()),
                  ),
                  BlocProvider.value(value: accountsBloc),
                ], child: const PreferencePage()));
      case subscriptionPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider(
                    create: (_) => UpgradesBloc(injector(), injector()),
                  ),
                ], child: const SubscriptionPage()));
      case dataManagementPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider(create: (_) => identityBloc),
                ], child: const DataManagementPage()));
      case helpUsPage:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const HelpUsPage());
      case inappWebviewPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => InAppWebViewPage(
                payload: settings.arguments! as InAppWebViewPayload));
      case claimEmptyPostCard:
        final claimRequest = settings.arguments! as RequestPostcardResponse;
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: ClaimEmptyPostCardScreen(claimRequest: claimRequest),
        );

      case payToMintPostcard:
        final claimRequest = settings.arguments! as PayToMintRequest;
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              PayToMintPostcardScreen(claimRequest: claimRequest),
        );

      case selectAddressScreen:
        final arguments = settings.arguments! as Map;
        final blockchain = arguments['blockchain'] as String;
        final onConfirm = arguments['onConfirm'] as Future Function(String);
        final withLinked = (arguments['withLinked'] ?? true) as bool;
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountsBloc),
            ],
            child: SelectAccountScreen(
              blockchain: blockchain,
              onConfirm: onConfirm,
              withLinked: withLinked,
            ),
          ),
        );
      case receivePostcardPage:
        final args = settings.arguments! as ReceivePostcardPageArgs;
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => identityBloc),
            ],
            child: ReceivePostCardPage(
              asset: args.asset,
              shareCode: args.shareCode,
            ),
          ),
        );
      case receivePostcardSelectAccountPage:
        final args =
            settings.arguments! as ReceivePostcardSelectAccountPageArgs;
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: BlocProvider.value(
            value: accountsBloc,
            child: ReceivePostcardSelectAccountPage(
              blockchain: args.blockchain,
              withLinked: args.withLinked,
            ),
          ),
        );

      case irlWebView:
        final payload = settings.arguments! as IRLWebScreenPayload;
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => IRLWebScreen(payload: payload));

      case irlSignMessage:
        final payload = settings.arguments! as IRLSignMessagePayload;
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => IRLSignMessageScreen(payload: payload));

      case canvasHelpPage:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const CanvasHelpPage());

      case keyboardControlPage:
        return TransparentRoute(
            settings: settings,
            builder: (context) {
              final payload = settings.arguments! as KeyboardControlPagePayload;
              return KeyboardControlPage(
                payload: payload,
              );
            });
      case touchPadPage:
        return TransparentRoute(
            settings: settings,
            builder: (context) {
              final payload = settings.arguments! as TouchPadPagePayload;
              return TouchPadPage(
                payload: payload,
              );
            });
      case claimAirdropPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: accountsBloc,
            child: ClaimAirdropPage(
              payload: settings.arguments! as ClaimTokenPagePayload,
            ),
          ),
        );

      case activationTokenDetailPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: accountsBloc,
            child: ActivationTokenDetailPage(
              assetToken: settings.arguments! as AssetToken,
            ),
          ),
        );

      case claimActivationPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: accountsBloc,
            child: ClaimActivationPage(
              payload: settings.arguments! as ClaimActivationPagePayload,
            ),
          ),
        );

      case previewActivationClaimPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: accountsBloc,
            child: PreviewActivationTokenPage(
              assetToken: settings.arguments! as AssetToken,
            ),
          ),
        );

      case postcardLeaderboardPage:
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountsBloc),
              BlocProvider(create: (_) => postcardDetailBloc),
            ],
            child: PostcardLeaderboardPage(
              payload: settings.arguments! as PostcardLeaderboardPagePayload,
            ),
          ),
        );
      case postcardLocationExplain:
        return PageTransition(
          settings: settings,
          type: PageTransitionType.rightToLeft,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          child: PostcardLocationExplain(
            payload: settings.arguments! as PostcardExplainPayload,
          ),
        );

      default:
        throw Exception('Invalid route: ${settings.name}');
    }
  }
}
