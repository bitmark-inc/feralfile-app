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
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/editorial.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/account/access_method_page.dart';
import 'package:autonomy_flutter/screen/account/accounts_preview_page.dart';
import 'package:autonomy_flutter/screen/account/add_account_page.dart';
import 'package:autonomy_flutter/screen/account/import_account_page.dart';
import 'package:autonomy_flutter/screen/account/link_account_page.dart';
import 'package:autonomy_flutter/screen/account/link_app_options_page.dart';
import 'package:autonomy_flutter/screen/account/link_ledger_page.dart';
import 'package:autonomy_flutter/screen/account/link_manually_page.dart';
import 'package:autonomy_flutter/screen/account/link_metamask_page.dart';
import 'package:autonomy_flutter/screen/account/link_tezos_kukai_page.dart';
import 'package:autonomy_flutter/screen/account/link_tezos_temple_page.dart';
import 'package:autonomy_flutter/screen/account/link_wallet_connect_page.dart';
import 'package:autonomy_flutter/screen/account/linked_account_details_page.dart';
import 'package:autonomy_flutter/screen/account/name_linked_account_page.dart';
import 'package:autonomy_flutter/screen/account/name_persona_page.dart';
import 'package:autonomy_flutter/screen/account/new_account_page.dart';
import 'package:autonomy_flutter/screen/account/persona_details_page.dart';
import 'package:autonomy_flutter/screen/account/recovery_phrase_page.dart';
import 'package:autonomy_flutter/screen/account/select_account_page.dart';
import 'package:autonomy_flutter/screen/account/select_ledger_page.dart';
import 'package:autonomy_flutter/screen/account/test_artwork_screen.dart';
import 'package:autonomy_flutter/screen/autonomy_security_page.dart';
import 'package:autonomy_flutter/screen/be_own_gallery_page.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tzkt_transaction/tzkt_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/bug_bounty_page.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
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
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_primer.dart';
import 'package:autonomy_flutter/screen/detail/royalty/royalty_bloc.dart';
import 'package:autonomy_flutter/screen/editorial/article/article_detail.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_bloc.dart';
import 'package:autonomy_flutter/screen/editorial/feralfile/exhibition_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_artwork_details_page.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_preview_page.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_bloc.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/screen/github_doc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_navigation_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/claim_empty_postcard/claim_empty_postcard_screen.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/hand_signature_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_started_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_bloc.dart';
import 'package:autonomy_flutter/screen/irl_screen/get_address_screen.dart';
import 'package:autonomy_flutter/screen/irl_screen/sign_message_screen.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_bloc.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_page.dart';
import 'package:autonomy_flutter/screen/more_autonomy_page.dart';
import 'package:autonomy_flutter/screen/notification_onboarding_page.dart';
import 'package:autonomy_flutter/screen/onboarding_page.dart';
import 'package:autonomy_flutter/screen/participate_user_test_page.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist.dart';
import 'package:autonomy_flutter/screen/playlists/edit_playlist/edit_playlist.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/screen/release_notes_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_select_account_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/linked_wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/tezos_transaction_detail_page.dart';
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
import 'package:autonomy_flutter/screen/survey/survey.dart';
import 'package:autonomy_flutter/screen/survey/survey_thankyou.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/au_sign_message_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/screen/unsafe_web_wallet_page.dart';
import 'package:autonomy_flutter/screen/wallet/wallet_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/tv_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/v2/wc2_permission_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_disconnect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:page_transition/page_transition.dart';
import 'package:wallet_connect/wallet_connect.dart';

import 'account/link_beacon_connect_page.dart';
import 'interactive_postcard/postcard_detail_page.dart';

