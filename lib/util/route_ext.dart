import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
import 'package:autonomy_flutter/screen/cloud/cloud_android_page.dart';
import 'package:autonomy_flutter/screen/cloud/cloud_page.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_page.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/hand_signature_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/screen/irl_screen/sign_message_screen.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/name_address_persona.dart';
import 'package:autonomy_flutter/screen/onboarding/new_address/address_alias.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/linked_wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter/material.dart';

const unknownMetricTitle = 'Unknown';

extension RouteExt on Route {
  String get metricTitle {
    final routeName = settings.name;
    if (routeName == null) {
      return unknownMetricTitle;
    }
    return getPageName(routeName);
  }

  bool get isIgnoreForVisitPageEvent =>
      metricVisitPageIgnoreScreen.contains(settings.name) ||
      metricTitle == unknownMetricTitle;

  Map<String, dynamic> get metricData {
    Map<String, dynamic> data = {};
    final routeName = settings.name;
    switch (routeName) {
      case AppRouter.viewPlayListPage:
        final payload = settings.arguments! as ViewPlaylistScreenPayload;
        data = {MixpanelProp.playlistId: payload.playListModel?.id};
      case AppRouter.editPlayListPage:
        final payload = settings.arguments! as PlayListModel;
        data = {
          MixpanelProp.playlistId: payload.id,
        };
      case AppRouter.artworkPreviewPage:
        final payload = settings.arguments! as ArtworkDetailPayload;
        data = {
          MixpanelProp.tokenId: payload.identities[payload.currentIndex].id,
          MixpanelProp.ownerAddress:
              payload.identities[payload.currentIndex].owner,
        };
      case AppRouter.artworkDetailsPage:
        final payload = settings.arguments! as ArtworkDetailPayload;
        data = {
          MixpanelProp.tokenId: payload.identities[payload.currentIndex].id,
          MixpanelProp.ownerAddress:
              payload.identities[payload.currentIndex].owner,
        };
      case AppRouter.claimedPostcardDetailsPage:
        final payload = settings.arguments! as PostcardDetailPagePayload;
        data = {
          MixpanelProp.tokenId: payload.identities[payload.currentIndex].id,
          MixpanelProp.ownerAddress:
              payload.identities[payload.currentIndex].owner,
        };
      case AppRouter.galleryPage:
        final payload = settings.arguments! as GalleryPagePayload;
        data = {
          MixpanelProp.address: payload.address,
        };
      case AppRouter.personaConnectionsPage:
        final payload = settings.arguments! as PersonaConnectionsPayload;
        data = {
          MixpanelProp.address: payload.address,
          MixpanelProp.type: payload.type.code,
        };
      case AppRouter.connectionDetailsPage:
        final payload = settings.arguments! as ConnectionItem;
        data = {
          MixpanelProp.title: payload.representative.name,
          MixpanelProp.type: payload.representative.connectionType,
        };
      case AppRouter.walletDetailsPage:
        final payload = settings.arguments! as WalletDetailsPayload;
        data = {
          MixpanelProp.type: payload.type.code,
          MixpanelProp.address: payload.walletAddress.address
        };
      case AppRouter.linkedWalletDetailsPage:
        final payload = settings.arguments! as LinkedWalletDetailsPayload;
        data = {
          MixpanelProp.type: payload.type.code,
          MixpanelProp.address: payload.connection.name
        };
      case AppRouter.scanQRPage:
        final payload = settings.arguments! as ScannerItem;
        data = {
          MixpanelProp.type: payload.name,
        };
      case AppRouter.globalReceivePage:
        final payload = settings.arguments! as GlobalReceivePayload;
        data = {
          MixpanelProp.address: payload.address,
          MixpanelProp.type: payload.blockchain,
        };
      case AppRouter.tbConnectPage:
        final payload = settings.arguments! as ConnectionRequest;
        data = {
          MixpanelProp.title: payload.name,
          MixpanelProp.url: payload.url,
        };
      case AppRouter.cloudPage:
        final payload = settings.arguments! as CloudPagePayload;
        data = {
          MixpanelProp.section: payload.section,
        };
      case AppRouter.cloudAndroidPage:
        final payload = settings.arguments! as CloudAndroidPagePayload;
        data = {
          MixpanelProp.section: payload.isEncryptionAvailable,
        };
      case AppRouter.releaseNotesPage:
        final payload = settings.arguments! as String;
        data = {
          MixpanelProp.message: payload,
        };
      case AppRouter.supportThreadPage:
        final payload = settings.arguments! as SupportThreadPayload;
        data = {
          MixpanelProp.title: payload.announcement?.title,
          MixpanelProp.type: payload.announcement?.type,
          MixpanelProp.message: payload.announcement?.body,
        };
      case AppRouter.githubDocPage:
        data = {};
      case AppRouter.sendArtworkPage:
        final payload = settings.arguments! as SendArtworkPayload;
        data = {
          MixpanelProp.tokenId: payload.asset.id,
          MixpanelProp.ownerAddress: payload.asset.owner,
        };
      case AppRouter.sendArtworkReviewPage:
        final payload = settings.arguments! as SendArtworkReviewPayload;
        data = {
          MixpanelProp.tokenId: payload.assetToken.id,
          MixpanelProp.ownerAddress: payload.assetToken.owner,
          MixpanelProp.recipientAddress: payload.address,
        };
      case AppRouter.wc2ConnectPage:
        final payload = settings.arguments! as Wc2Proposal;
        data = {
          MixpanelProp.title: payload.name,
          MixpanelProp.url: payload.url,
        };
      case AppRouter.wc2PermissionPage:
        final payload = settings.arguments! as Wc2RequestPayload;
        data = {
          MixpanelProp.title: payload.proposer.name,
          MixpanelProp.url: payload.proposer.url,
        };
      case AppRouter.inappWebviewPage:
        final payload = settings.arguments! as InAppWebViewPayload;
        data = {
          MixpanelProp.url: payload.url,
        };
      case AppRouter.postcardExplain:
        final payload = settings.arguments! as PostcardExplainPayload;
        data = {
          MixpanelProp.tokenId: payload.asset.id,
          MixpanelProp.ownerAddress: payload.asset.owner
        };
      case AppRouter.designStamp:
      case AppRouter.promptPage:
        final payload = settings.arguments! as DesignStampPayload;
        data = {
          MixpanelProp.tokenId: payload.asset.id,
          MixpanelProp.ownerAddress: payload.asset.owner,
        };
      case AppRouter.handSignaturePage:
        final payload = settings.arguments! as HandSignaturePayload;
        data = {
          MixpanelProp.tokenId: payload.asset.id,
          MixpanelProp.ownerAddress: payload.asset.owner,
        };
      case AppRouter.stampPreview:
        final payload = settings.arguments! as StampPreviewPayload;
        data = {
          MixpanelProp.tokenId: payload.asset.id,
          MixpanelProp.ownerAddress: payload.asset.owner,
        };
      case AppRouter.claimEmptyPostCard:
        final payload = settings.arguments! as RequestPostcardResponse;
        data = {
          MixpanelProp.tokenId: payload.tokenId,
          MixpanelProp.url: payload.previewURL,
        };
      case AppRouter.payToMintPostcard:
        final payload = settings.arguments! as PayToMintRequest;
        data = {
          MixpanelProp.tokenId: payload.tokenId,
          MixpanelProp.url: payload.previewURL,
          MixpanelProp.address: payload.address,
        };
      case AppRouter.postcardSelectAddressScreen:
        data = {};
      case AppRouter.receivePostcardPage:
        final payload = settings.arguments! as ReceivePostcardPageArgs;
        data = {
          MixpanelProp.tokenId: payload.asset.id,
          MixpanelProp.url: payload.asset.previewURL,
          MixpanelProp.ownerAddress: payload.asset.owner,
        };
      case AppRouter.irlWebView:
        final payload = settings.arguments! as IRLWebScreenPayload;
        data = {
          MixpanelProp.url: payload.url,
        };
      case AppRouter.irlSignMessage:
        final payload = settings.arguments! as IRLSignMessagePayload;
        data = {
          MixpanelProp.type: payload.chain,
          MixpanelProp.address: payload.sourceAddress,
        };
      case AppRouter.postcardLocationExplain:
        final payload = settings.arguments! as PostcardExplainPayload;
        data = {
          MixpanelProp.tokenId: payload.asset.id,
          MixpanelProp.ownerAddress: payload.asset.owner,
        };
      case AppRouter.addToCollectionPage:
        final payload = settings.arguments! as PlayListModel;
        data = {
          MixpanelProp.playlistId: payload.id,
        };
      case AppRouter.exhibitionDetailPage:
        final payload = settings.arguments! as ExhibitionDetailPayload;
        data = {
          MixpanelProp.exhibitionId: payload.exhibitions[payload.index].id,
        };
      case AppRouter.ffArtworkPreviewPage:
        final payload =
            settings.arguments! as FeralFileArtworkPreviewPagePayload;
        data = {
          MixpanelProp.artworkId: payload.artwork.id,
          MixpanelProp.seriesId: payload.artwork.seriesID,
        };
      case AppRouter.feralFileSeriesPage:
        final payload = settings.arguments! as FeralFileSeriesPagePayload;
        data = {
          MixpanelProp.seriesId: payload.seriesId,
          MixpanelProp.exhibitionId: payload.exhibitionId,
        };
      case AppRouter.tbSendTransactionPage:
        final payload = settings.arguments! as BeaconRequest;
        data = {
          MixpanelProp.type: payload.type,
          MixpanelProp.address: payload.sourceAddress,
          MixpanelProp.title: payload.name,
          MixpanelProp.url: payload.url,
        };
      case AppRouter.viewExistingAddressPage:
        final payload = settings.arguments! as ViewExistingAddressPayload;
        data = {
          MixpanelProp.isOnboarding: payload.isOnboarding,
        };
      case AppRouter.sendCryptoPage:
        final payload = settings.arguments! as SendData;
        data = {
          MixpanelProp.type: payload.type.code,
          MixpanelProp.address: payload.address,
        };
      case AppRouter.sendReviewPage:
        final payload = settings.arguments! as SendCryptoPayload;
        data = {
          MixpanelProp.type: payload.type.code,
          MixpanelProp.address: payload.address,
        };
      case AppRouter.nameAddressPersonaPage:
        final payload = settings.arguments! as NameAddressPersonaPayload;
        data = {
          MixpanelProp.address: payload.listAddressInfo.first.address,
        };
      case AppRouter.addressAliasPage:
        final payload = settings.arguments! as AddressAliasPayload;
        data = {
          MixpanelProp.address: payload.walletType.name,
        };
      case AppRouter.tbSignMessagePage:
        final payload = settings.arguments! as BeaconRequest;
        data = {
          MixpanelProp.type: payload.type,
          MixpanelProp.address: payload.sourceAddress,
          MixpanelProp.title: payload.name,
          MixpanelProp.url: payload.url,
        };
      case AppRouter.auSignMessagePage:
        final payload = settings.arguments! as Wc2RequestPayload;
        data = {
          MixpanelProp.title: payload.proposer.name,
          MixpanelProp.url: payload.proposer.url,
        };
      case AppRouter.globalReceiveDetailPage:
        final payload = settings.arguments! as GlobalReceivePayload;
        data = {
          MixpanelProp.address: payload.address,
          MixpanelProp.type: payload.blockchain,
        };
      case AppRouter.chatThreadPage:
        final payload = settings.arguments! as ChatThreadPagePayload;
        data = {
          MixpanelProp.title: payload.name,
          MixpanelProp.address: payload.address,
          MixpanelProp.tokenId: payload.token.id,
        };
      case AppRouter.wcSignMessagePage:
        final payload = settings.arguments! as WCSignMessagePageArgs;
        data = {
          MixpanelProp.type: payload.type.name,
          MixpanelProp.message: payload.message,
          MixpanelProp.title: payload.peerMeta.name,
          MixpanelProp.url: payload.peerMeta.url,
        };
      case AppRouter.wcSendTransactionPage:
        final payload = settings.arguments! as WCSendTransactionPageArgs;
        data = {
          MixpanelProp.title: payload.peerMeta.name,
          MixpanelProp.url: payload.peerMeta.url,
          MixpanelProp.address: payload.transaction.from,
          MixpanelProp.recipientAddress: payload.transaction.to,
        };
      case AppRouter.exhibitionCustomNote:
        final payload = settings.arguments! as Exhibition;
        data = {
          MixpanelProp.exhibitionId: payload.id,
        };
      default:
        break;
    }
    return data;
  }
}

