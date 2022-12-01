//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

const INDEXER_TOKENS_MAXIMUM = 50;
const INDEXER_UNKNOWN_SOURCE = 'unknown';
const CLOUDFLAREIMAGEURLPREFIX =
    'https://imagedelivery.net/iCRs13uicXIPOWrnuHbaKA/';
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
const CHECK_WEB3_PRIMER_URL =
    'https://feralfile.com/artworks/memento-1-study-for-unsupervised';

const int cellPerRowPhone = 3;
const int cellPerRowTablet = 6;
const double cellSpacing = 3.0;

const Duration SENT_ARTWORK_HIDE_TIME = Duration(minutes: 20);
const USDC_CONTRACT_ADDRESS_GOERLI =
    "0x07865c6E87B9F70255377e024ace6630C1Eaa37F";
const USDC_CONTRACT_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

String get usdcContractAddress => Environment.appTestnetConfig
    ? USDC_CONTRACT_ADDRESS_GOERLI
    : USDC_CONTRACT_ADDRESS;

Future<bool> isAppCenterBuild() async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return !info.packageName.contains("inhouse");
}

Future<String> getDemoAccount() async {
  return await isAppCenterBuild() ? "demo" : "tv";
}

Future<String> getAppVariant() async {
  return await isAppCenterBuild() ? "inhouse" : "production";
}

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
  BITMARK,
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
      case CryptoType.BITMARK:
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
      case CryptoType.BITMARK:
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
      case CryptoType.BITMARK:
        return "Bitmark";
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