class AppRouter {
  static const createPlayListPage = "createPlayList";
  static const viewPlayListPage = "viewPlayList";
  static const editPlayListPage = "editPlayList";
  static const previewPrimerPage = "preview_primer";
  static const onboardingPage = "onboarding";
  static const beOwnGalleryPage = 'be_own_gallery';
  static const moreAutonomyPage = 'more_autonomy';
  static const notificationOnboardingPage = 'notification_onboarding';
  static const newAccountPage = "new_account";
  static const addAccountPage = 'add_account';
  static const linkAccountpage = "link_account";
  static const linkLedgerWalletPage = "link_ledger_wallet";
  static const selectLedgerWalletPage = "select_ledger_waller";
  static const linkWalletConnectPage = "link_wallet_connect";
  static const linkBeaconConnectPage = "link_beacon_connect";
  static const accountsPreviewPage = 'accounts_preview';
  static const accessMethodPage = 'access_method_page';
  static const linkAppOptionPage = 'link_app_option_page';
  static const linkMetamaskPage = 'link_metamask';
  static const linkTezosKukaiPage = 'link_tezos_kukai_page';
  static const linkTezosTemplePage = 'link_tezos_temple_page';
  static const namePersonaPage = "name_persona_page";
  static const nameLinkedAccountPage = 'name_linked_account';
  static const importAccountPage = 'import_account';
  static const homePage = "home_page";
  static const homePageNoTransition = 'home_page_NoTransition';
  static const artworkPreviewPage = 'artwork_preview';
  static const artworkDetailsPage = 'artwork_detail';
  static const claimedPostcardDetailsPage = 'claimed_postcard_detail';
  static const feedPreviewPage = 'feedPreviewPage';
  static const feedArtworkDetailsPage = 'feedArtworkDetailsPage';
  static const galleryPage = 'galleryPage';
  static const settingsPage = "settings";
  static const personaDetailsPage = "persona_details";
  static const personaConnectionsPage = "persona_connections";
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
  static const tvConnectPage = 'tv_connect';
  static const tezosTXDetailPage = "tezos_tx_detail";
  static const githubDocPage = 'github_doc_page';
  static const sendArtworkPage = 'send_artwork_page';
  static const sendArtworkReviewPage = 'send_artwork_review_page';
  static const claimFeralfileTokenPage = 'claim_feralfile_token_page';
  static const claimSelectAccountPage = 'claim_select_account_page';
  static const airdropTokenDetailPage = 'airdrop_token_detail_page';
  static const wc2ConnectPage = 'wc2_connect_page';
  static const wc2PermissionPage = 'wc2_permission_page';
  static const articleDetailPage = 'article_detail_page';
  static const preferencesPage = 'preferences_page';
  static const walletPage = 'wallet_page';
  static const subscriptionPage = 'subscription_page';
  static const dataManagementPage = 'data_management_page';
  static const helpUsPage = 'help_us_page';
  static const inappWebviewPage = 'inapp_webview_page';
  static const postcardExplain = 'postcard_explain_screen';
  static const designStamp = 'design_stamp_screen';
  static const handSignaturePage = "hand_signature_page";
  static const stampPreview = "stamp_preview";
  static const claimEmptyPostCard = "claim_empty_postcard";
  static const selectAddressScreen = "select_address_screen";
  static const receivePostcardPage = 'receive_postcard_page';
  static const postcardDetailPage = 'postcard_detail_page';
  static const receivePostcardSelectAccountPage =
      'receive_postcard_select_account_page';
  static const irlWebview = 'irl_web_claim';
  static const irlGetAddress = 'irl_get_address';
  static const irlSignMessage = 'irl_sign_message';
  static const postcardStartedPage = 'postcard_started';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final ethereumBloc = EthereumBloc(injector(), injector());
    final tezosBloc = TezosBloc(injector(), injector());
    final usdcBloc = USDCBloc(injector());
    final accountsBloc = AccountsBloc(injector(), injector<CloudDatabase>(),
        injector(), injector<AuditService>(), injector());

