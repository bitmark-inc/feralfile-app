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
import 'package:autonomy_flutter/model/ff_account.dart';
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
import 'package:autonomy_flutter/screen/autonomy_security_page.dart';
import 'package:autonomy_flutter/screen/be_own_gallery_page.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tzkt_transaction/tzkt_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/bug_bounty_page.dart';
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
import 'package:autonomy_flutter/screen/feed/feed_artwork_details_page.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_preview_page.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_bloc.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/screen/github_doc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_page.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_bloc.dart';
import 'package:autonomy_flutter/screen/migration/key_sync_page.dart';
import 'package:autonomy_flutter/screen/more_autonomy_page.dart';
import 'package:autonomy_flutter/screen/notification_onboarding_page.dart';
import 'package:autonomy_flutter/screen/onboarding_page.dart';
import 'package:autonomy_flutter/screen/participate_user_test_page.dart';
import 'package:autonomy_flutter/screen/release_notes_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/tezos_transaction_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/hidden_artworks/hidden_artworks_bloc.dart';
import 'package:autonomy_flutter/screen/settings/hidden_artworks/hidden_artworks_page.dart';
import 'package:autonomy_flutter/screen/settings/settings_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/survey/survey.dart';
import 'package:autonomy_flutter/screen/survey/survey_thankyou.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/screen/unsafe_web_wallet_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/tv_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_disconnect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:page_transition/page_transition.dart';
import 'package:wallet_connect/wallet_connect.dart';

import 'account/link_beacon_connect_page.dart';

class AppRouter {
  static const previewPrimerPage = "preview_primer";
  static const onboardingPage = "onboarding";
  static const beOwnGalleryPage = 'be_own_gallery';
  static const moreAutonomyPage = 'more_autonomy';
  static const notificationOnboardingPage = 'notification_onboarding';
  static const newAccountPage = "new_account";
  static const addAccountPage = 'add_account';
  static const linkAccountpage = "link_account";
  static const linkLedgerWalletPage = "link_ledger_wallet";
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
  static const feedPreviewPage = 'feedPreviewPage';
  static const feedArtworkDetailsPage = 'feedArtworkDetailsPage';
  static const galleryPage = 'galleryPage';
  static const settingsPage = "settings";
  static const personaDetailsPage = "persona_details";
  static const personaConnectionsPage = "persona_connections";
  static const connectionDetailsPage = 'connection_details';
  static const linkedAccountDetailsPage = 'linked_account_details';
  static const walletDetailsPage = 'wallet_detail';
  static const scanQRPage = 'qr_scanner';
  static const globalReceivePage = 'global_receive';
  static const recoveryPhrasePage = 'recovery_phrase';
  static const wcConnectPage = 'wc_connect';
  static const cloudPage = 'cloud_page';
  static const cloudAndroidPage = 'cloud_android_page';
  static const linkManually = 'link_manually';
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

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final ethereumBloc = EthereumBloc(injector());
    final tezosBloc = TezosBloc(injector());
    final accountsBloc = AccountsBloc(injector(), injector<CloudDatabase>(),
        injector(), injector<AuditService>(), injector());
    final nftCollectionBloc = injector<NftCollectionBloc>();

