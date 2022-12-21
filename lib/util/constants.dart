//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fee_util.dart';

const INDEXER_TOKENS_MAXIMUM = 50;
const INDEXER_UNKNOWN_SOURCE = 'unknown';
const AUTONOMY_TV_PEER_NAME = 'Autonomy TV';
const DEFAULT_IPFS_PREFIX = 'https://ipfs.io';
const IPFS_PREFIX = "ipfs://";
const CLOUDFLARE_IPFS_PREFIX = 'https://cloudflare-ipfs.com';
const EMPTY_ISSUE_MESSAGE = 'NO MESSAGE BODY WAS PROVIDED';
const RATING_MESSAGE_START = "### Customer support rating\n";
const MUTE_RATING_MESSAGE = "MUTE_RATING_MESSAGE";
const STAR_RATING = "###STAR#RATING#";
const KNOWN_BUGS_LINK = 'https://github.com/orgs/bitmark-inc/projects/16';
const USER_TEST_CALENDAR_LINK =
    'https://calendly.com/anais-bitmark/usertesting';
const FF_TOKEN_DEEPLINK_PREFIX = 'https://autonomy.io/apps/feralfile?token=';
const AUTONOMY_CLIENT_GITHUB_LINK =
    "https://github.com/bitmark-inc/autonomy-client";
const DEEP_LINKS = [
  "autonomy://",
  "https://autonomy.io",
  "https://au.bitmark.com",
  "https://autonomy-app.app.link",
  "https://autonomy-app-alternate.app.link",
  "https://link.autonomy.io",
];
const FF_ARTIST_COLLECTOR =
    'https://feralfile.com/docs/artist-collector-rights';
const WEB3_PRIMER_URL = 'https://autonomy.io/catalog/primer/';
const COLLECTOR_RIGHTS_DEFAULT_DOCS =
    "/bitmark-inc/feral-file-docs/master/docs/collector-rights/standard/en.md";
const COLLECTOR_RIGHTS_MEMENTO_DOCS =
    "/bitmark-inc/feral-file-docs/master/docs/collector-rights/MoMA-Memento/en.md";
const COLLECTOR_RIGHTS_MOMA_009_UNSUPERVISED_DOCS =
    "/bitmark-inc/feral-file-docs/master/docs/collector-rights/009-unsupervised/en.md";
const MOMA_MEMENTO_EXHIBITION_ID = "00370334-6151-4c04-b6be-dc09e325d57d";
const MOMA_009_UNSUPERVISED_CONTRACT_ADDRESS =
    "0x7a15b36cB834AeA88553De69077D3777460d73Ac";
const CHECK_WEB3_PRIMER_URL =
    'https://feralfile.com/artworks/memento-1-study-for-unsupervised';
const int cellPerRowPhone = 3;
const int cellPerRowTablet = 6;
const double cellSpacing = 3.0;

const Duration SENT_ARTWORK_HIDE_TIME = Duration(minutes: 20);
const USDC_CONTRACT_ADDRESS_GOERLI =
    "0x07865c6E87B9F70255377e024ace6630C1Eaa37F";
const USDC_CONTRACT_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const DEFAULT_FEE_OPTION = FeeOption.MEDIUM;

String get usdcContractAddress => Environment.appTestnetConfig
    ? USDC_CONTRACT_ADDRESS_GOERLI
    : USDC_CONTRACT_ADDRESS;

Future<bool> isAppCenterBuild() async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.packageName.contains("inhouse");
}

Future<String> getDemoAccount() async {
  return await isAppCenterBuild() ? "demo" : "tv";
}

Future<String> getAppVariant() async {
  return await isAppCenterBuild() ? "inhouse" : "production";
}

String feralFileExhibitionUrl(String slug) =>
    "${Environment.feralFileAPIURL}/exhibitions/$slug";

String feralFileArtworkUrl(String slug) =>
    "${Environment.feralFileAPIURL}/artworks/$slug";

enum WalletApp {
  MetaMask,
  Kukai,
  Temple,
}

class Survey {
  static const onboarding = 'onboarding_survey';
}

class GallerySortProperty {
  static const Source = 'Source';
  static const Medium = 'Medium';
  static const Artist = 'Artist';
  static const Chain = "Chain";

  static List<String> get getList => [Source, Medium, Artist, Chain];
}

extension RawValue on WalletApp {
  String get rawValue => toString().split('.').last;
}

class ReportIssueType {
  static const Feature = 'feature';
  static const Bug = 'bug';
  static const Feedback = 'feedback';
  static const Other = 'other';
  static const Exception = 'exception';
  static const ReportNFTIssue = 'report nft issue';

  static List<String> get getList =>
      [Feature, Bug, Feedback, Other, Exception, ReportNFTIssue];

  static List<String> get getSuggestList => [Feature, Bug, Feedback, Other];

  static String toTitle(String item) {
    switch (item) {
      case Feature:
        return 'Request a feature';
      case Bug:
        return 'Report a bug';
      case Feedback:
        return 'Share feedback';
      case Exception:
        return 'Report a bug';
      case ReportNFTIssue:
        return 'Report NFT issue';
      default:
        return 'Something else?';
    }
  }