    switch (settings.name) {
      case viewPlayListPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => ViewPlaylistScreen(
            playListModel: settings.arguments as PlayListModel?,
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
              ),
            ),
            BlocProvider(
              create: (_) => PersonaBloc(
                injector<CloudDatabase>(),
                injector(),
                injector(),
                injector<AuditService>(),
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
                BlocProvider(
                    create: (_) =>
                        IdentityBloc(injector<AppDatabase>(), injector())),
              ],
              child: PreviewPrimerPage(
                token: settings.arguments as AssetToken,
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
                              injector(),
                            )),
                    BlocProvider(
                        create: (_) => IdentityBloc(injector(), injector())),
                    BlocProvider(
                        create: (_) => UpgradesBloc(
                              injector(),
                              injector(),
                            )),
                    BlocProvider(create: (_) => EditorialBloc(injector())),
                    BlocProvider(
                      create: (_) => FeedBloc(
                        injector(),
                        injector(),
                        injector(),
                      ),
                    ),
                    BlocProvider(create: (_) => ExhibitionBloc(injector())),
                    BlocProvider(
                      create: (_) => PersonaBloc(
                        injector<CloudDatabase>(),
                        injector(),
                        injector(),
                        injector<AuditService>(),
                      ),
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
                              injector(),
                            )),
                    BlocProvider(
                        create: (_) => IdentityBloc(injector(), injector())),
                    BlocProvider(
                        create: (_) => UpgradesBloc(
                              injector(),
                              injector(),
                            )),
                    BlocProvider(create: (_) => EditorialBloc(injector())),
                    BlocProvider(
                      create: (_) => FeedBloc(
                        injector(),
                        injector(),
                        injector(),
                      ),
                    ),
                    BlocProvider(create: (_) => ExhibitionBloc(injector())),
                    BlocProvider(
                      create: (_) => PersonaBloc(
                        injector<CloudDatabase>(),
                        injector(),
                        injector(),
                        injector<AuditService>(),
                      ),
                    ),
                  ],
                  child: const HomeNavigationPage(),
                ));
      case beOwnGalleryPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => const BeOwnGalleryPage(),
        );

      case ChatThreadPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => ChatThreadPage(
              payload: settings.arguments as ChatThreadPagePayload),
        );

      case postcardExplain:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => PostcardExplain(
              payload: settings.arguments as PostcardExplainPayload),
        );

      case designStamp:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => DesignStampPage(
              payload: settings.arguments as DesignStampPayload),
        );

      case handSignaturePage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => HandSignaturePage(
            payload: settings.arguments as HandSignaturePayload,
          ),
        );

      case AppRouter.stampPreview:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              StampPreview(payload: settings.arguments as StampPreviewPayload),
        );

      case moreAutonomyPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
            create: (_) => UpgradesBloc(injector(), injector()),
            child: const MoreAutonomyPage(),
          ),
        );
      case notificationOnboardingPage:
        return CupertinoPageRoute(
          settings: settings,
          fullscreenDialog: true,
          builder: (context) => const NotificationOnboardingPage(),
        );
      case newAccountPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => PersonaBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                      injector<AuditService>(),
                    ),
                child: NewAccountPage()));

      case addAccountPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => PersonaBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                      injector<AuditService>(),
                    ),
                child: const AddAccountPage()));

      case AppRouter.linkAccountpage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(create: (_) => FeralfileBloc.create()),
                ], child: const LinkAccountPage()));

      case accountsPreviewPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(
                    create: (_) => PersonaBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                      injector<AuditService>(),
                    ),
                  ),
                ], child: const AccountsPreviewPage()));

      case accessMethodPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider(
                    create: (_) => FeralfileBloc.create(),
                  ),
                  BlocProvider(
                    create: (_) => PersonaBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                      injector<AuditService>(),
                    ),
                  ),
                ], child: const AccessMethodPage()));

      case linkAppOptionPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => FeralfileBloc.create(),
                child: LinkAppOptionsPage(
                  walletApp: settings.arguments as WalletApp,
                )));

      case linkMetamaskPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => FeralfileBloc.create(),
                child: const LinkMetamaskPage()));

      case linkTezosKukaiPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const LinkTezosKukaiPage());

      case linkTezosTemplePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const LinkTezosTemplePage());

      case linkBeaconConnectPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) =>
                LinkBeaconConnectPage(uri: settings.arguments as String));

      case linkLedgerWalletPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider.value(
                value: accountsBloc,
                child: LinkLedgerPage(payload: settings.arguments as String)));

      case selectLedgerWalletPage:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const SelectLedgerPage());

      case linkWalletConnectPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider.value(
                value: accountsBloc,
                child: LinkWalletConnectPage(
                  unableOpenAppname: (settings.arguments as String?) ?? "",
                )));

      case AppRouter.namePersonaPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => PersonaBloc(
                    injector<CloudDatabase>(),
                    injector(),
                    injector(),
                    injector<AuditService>(),
                  ),
                  child: NamePersonaPage(
                      payload: settings.arguments as NamePersonaPayload),
                ));
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
                child: NameLinkedAccountPage(
                    connection: settings.arguments as Connection)));

      case importAccountPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
            create: (_) => ScanWalletBloc(
              injector(),
              injector(),
            ),
            child: const ImportAccountPage(),
          ),
        );

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

      case WCDisconnectPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              WCDisconnectPage(client: settings.arguments as WCClient),
        );
      case WCSignMessagePage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
              create: (_) => FeralfileBloc.create(),
              child: WCSignMessagePage(
                  args: settings.arguments as WCSignMessagePageArgs)),
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
              injector(),
            ),
            child: WCSendTransactionPage(
                args: settings.arguments as WCSendTransactionPageArgs),
          ),
        );
      case ScanQRPage.tag:
        return PageTransition(
            settings: settings,
            type: PageTransitionType.topToBottom,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            child: BlocProvider(
                create: (_) => FeralfileBloc.create(),
                child: ScanQRPage(
                    scannerItem: settings.arguments as ScannerItem)));
      case settingsPage:
        return CupertinoPageRoute(
            settings: settings,
            fullscreenDialog: true,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(
                      create: (_) => PersonaBloc(
                            injector<CloudDatabase>(),
                            injector(),
                            injector(),
                            injector<AuditService>(),
                          )),
                  BlocProvider.value(value: ethereumBloc),
                  BlocProvider.value(value: tezosBloc),
                  BlocProvider(
                      create: (_) => IdentityBloc(injector(), injector())),
                ], child: const SettingsPage()));

      case personaDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: ethereumBloc),
                      BlocProvider.value(value: tezosBloc),
                      BlocProvider.value(value: usdcBloc),
                      BlocProvider(
                        create: (_) => ScanWalletBloc(
                          injector(),
                          injector(),
                        ),
                      ),
                    ],
                    child: PersonaDetailsPage(
                      persona: settings.arguments as Persona,
                    )));

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
                            settings.arguments as PersonaConnectionsPayload)));

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
                  connectionItem: settings.arguments as ConnectionItem,
                )));

      case linkedAccountDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(create: (_) => FeralfileBloc.create()),
                    ],
                    child: LinkedAccountDetailsPage(
                        connection: settings.arguments as Connection)));

      case walletDetailsPage:
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
                    )),
                    BlocProvider(
                        create: (_) => WalletDetailBloc(
                            injector(), injector(), injector())),
                    BlocProvider(create: (_) => TZKTTransactionBloc()),
                  ],
                  child: WalletDetailPage(
                      payload: settings.arguments as WalletDetailsPayload),
                ));
      case linkedWalletDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: accountsBloc),
                    BlocProvider.value(value: ethereumBloc),
                    BlocProvider.value(value: tezosBloc),
                    BlocProvider.value(value: usdcBloc),
                    BlocProvider(
                        create: (_) => WalletDetailBloc(
                            injector(), injector(), injector())),
                    BlocProvider(create: (_) => TZKTTransactionBloc()),
                  ],
                  child: LinkedWalletDetailPage(
                      payload:
                          settings.arguments as LinkedWalletDetailsPayload),
                ));
      case SendCryptoPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => SendCryptoBloc(injector(), injector(),
                      injector(), (settings.arguments as SendData).type),
                  child: SendCryptoPage(data: settings.arguments as SendData),
                ));
      case SendReviewPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => SendReviewPage(
                  payload: settings.arguments as SendCryptoPayload,
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
                  create: (_) => IdentityBloc(
                    injector<AppDatabase>(),
                    injector(),
                  ),
                ),
              ],
              child: ArtworkPreviewPage(
                payload: settings.arguments as ArtworkDetailPayload,
              ),
            ));

      case feedPreviewPage:
        return PageTransition(
            type: PageTransitionType.fade,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            settings: settings,
            child: FeedPreviewPage());

      case feedArtworkDetailsPage:
        return PageTransition(
            type: PageTransitionType.fade,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            settings: settings,
            child: MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(create: (_) => RoyaltyBloc(injector())),
                  BlocProvider(
                      create: (_) =>
                          IdentityBloc(injector<AppDatabase>(), injector())),
                ],
                child: FeedArtworkDetailsPage(
                  payload: settings.arguments as FeedDetailPayload,
                )));

      case galleryPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                          create: (_) => GalleryBloc(injector(), injector())),
                      BlocProvider(
                          create: (_) => IdentityBloc(injector(), injector())),
                    ],
                    child: GalleryPage(
                      payload: settings.arguments as GalleryPagePayload,
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
                  BlocProvider(
                      create: (_) => IdentityBloc(injector(), injector())),
                  BlocProvider(create: (_) => RoyaltyBloc(injector())),
                  BlocProvider(
                      create: (_) => ArtworkDetailBloc(
                            injector(),
                            injector(),
                            injector(),
                            injector(),
                            injector(),
                          )),
                ],
                child: ArtworkDetailPage(
                    payload: settings.arguments as ArtworkDetailPayload)));

      case claimedPostcardDetailsPage:
        return PageTransition(
            type: PageTransitionType.fade,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            settings: settings,
            child: MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(
                      create: (_) => IdentityBloc(injector(), injector())),
                  BlocProvider(create: (_) => RoyaltyBloc(injector())),
                  BlocProvider(create: (_) => TravelInfoBloc()),
                  BlocProvider(
                      create: (_) => PostcardDetailBloc(
                            injector(),
                            injector(),
                            injector(),
                            injector(),
                          )),
                ],
                child: ClaimedPostcardDetailPage(
                    payload: settings.arguments as ArtworkDetailPayload)));
      case TBSignMessagePage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              TBSignMessagePage(request: settings.arguments as BeaconRequest),
        );
      case AUSignMessagePage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              AUSignMessagePage(request: settings.arguments as Wc2Request),
        );
      case TBSendTransactionPage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => TBSendTransactionPage(
              request: settings.arguments as BeaconRequest),
        );

      case recoveryPhrasePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => RecoveryPhrasePage(
                  words: settings.arguments as List<String>,
                ));

      case cloudPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => CloudPage(
                  section: settings.arguments as String,
                ));

      case cloudAndroidPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => CloudAndroidPage(
                  isEncryptionAvailable: settings.arguments as bool?,
                ));

      case globalReceivePage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(
                    create: (_) => PersonaBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                      injector<AuditService>(),
                    ),
                  ),
                  BlocProvider.value(value: ethereumBloc),
                  BlocProvider.value(value: tezosBloc),
                ], child: const GlobalReceivePage()));

      case GlobalReceiveDetailPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => GlobalReceiveDetailPage(
                  payload: settings.arguments as GlobalReceivePayload,
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
              releaseNotes: settings.arguments as String,
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

      case supportThreadPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => SupportThreadPage(
                payload: settings.arguments as SupportThreadPayload));

      case bugBountyPage:
        return CupertinoPageRoute(
            settings: settings, builder: (context) => const BugBountyPage());

      case participateUserTestPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const ParticipateUserTestPage());

      case linkManually:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => LinkManuallyPage(
                  type: settings.arguments as String,
                ));

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

      case SurveyPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            fullscreenDialog: true,
            builder: (context) => const SurveyPage());
      case SurveyThankyouPage.tag:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => const SurveyThankyouPage());

      case githubDocPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => GithubDocPage(
                payload: settings.arguments as Map<String, String>));

      case keySyncPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => KeySyncBloc(injector(), injector()),
                  child: const KeySyncPage(),
                ));

      case tvConnectPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: accountsBloc),
                      BlocProvider(
                        create: (_) => PersonaBloc(
                          injector<CloudDatabase>(),
                          injector(),
                          injector(),
                          injector<AuditService>(),
                        ),
                      ),
                    ],
                    child: TVConnectPage(
                        wcConnectArgs:
                            settings.arguments as WCConnectPageArgs)));

      case tezosTXDetailPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => TezosTXDetailPage.fromPayload(
                payload: settings.arguments as Map<String, dynamic>));

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
                        (settings.arguments as SendArtworkPayload).asset)),
                BlocProvider(
                    create: (_) =>
                        IdentityBloc(injector<AppDatabase>(), injector())),
              ],
              child: SendArtworkPage(
                  payload: settings.arguments as SendArtworkPayload)),
        );

      case sendArtworkReviewPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) =>
                      IdentityBloc(injector<AppDatabase>(), injector()),
                  child: SendArtworkReviewPage(
                      payload: settings.arguments as SendArtworkReviewPayload),
                ));

      case claimFeralfileTokenPage:
        final args = settings.arguments as ClaimTokenPageArgs;
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return ClaimTokenPage(
                artwork: args.artwork,
                otp: args.otp,
              );
            });

      case airdropTokenDetailPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                  create: (_) => RoyaltyBloc(injector()),
                  child: TokenDetailPage(
                    artwork: settings.arguments as FFArtwork,
                  ),
                ));

      case claimSelectAccountPage:
        final args = settings.arguments as SelectAccountPageArgs;
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return BlocProvider.value(
                value: accountsBloc,
                child: SelectAccountPage(
                  blockchain: args.blockchain,
                  artwork: args.artwork,
                  otp: args.otp,
                  fromWebview: args.fromWebview,
                ),
              );
            });

      case wc2ConnectPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountsBloc),
              BlocProvider(
                create: (_) => PersonaBloc(
                  injector<CloudDatabase>(),
                  injector(),
                  injector(),
                  injector<AuditService>(),
                ),
              ),
            ],
            child: WCConnectPage(
              connectionRequest: settings.arguments as Wc2Proposal,
            ),
          ),
        );

      case wc2PermissionPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: accountsBloc),
                      BlocProvider(
                        create: (_) => PersonaBloc(
                          injector<CloudDatabase>(),
                          injector(),
                          injector(),
                          injector<AuditService>(),
                        ),
                      ),
                    ],
                    child: Wc2RequestPage(
                        request: settings.arguments as Wc2Request)));
      case articleDetailPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return ArticleDetailPage(
                  post: settings.arguments as EditorialPost);
            });
      case walletPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: accountsBloc),
                  BlocProvider(
                    create: (_) => PersonaBloc(
                      injector<CloudDatabase>(),
                      injector(),
                      injector(),
                      injector<AuditService>(),
                    ),
                  ),
                ],
                child: const WalletPage(),
              );
            });
      case preferencesPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return MultiBlocProvider(providers: [
                BlocProvider(
                  create: (_) => PreferencesBloc(injector()),
                ),
                BlocProvider.value(value: accountsBloc),
              ], child: const PreferencePage());
            });
      case subscriptionPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return MultiBlocProvider(providers: [
                BlocProvider(
                  create: (_) => UpgradesBloc(injector(), injector()),
                ),
              ], child: const SubscriptionPage());
            });
      case dataManagementPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return MultiBlocProvider(providers: [
                BlocProvider(
                    create: (_) =>
                        IdentityBloc(injector<AppDatabase>(), injector())),
              ], child: const DataManagementPage());
            });
      case helpUsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return const HelpUsPage();
            });
      case inappWebviewPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return InappWebviewPage(url: settings.arguments as String);
            });
      case claimEmptyPostCard:
        final claimRequest = settings.arguments as RequestPostcardResponse;
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) {
            return ClaimEmptyPostCardScreen(claimRequest: claimRequest);
          },
        );

      case selectAddressScreen:
        final arguments = settings.arguments as Map;
        final blockchain = arguments['blockchain'] as String;
        final onConfirm = arguments['onConfirm'] as Future Function(String);
        final withLinked = (arguments['withLinked'] ?? true) as bool;
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) {
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: accountsBloc),
              ],
              child: SelectAccountScreen(
                blockchain: blockchain,
                onConfirm: onConfirm,
                withLinked: withLinked,
              ),
            );
          },
        );
      case receivePostcardPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              final args = settings.arguments as ReceivePostcardPageArgs;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                      create: (_) =>
                          IdentityBloc(injector<AppDatabase>(), injector())),
                ],
                child: ReceivePostCardPage(
                  asset: args.asset,
                  shareCode: args.shareCode,
                ),
              );
            });
      case postcardDetailPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => TravelInfoBloc()),
                    BlocProvider(
                        create: (_) => PostcardDetailBloc(
                              injector(),
                              injector(),
                              injector(),
                              injector(),
                            )),
                    BlocProvider.value(value: accountsBloc),
                    BlocProvider(
                        create: (_) =>
                            IdentityBloc(injector<AppDatabase>(), injector())),
                  ],
                  child: PostcardDetailPage(
                    asset: settings.arguments as AssetToken,
                  ));
            });
      case receivePostcardSelectAccountPage:
        return CupertinoPageRoute(builder: (context) {
          final args =
              settings.arguments as ReceivePostcardSelectAccountPageArgs;
          return BlocProvider.value(
            value: accountsBloc,
            child: ReceivePostcardSelectAccountPage(
              blockchain: args.blockchain,
              withLinked: args.withLinked,
            ),
          );
        });

      case irlWebview:
        final url = settings.arguments as Uri;
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return IRLWebScreen(url: url);
            });

      case irlGetAddress:
        final payload = settings.arguments as IRLGetAddressPayLoad?;
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) {
            return BlocProvider.value(
              value: accountsBloc,
              child: IRLGetAddressPage(payload: payload),
            );
          },
        );

      case irlSignMessage:
        final payload = settings.arguments as IRLSignMessagePayload;
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) {
              return IRLSignMessageScreen(payload: payload);
            });

      case postcardStartedPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) {
            return PostcardStartedPage(
              assetToken: settings.arguments as AssetToken,
            );
          },
        );

      default:
        throw Exception('Invalid route: ${settings.name}');
    }
  }
}
