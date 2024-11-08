//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/account/access_method_page.dart';
import 'package:autonomy_flutter/screen/account/recovery_phrase_page.dart';
import 'package:autonomy_flutter/screen/account/test_artwork_screen.dart';
import 'package:autonomy_flutter/screen/activation/playlist_activation/playlist_activation_page.dart';
import 'package:autonomy_flutter/screen/alumni_details/alumni_details_bloc.dart';
import 'package:autonomy_flutter/screen/alumni_details/alumni_details_page.dart';
import 'package:autonomy_flutter/screen/alumni_details/alumni_exhibitions_page.dart';
import 'package:autonomy_flutter/screen/alumni_details/alumni_posts_page.dart';
import 'package:autonomy_flutter/screen/alumni_details/alumni_works_page.dart';
import 'package:autonomy_flutter/screen/autonomy_security_page.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/bug_bounty_page.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
import 'package:autonomy_flutter/screen/cloud/cloud_android_page.dart';
import 'package:autonomy_flutter/screen/cloud/cloud_page.dart';
import 'package:autonomy_flutter/screen/collection_pro/artists_list_page/artists_list_page.dart';
import 'package:autonomy_flutter/screen/connection/connection_details_page.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/screen/customer_support/merchandise_order/merchandise_orders_page.dart';
import 'package:autonomy_flutter/screen/customer_support/support_customer_page.dart';
import 'package:autonomy_flutter/screen/customer_support/support_list_page.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/keyboard_control_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/touchpad_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_primer.dart';
import 'package:autonomy_flutter/screen/detail/royalty/royalty_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_custom_note/exhibition_custom_note_page.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_page.dart';
import 'package:autonomy_flutter/screen/github_doc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/screen/home/collection_home_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_navigation_page.dart';
import 'package:autonomy_flutter/screen/home/list_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/home/organize_home_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/claim_empty_postcard/claim_empty_postcard_screen.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/claim_empty_postcard/pay_to_mint_postcard_screen.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/hand_signature_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_get_location.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_select_account_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/prompt_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_bloc.dart';
import 'package:autonomy_flutter/screen/irl_screen/sign_message_screen.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/import_seeds.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/name_address_persona.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/select_addresses.dart';
import 'package:autonomy_flutter/screen/onboarding/new_address/address_alias.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/name_view_only_page.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address_bloc.dart';
import 'package:autonomy_flutter/screen/onboarding_page.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist.dart';
import 'package:autonomy_flutter/screen/playlists/add_to_playlist/add_to_playlist.dart';
import 'package:autonomy_flutter/screen/playlists/edit_playlist/edit_playlist.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/screen/predefined_collection/predefined_collection_screen.dart';
import 'package:autonomy_flutter/screen/release_notes_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
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
import 'package:autonomy_flutter/screen/settings/hidden_artworks/hidden_artworks_bloc.dart';
import 'package:autonomy_flutter/screen/settings/hidden_artworks/hidden_artworks_page.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_page.dart';
import 'package:autonomy_flutter/screen/settings/settings_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/subscription_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/screen/wallet/wallet_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/view/transparent_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:page_transition/page_transition.dart';

GlobalKey<HomeNavigationPageState> homePageKey = GlobalKey();
GlobalKey<HomeNavigationPageState> homePageNoTransactionKey = GlobalKey();
GlobalKey<FeralfileHomePageState> feralFileHomeKey = GlobalKey();
final GlobalKey<DailyWorkPageState> dailyWorkKey = GlobalKey();

