//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:package_info_plus/package_info_plus.dart';

const INDEXER_TOKENS_MAXIMUM = 50;
const CLOUDFLAREIMAGEURLPREFIX =
    'https://imagedelivery.net/iCRs13uicXIPOWrnuHbaKA/';
const AUTONOMY_TV_PEER_NAME = 'Autonomy TV';
const DEFAULT_IPFS_PREFIX = 'https://ipfs.io';
const CLOUDFLARE_IPFS_PREFIX = 'https://cloudflare-ipfs.com';
const EMPTY_ISSUE_MESSAGE = 'NO MESSAGE BODY WAS PROVIDED';
const KNOWN_BUGS_LINK = 'https://github.com/orgs/bitmark-inc/projects/16';
const USER_TEST_CALENDAR_LINK =
    'https://calendly.com/anais-bitmark/usertesting';

Future<bool> isAppCenterBuild() async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.packageName.contains("inhouse");
}

Future<String> getDemoAccount() async {
  return await isAppCenterBuild() ? "demo" : "demo2";
}

Future<String> getAppVariant() async {
  return await isAppCenterBuild() ? "inhouse" : "production";
}

enum WalletApp {
  MetaMask,
  Kukai,
  Temple,
}

class GallerySortProperty {
  static const Source = 'Source';
  static const Medium = 'Medium';
  static const Artist = 'Artist';
  static const Chain = "Chain";

  static List<String> get getList => [Source, Medium, Artist, Chain];
}

extension RawValue on WalletApp {
  String get rawValue => this.toString().split('.').last;
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
  String get rawValue => this.toString().split('.').last;

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
}

extension CryptoTypeHelpers on CryptoType {
  String get code {
    switch (this) {
      case CryptoType.ETH:
        return "ETH";
      case CryptoType.XTZ:
        return "XTZ";
      case CryptoType.BITMARK:
        return "USDC";
    }
  }

  String get fullCode {
    switch (this) {
      case CryptoType.ETH:
        return "Ethereum (ETH)";
      case CryptoType.XTZ:
        return "Tezos (XTZ)";
      case CryptoType.BITMARK:
        return "USD Coin (USDC)";
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
    }
  }
}