final screenNameMap = {
  AppRouter.createPlayListPage: 'Create Playlist',
  AppRouter.viewPlayListPage: 'View Playlist',
  AppRouter.editPlayListPage: 'Edit Playlist',
  AppRouter.onboardingPage: 'Onboarding',
  AppRouter.artworkPreviewPage: 'Artwork Preview',
  AppRouter.artworkDetailsPage: 'Artwork Detail',
  AppRouter.claimedPostcardDetailsPage: 'Postcard Detail',
  AppRouter.galleryPage: 'Gallery',
  AppRouter.settingsPage: 'Settings',
  AppRouter.personaConnectionsPage: 'Connections',
  AppRouter.connectionDetailsPage: 'Connection Detail',
  AppRouter.walletDetailsPage: 'Addresses',
  AppRouter.linkedWalletDetailsPage: 'View Only Address Detail',
  AppRouter.scanQRPage: 'Scan QR',
  AppRouter.globalReceivePage: 'Global Receive',
  AppRouter.recoveryPhrasePage: 'Recovery Phrase',
  AppRouter.tbConnectPage: 'TB Connect',
  AppRouter.cloudPage: 'Cloud',
  AppRouter.cloudAndroidPage: 'Cloud',
  AppRouter.linkManually: 'Link Manually',
  AppRouter.autonomySecurityPage: 'Feral File Security',
  AppRouter.releaseNotesPage: 'Release Notes',
  AppRouter.hiddenArtworksPage: 'Hidden Artworks',
  AppRouter.supportCustomerPage: 'Support Customer',
  AppRouter.supportListPage: 'Support List',
  AppRouter.merchOrdersPage: 'Merch Orders',
  AppRouter.supportThreadPage: 'Support Thread',
  AppRouter.bugBountyPage: 'Bug Bounty',
  AppRouter.keySyncPage: 'Key Sync',
  AppRouter.githubDocPage: 'Github Doc',
  AppRouter.sendArtworkPage: 'Send Artwork',
  AppRouter.sendArtworkReviewPage: 'Send Artwork Review',
  AppRouter.wc2ConnectPage: 'WC2 Connect',
  AppRouter.wc2PermissionPage: 'WC2 Permission',
  AppRouter.preferencesPage: 'Preferences',
  AppRouter.walletPage: 'Wallet',
  AppRouter.subscriptionPage: 'Subscription',
  AppRouter.dataManagementPage: 'Data Management',
  AppRouter.inappWebviewPage: 'Inapp Webview',
  AppRouter.postcardExplain: 'Postcard Explain',
  AppRouter.designStamp: 'Design Stamp',
  AppRouter.promptPage: 'Prompt',
  AppRouter.handSignaturePage: 'Hand Signature',
  AppRouter.stampPreview: 'Stamp Preview',
  AppRouter.claimEmptyPostCard: 'Claim Empty Postcard',
  AppRouter.payToMintPostcard: 'Pay To Mint Postcard',
  AppRouter.postcardSelectAddressScreen: 'Postcard Select Address',
  AppRouter.receivePostcardPage: 'Receive Postcard',
  AppRouter.irlWebView: 'IRL Webview',
  AppRouter.irlSignMessage: 'IRL Sign Message',
  AppRouter.keyboardControlPage: 'Keyboard Control',
  AppRouter.touchPadPage: 'Touch Pad',
  AppRouter.postcardLeaderboardPage: 'Postcard Leaderboard',
  AppRouter.postcardLocationExplain: 'Postcard Location Explain',
  AppRouter.predefinedCollectionPage: 'Predefined Collection',
  AppRouter.addToCollectionPage: 'Add To Playlist',
  AppRouter.collectionPage: 'Collection',
  AppRouter.exhibitionsPage: 'Explore Exhibitions',
  AppRouter.organizePage: 'Organize',
  AppRouter.addressAliasPage: 'Address Alias',
  AppRouter.nameAddressPersonaPage: 'Name Address Persona',
  AppRouter.viewExistingAddressPage: 'View Existing Address',
  AppRouter.sendCryptoPage: 'Send Crypto',
  AppRouter.sendReviewPage: 'Send Review',
  AppRouter.importSeedsPage: 'Import Seeds',
  AppRouter.tbSignMessagePage: 'TB Sign Message',
  AppRouter.auSignMessagePage: 'AU Sign Message',
  AppRouter.globalReceiveDetailPage: 'Global Receive Detail',
  AppRouter.chatThreadPage: 'Chat Thread',
  AppRouter.wcSignMessagePage: 'WC Sign Message',
  AppRouter.wcSendTransactionPage: 'WC Send Transaction',
  AppRouter.momaPostcardPage: 'MoMA Postcards',
  AppRouter.tbSendTransactionPage: 'TB Send Transaction',
  AppRouter.feralFileSeriesPage: 'Series Detail',
  AppRouter.ffArtworkPreviewPage: 'Feral File Artwork Preview',
  AppRouter.exhibitionDetailPage: 'Exhibition Detail',
  AppRouter.previewPrimerPage: 'Preview Primer',
  AppRouter.projectsList: 'Projects',
  AppRouter.artistsListPage: 'Artists list',
  AppRouter.exhibitionCustomNote: 'Exhibition Custom Note',
};

String getPageName(String routeName) {
  String pageName = routeName;
  return screenNameMap[routeName] ?? pageName;
}