class AppRouter {
  static const createPlayListPage = 'create_playlist_page';
  static const viewPlayListPage = 'view_playlist_page';
  static const editPlayListPage = 'edit_playlist_page';
  static const previewPrimerPage = 'preview_primer_page';
  static const onboardingPage = 'onboarding_page';
  static const newOnboardingPage = 'new_onboarding_page';
  static const nameLinkedAccountPage = 'name_linked_account_page';
  static const homePage = 'home_page';
  static const homePageNoTransition = 'home_page_no_transition';
  static const artworkPreviewPage = 'artwork_preview_page';
  static const artworkDetailsPage = 'artwork_details_page';
  static const claimedPostcardDetailsPage = 'claimed_postcard_details_page';
  static const galleryPage = 'gallery_page';
  static const settingsPage = 'settings_page';
  static const personaConnectionsPage = 'persona_connections_page';
  static const connectionDetailsPage = 'connection_details_page';
  static const walletDetailsPage = 'wallet_details_page';
  static const linkedWalletDetailsPage = 'linked_wallet_details_page';
  static const scanQRPage = 'scan_qr_page';
  static const globalReceivePage = 'global_receive_page';
  static const recoveryPhrasePage = 'recovery_phrase_page';
  static const tbConnectPage = 'tb_connect_page';
  static const cloudPage = 'cloud_page';
  static const cloudAndroidPage = 'cloud_android_page';
  static const testArtwork = 'test_artwork';
  static const autonomySecurityPage = 'security_page';
  static const releaseNotesPage = 'release_notes_page';
  static const hiddenArtworksPage = 'hidden_artworks_page';
  static const supportCustomerPage = 'support_customer_page';
  static const supportListPage = 'support_list_page';
  static const merchOrdersPage = 'merch_orders_page';
  static const supportThreadPage = 'support_thread_page';
  static const bugBountyPage = 'bug_bounty_page';
  static const githubDocPage = 'github_doc_page';
  static const sendArtworkPage = 'send_artwork_page';
  static const sendArtworkReviewPage = 'send_artwork_review_page';
  static const wc2ConnectPage = 'wc2_connect_page';
  static const preferencesPage = 'preferences_page';
  static const walletPage = 'wallet_page';
  static const subscriptionPage = 'subscription_page';
  static const dataManagementPage = 'data_management_page';
  static const postcardExplain = 'postcard_explain_screen';
  static const designStamp = 'design_stamp_screen';
  static const promptPage = 'prompt_page';
  static const handSignaturePage = 'hand_signature_page';
  static const stampPreview = 'stamp_preview';
  static const claimEmptyPostCard = 'claim_empty_postcard';
  static const payToMintPostcard = 'pay_to_mint_postcard';
  static const postcardSelectAddressScreen = 'postcard_select_address_screen';
  static const receivePostcardPage = 'receive_postcard_page';
  static const irlWebView = 'irl_web_view';
  static const irlSignMessage = 'irl_sign_message';
  static const keyboardControlPage = 'keyboard_control_page';
  static const touchPadPage = 'touch_pad_page';
  static const postcardLeaderboardPage = 'postcard_leaderboard_page';
  static const postcardLocationExplain = 'postcard_location_explain';
  static const predefinedCollectionPage = 'predefined_collection_page';
  static const addToCollectionPage = 'add_to_collection_page';
  static const exhibitionDetailPage = 'exhibition_detail_page';
  static const ffArtworkPreviewPage = 'ff_artwork_preview_page';
  static const feralFileSeriesPage = 'feral_file_series_page';
  static const tbSendTransactionPage = 'tb_send_transaction_page';
  static const viewExistingAddressPage = 'view_existing_address_page';
  static const sendCryptoPage = 'send_crypto_page';
  static const sendReviewPage = 'send_review_page';
  static const importSeedsPage = 'import_seeds_page';
  static const selectAddressesPage = 'select_addresses_page';
  static const nameAddressPersonaPage = 'name_address_persona_page';
  static const addressAliasPage = 'address_alias_page';
  static const tbSignMessagePage = 'tb_sign_message_page';
  static const globalReceiveDetailPage = 'global_receive_detail_page';
  static const chatThreadPage = 'chat_thread_page';
  static const accessMethodPage = 'access_method_page';
  static const wcSignMessagePage = 'wc_sign_message_page';
  static const wcSendTransactionPage = 'wc_send_transaction_page';
  static const collectionPage = 'collection_page';
  static const organizePage = 'organize_page';
  static const exhibitionsPage = 'exhibitions_page';
  static const explorePage = 'explore_page';
  static const addEthereumChainPage = 'add_ethereum_chain_page';
  static const artistsListPage = 'artists_list_page';
  static const exhibitionCustomNote = 'exhibition_custom_note';
  static const dailyWorkPage = 'daily_work_page';
  static const alumniDetailsPage = 'alumni_details_page';
  static const alumniWorksPage = 'alumni_works_page';
  static const alumniExhibitionsPage = 'alumni_exhibitions_page';
  static const alumniPostPage = 'alumni_posts_page';
  static const featuredPage = 'featured_page';
  static const artworksPage = 'artworks_page';
  static const artistsPage = 'artists_page';
  static const curatorsPage = 'curators_page';
  static const rAndDPage = 'r_and_d_page';
  static const playlistActivationPage = 'playlist_activation_page';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final ethereumBloc = EthereumBloc(injector(), injector());
    final tezosBloc = TezosBloc(injector(), injector());
    final usdcBloc = USDCBloc(injector());
    final accountsBloc = AccountsBloc(injector(), injector());