    switch (settings.name) {
      case onboardingPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => RouterBloc(
                      injector(),
                      injector(),
                      injector(),
                      injector<CloudDatabase>(),
                      injector(),
                      injector<AuditService>(),
                    ),
                child: const OnboardingPage()));

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
                    BlocProvider.value(value: nftCollectionBloc),
                    BlocProvider(
                        create: (_) => UpgradesBloc(
                              injector(),
                              injector(),
                            )),
                  ],
                  child: const HomePage(),
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
                    BlocProvider.value(value: nftCollectionBloc),
                    BlocProvider(
                        create: (_) => UpgradesBloc(
                              injector(),
                              injector(),
                            )),
                  ],
                  child: const HomePage(),
                ));
      case beOwnGalleryPage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) => const BeOwnGalleryPage(),
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
                child: const NewAccountPage()));

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
            builder: (context) => BlocProvider(
                create: (_) => FeralfileBloc.create(),
                child: AccessMethodPage(
                  walletApp: settings.arguments as String,
                )));

      case linkAppOptionPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => BlocProvider(
                create: (_) => FeralfileBloc.create(),
                child: const LinkAppOptionsPage()));

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
                  child: NamePersonaPage(uuid: settings.arguments as String),
                ));

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
            builder: (context) => const ImportAccountPage());

      case wcConnectPage:
        final argument = settings.arguments;
        switch (argument.runtimeType) {
          case WCConnectPageArgs:
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
                            wcConnectArgs: argument as WCConnectPageArgs,
                            beaconRequest: null)));

          case BeaconRequest:
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
                      wcConnectArgs: null,
                      beaconRequest: argument as BeaconRequest?)),
            );

          default:
            throw Exception('Invalid route: ${settings.name}');
        }

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
                injector(), injector(), injector(), injector()),
            child: WCSendTransactionPage(
                args: settings.arguments as WCSendTransactionPageArgs),
          ),
        );
      case ScanQRPage.tag:
        return PageTransition(
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
                ], child: const SettingsPage()));

      case personaDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: ethereumBloc),
                      BlocProvider.value(value: tezosBloc),
                      BlocProvider.value(value: nftCollectionBloc),
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
                      BlocProvider.value(
                          value: ConnectionsBloc(
                        injector<CloudDatabase>(),
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
                      BlocProvider.value(value: nftCollectionBloc),
                    ],
                    child: LinkedAccountDetailsPage(
                        connection: settings.arguments as Connection)));

      case walletDetailsPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                        create: (_) => WalletDetailBloc(
                            injector(), injector(), injector())),
                    BlocProvider(create: (_) => TZKTTransactionBloc()),
                  ],
                  child: WalletDetailPage(
                      payload: settings.arguments as WalletDetailsPayload),
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
                        nftCollectionBloc.database.assetDao, injector())),
                BlocProvider(
                    create: (_) =>
                        IdentityBloc(injector<AppDatabase>(), injector())),
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
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => FeedBloc(
                    injector(),
                    injector(),
                    nftCollectionBloc.database.assetDao,
                  ),
                ),
                BlocProvider(
                    create: (_) =>
                        IdentityBloc(injector<AppDatabase>(), injector())),
              ],
              child: const FeedPreviewPage(),
            ));

      case feedArtworkDetailsPage:
        return PageTransition(
            type: PageTransitionType.fade,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 250),
            settings: settings,
            child: MultiBlocProvider(providers: [
              BlocProvider.value(value: accountsBloc),
              BlocProvider.value(value: settings.arguments as FeedBloc),
              BlocProvider(
                  create: (_) =>
                      IdentityBloc(injector<AppDatabase>(), injector())),
            ], child: const FeedArtworkDetailsPage()));

      case galleryPage:
        return CupertinoPageRoute(
            settings: settings,
            builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                          create: (_) => GalleryBloc(
                                injector(),
                              )),
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
                  BlocProvider(
                      create: (_) => ArtworkDetailBloc(
                            injector(),
                            nftCollectionBloc.database.assetDao,
                            nftCollectionBloc.database.provenanceDao,
                          )),
                  BlocProvider.value(value: nftCollectionBloc),
                ],
                child: ArtworkDetailPage(
                    payload: settings.arguments as ArtworkDetailPayload)));
      case TBSignMessagePage.tag:
        return CupertinoPageRoute(
          settings: settings,
          builder: (context) =>
              TBSignMessagePage(request: settings.arguments as BeaconRequest),
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
                  payload: settings.arguments,
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
            type: PageTransitionType.bottomToTop,
            curve: Curves.easeIn,
            child: ReleaseNotesPage(
              releaseNotes: settings.arguments as String,
            ));

      case supportCustomerPage:
        return PageTransition(
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
            builder: (context) => BlocProvider(
                  create: (_) => HiddenArtworksBloc(
                      injector<ConfigurationService>(),
                      injector<NftCollectionBloc>().database.assetDao),
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
            builder: (context) {
              return TokenDetailPage(
                artwork: settings.arguments as FFArtwork,
              );
            });

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
                ),
              );
            });

      default:
        throw Exception('Invalid route: ${settings.name}');
    }
  }
}