  static String introMessage(String item) {
    switch (item) {
      case Feature:
        return 'Thanks for taking the time to help us improve Autonomy. We’re always looking for great ideas. What feature would you like to request?';
      case Bug:
        return 'We’re sorry to hear you’ve experienced a problem using Autonomy. Thanks for taking the time to help us improve. Please describe the bug for us.';
      case Feedback:
        return 'Thanks for taking the time to share your feedback with us. What’s on your mind?';
      case Exception:
        return 'Thanks for taking the time to help improve Autonomy. We’ve received your automatic crash report and are looking into it. How else can we help?';
      case ReportNFTIssue:
        return 'Thanks for taking the time to help improve Autonomy. We’ve received your NFT issue and are looking into it. How else can we help?';
      default:
        return 'Thanks for reaching out to the Autonomy team! What’s on your mind?';
    }
  }
}

// Premium Features
enum PremiumFeature {
  AutonomyTV,
}

extension PremiumFeatureExtension on PremiumFeature {
  String get rawValue => toString().split('.').last;

  String get description {
    switch (rawValue) {
      case 'AutonomyTV':
        return 'Subscribe to play your collection on external devices.';
      default:
        return '';
    }
  }

  String get moreAutonomyDescription {
    switch (rawValue) {
      case 'AutonomyTV':
        return 'You must upgrade to an Autonomy subscription to connect to Autonomy on TV.';
      default:
        return '';
    }
  }
}

class ContextedAddress {
  final CryptoType cryptoType;
  final String address;

  ContextedAddress(
    this.cryptoType,
    this.address,
  );
}

enum CryptoType {
  ETH,
  XTZ,
  USDC,
  UNKNOWN,
}

extension CryptoTypeHelpers on CryptoType {
  String get code {
    switch (this) {
      case CryptoType.ETH:
        return "ETH";
      case CryptoType.XTZ:
        return "XTZ";
      case CryptoType.USDC:
        return "USDC";
      case CryptoType.UNKNOWN:
        return "";
    }
  }

  String get fullCode {
    switch (this) {
      case CryptoType.ETH:
        return "Ethereum (ETH)";
      case CryptoType.XTZ:
        return "Tezos (XTZ)";
      case CryptoType.USDC:
        return "USD Coin (USDC)";
      case CryptoType.UNKNOWN:
        return "";
    }
  }

  String get source {
    switch (this) {
      case CryptoType.ETH:
        return "Ethereum";
      case CryptoType.XTZ:
        return "Tezos";
      case CryptoType.USDC:
        return "USDC";
      case CryptoType.UNKNOWN:
        return "Unknown";
    }
  }
}

class Constants {
  static const minCountToReview = 10;
  static const durationToReview = Duration(days: 30);

  // Responsive
  static const kTabletBreakpoint = 480;
  static const kDesktopBreakpoint = 1025;
  static const maxWidthModalTablet = 387.0;
  static const paddingMobile = EdgeInsets.symmetric(horizontal: 14);
  static const paddingTablet = EdgeInsets.symmetric(horizontal: 20);
  static const paddingTabletLandScape = EdgeInsets.symmetric(horizontal: 32);
  static const branchDeepLinks = [
    "https://autonomy-app.app.link",
    "https://autonomy-app-alternate.app.link",
    "https://link.autonomy.io",
  ];
}

class MixpanelEvent {
  static const addExistAccount = 'add_exist_account';
  static const createNewAccount = 'create_new_account';
  static const generateLink = 'generate_link';
  static const backGenerateLink = 'back_generate_link';
  static const backImportAccount = 'back_import_account';
  static const restoreAccount = 'restore_account';
  static const cancelContact = 'cancel_contact';
  static const connectContactSuccess = 'connect_contact_success';
  static const backConnectMarket = 'back_connect_market';
  static const connectMarket = 'connect_market';
  static const connectMarketSuccess = 'connect_market_success';
  static const backConfirmTransaction = 'back_confirm_transaction';
  static const confirmTransaction = 'confirm_transaction';
  static const clickArtist = 'click_artist';
  static const stayInArtworkDetail = 'stay_in_artwork_detail';
  static const clickArtworkInfo = 'click_artwork_info';
  static const acceptOwnership = 'accept_ownership';
  static const declineOwnership = 'delice_ownership';
  static const generateReport = 'generate_report';
  static const displayUnableLoadIPFS = 'display_unable_load_IPFS';
  static const clickLoadIPFSAgain = 'click_load_IPFS_again';
  static const showLoadingArtwork = 'show_loading_artwork';
  static const seeArtworkFullScreen = 'see_artwork_fullscreen';
  static const streamChromecast = 'stream_chromecast';
  static const linkLedger = 'link_ledger';
  static const viewArtwork = 'view_artwork';
  static const viewDiscovery = 'view_discovery';
  static const deviceBackground = 'device_background';
}