    final connectionsBloc = injector<ConnectionsBloc>();
    final identityBloc = IdentityBloc(injector<AppDatabase>(), injector());
    final canvasDeviceBloc = injector<CanvasDeviceBloc>();

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

    final subscriptionBloc = injector<SubscriptionBloc>();
    final listPlaylistBloc = injector<ListPlaylistBloc>();

    final royaltyBloc = RoyaltyBloc(injector());

    switch (settings.name) {
      case artistsListPage:
        return PageTransition(
          type: PageTransitionType.fade,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 250),
          settings: settings,
          child: ArtistsListPage(
              payload: settings.arguments! as ArtistsListPagePayload),
        );

      case viewPlayListPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: canvasDeviceBloc),
              BlocProvider.value(value: subscriptionBloc),
            ],
            child: ViewPlaylistScreen(
              payload: settings.arguments! as ViewPlaylistScreenPayload,
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
          builder: (context) => const OnboardingPage(),
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
        final payload = settings.arguments as HomeNavigationPagePayload?;
        return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation1, animation2) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                        create: (_) => HomeBloc(
                              injector(),
                            )),
                    BlocProvider(create: (_) => identityBloc),
                    BlocProvider.value(value: royaltyBloc),
                    BlocProvider.value(
                      value: subscriptionBloc,
                    ),
                    BlocProvider(lazy: false, create: (_) => connectionsBloc),
                    BlocProvider(create: (_) => canvasDeviceBloc),
                    BlocProvider.value(value: listPlaylistBloc),
                  ],
                  child: HomeNavigationPage(
                      key: homePageNoTransactionKey,
                      payload: HomeNavigationPagePayload(
                          fromOnboarding: true,
                          startedTab: payload?.startedTab)),
                ),
            transitionDuration: const Duration());

      case homePage:
        final payload = settings.arguments as HomeNavigationPagePayload?;
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                        create: (_) => HomeBloc(
                              injector(),
                            )),
                    BlocProvider(create: (_) => identityBloc),
                    BlocProvider.value(value: royaltyBloc),
                    BlocProvider.value(
                      value: subscriptionBloc,
                    ),
                    BlocProvider(create: (_) => canvasDeviceBloc),
                    BlocProvider.value(value: listPlaylistBloc),

                    /// The page itself doesn't need to use the bloc.
                    /// This will create bloc instance to receive and handle
                    /// event disconnect from dApp
                    BlocProvider(lazy: false, create: (_) => connectionsBloc),
                  ],
                  child: HomeNavigationPage(
                    key: homePageKey,
                    payload: HomeNavigationPagePayload(
                        startedTab: payload?.startedTab),
                  ),
                ));

      case chatThreadPage:
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

      case accessMethodPage:
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

      case AppRouter.testArtwork:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => const TestArtworkScreen(),
        );

      case AppRouter.nameLinkedAccountPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => NameViewOnlyAddressPage(
                connection: settings.arguments! as Connection));

      case tbConnectPage:
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

      case wcSignMessagePage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => WCSignMessagePage(
              args: settings.arguments! as WCSignMessagePageArgs),
        );

      case wcSendTransactionPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
            create: (_) => WCSendTransactionBloc(
              injector(),
              injector(),
              injector(),
            ),
            child: WCSendTransactionPage(
                args: settings.arguments! as WCSendTransactionPageArgs),
          ),
        );

      case scanQRPage:
        final payload = settings.arguments! as ScanQRPagePayload;
        return PageTransition(
            settings: settings,
            type: PageTransitionType.topToBottom,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            child: ScanQRPage(
              payload: payload,
            ));

      case settingsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider.value(value: ethereumBloc),
                  BlocProvider.value(value: tezosBloc),
                  BlocProvider.value(value: subscriptionBloc),
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
                        value: connectionsBloc,
                      ),
                    ],
                    child: PersonaConnectionsPage(
                        payload:
                            settings.arguments! as PersonaConnectionsPayload)));

      case connectionDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider.value(
                value: connectionsBloc,
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
                    BlocProvider.value(value: connectionsBloc),
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
      case sendCryptoPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => SendCryptoBloc(
                      injector(),
                      injector(),
                      injector(),
                      (settings.arguments! as SendData).type,
                      injector(),
                      injector()),
                  child: SendCryptoPage(data: settings.arguments! as SendData),
                ));
      case sendReviewPage:
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
                  create: (_) => canvasDeviceBloc,
                ),
                BlocProvider(create: (_) => postcardDetailBloc),
              ],
              child: ArtworkPreviewPage(
                payload: settings.arguments! as ArtworkDetailPayload,
              ),
            ));

      case viewExistingAddressPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) =>
                      ViewExistingAddressBloc(injector(), injector()),
                  child: ViewExistingAddress(
                    payload: settings.arguments! as ViewExistingAddressPayload,
                  ),
                ));
      case importSeedsPage:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const ImportSeedsPage());

      case selectAddressesPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => ScanWalletBloc(injector(), injector()),
                  child: SelectAddressesPage(
                      payload: settings.arguments! as SelectAddressesPayload),
                ));

      case nameAddressPersonaPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => NameAddressPersona(
                  payload: settings.arguments! as NameAddressPersonaPayload,
                ));

      case addressAliasPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => AddressAlias(
                payload: settings.arguments! as AddressAliasPayload));

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
                  BlocProvider(create: (_) => royaltyBloc),
                  BlocProvider(
                      create: (_) => ArtworkDetailBloc(
                            injector(),
                            injector(),
                            injector(),
                            injector(),
                            injector(),
                            injector(),
                          )),
                  BlocProvider(
                    create: (_) => canvasDeviceBloc,
                  ),
                  BlocProvider.value(
                    value: subscriptionBloc,
                  ),
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
                  BlocProvider(create: (_) => royaltyBloc),
                  BlocProvider(create: (_) => TravelInfoBloc()),
                  BlocProvider(create: (_) => postcardDetailBloc),
                ],
                child: ClaimedPostcardDetailPage(
                    key: payload.key, payload: payload)));
      case tbSignMessagePage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              TBSignMessagePage(request: settings.arguments! as BeaconRequest),
        );
      case tbSendTransactionPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => TBSendTransactionPage(
              request: settings.arguments! as BeaconRequest),
        );

      case recoveryPhrasePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => RecoveryPhrasePage(
                  payload: settings.arguments! as RecoveryPhrasePayload,
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

      case globalReceiveDetailPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => GlobalReceiveDetailPage(
                  payload: settings.arguments! as GlobalReceivePayload,
                ));

      case autonomySecurityPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const AutonomySecurityPage());

      case releaseNotesPage:
        return PageTransition(
            settings: settings,
            type: PageTransitionType.bottomToTop,
            curve: Curves.easeIn,
            child: ReleaseNotesPage(
              releaseNotes: settings.arguments! as String,
            ));

      case supportCustomerPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const SupportCustomerPage());

      case supportListPage:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const SupportListPage());

      case merchOrdersPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const MerchandiseOrderPage());

      case supportThreadPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => SupportThreadPage(
                payload: settings.arguments! as SupportThreadPayload));

      case bugBountyPage:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const BugBountyPage());

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

      case exhibitionDetailPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => ExhibitionDetailBloc(injector()),
                    ),
                    BlocProvider(
                      create: (_) => canvasDeviceBloc,
                    ),
                    BlocProvider.value(
                      value: subscriptionBloc,
                    ),
                    BlocProvider(create: (_) => FFArtworkPreviewBloc())
                  ],
                  child: ExhibitionDetailPage(
                    payload: settings.arguments! as ExhibitionDetailPayload,
                  ),
                ));
      case ffArtworkPreviewPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => royaltyBloc,
                    ),
                    BlocProvider.value(
                      value: subscriptionBloc,
                    ),
                    BlocProvider(create: (_) => FFArtworkPreviewBloc()),
                  ],
                  child: FeralFileArtworkPreviewPage(
                      payload: settings.arguments!
                          as FeralFileArtworkPreviewPagePayload),
                ));

      case feralFileSeriesPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => FeralFileSeriesBloc(injector()),
                    ),
                  ],
                  child: FeralFileSeriesPage(
                    payload: settings.arguments! as FeralFileSeriesPagePayload,
                  ),
                ));

      case githubDocPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => GithubDocPage(
                payload: settings.arguments! as GithubDocPayload));

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
                        (settings.arguments! as SendArtworkPayload).asset,
                        injector())),
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

      case wc2ConnectPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountsBloc),
            ],
            child: WCConnectPage(
              connectionRequest: settings.arguments! as Wc2Proposal,
            ),
          ),
        );

      case walletPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: accountsBloc),
                  ],
                  child: WalletPage(
                    payload: settings.arguments as WalletPagePayload?,
                  ),
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
                    create: (_) => UpgradesBloc(
                      injector(),
                      injector(),
                    ),
                  ),
                ], child: const SubscriptionPage()));

      case dataManagementPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider(create: (_) => identityBloc),
                ], child: const DataManagementPage()));
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

      case postcardSelectAddressScreen:
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
            child: PostcardSelectAddressScreen(
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

      case predefinedCollectionPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              final payload =
                  settings.arguments! as PredefinedCollectionScreenPayload;
              return PredefinedCollectionScreen(
                payload: payload,
              );
            });
      case addToCollectionPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => AddToCollectionScreen(
            playList: settings.arguments! as PlayListModel,
          ),
        );

      case exhibitionCustomNote:
        return MaterialPageRoute(
          builder: (context) => ExhibitionCustomNotePage(
            info: settings.arguments! as CustomExhibitionNote,
          ),
        );

      case dailyWorkPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(providers: [
            BlocProvider(
              create: (_) => injector<DailyWorkBloc>(),
            ),
            BlocProvider.value(value: canvasDeviceBloc),
          ], child: const DailyWorkPage()),
        );

      case alumniDetailsPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => AlumniDetailsBloc()),
              ],
              child: AlumniDetailsPage(
                payload: settings.arguments! as AlumniDetailsPagePayload,
              )),
        );
      case alumniWorksPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => AlumniWorksPage(
            payload: settings.arguments! as AlumniWorksPagePayload,
          ),
        );

      case alumniExhibitionsPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => AlumniExhibitionsPage(
            payload: settings.arguments! as AlumniExhibitionsPagePayload,
          ),
        );

      case alumniPostPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => AlumniPostsPage(
            payload: settings.arguments! as AlumniPostsPagePayload,
          ),
        );
      case collectionPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: subscriptionBloc),
            ],
            child: const CollectionHomePage(),
          ),
        );
      case organizePage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: subscriptionBloc),
              BlocProvider.value(value: listPlaylistBloc),
            ],
            child: const OrganizeHomePage(),
          ),
        );

      case playlistActivationPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => PlaylistActivationPage(
            payload: settings.arguments! as PlaylistActivationPagePayload,
          ),
        );

      default:
        throw Exception('Invalid route: ${settings.name}');
    }
  }
}
