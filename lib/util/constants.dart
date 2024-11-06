//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/eth_utils.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

const INDEXER_TOKENS_MAXIMUM = 50;
const INDEXER_UNKNOWN_SOURCE = 'unknown';
const AUTONOMY_TV_PEER_NAME = 'Autonomy TV';
const DEFAULT_IPFS_PREFIX = 'https://ipfs.io';
const IPFS_PREFIX = 'ipfs://';
const CLOUDFLARE_IPFS_PREFIX = 'https://cloudflare-ipfs.com';
const EMPTY_ISSUE_MESSAGE = 'NO MESSAGE BODY WAS PROVIDED';
const RATING_MESSAGE_START = '### Customer support rating\n';
const MUTE_RATING_MESSAGE = 'MUTE_RATING_MESSAGE';
const STAR_RATING = '###STAR#RATING#';
const KNOWN_BUGS_LINK = 'https://github.com/orgs/bitmark-inc/projects/33';
const IRL_DEEPLINK_PREFIXES = [
  'https://autonomy.io/apps/irl/',
  'https://app.feralfile.com/apps/irl/'
];
const AUTONOMY_CLIENT_GITHUB_LINK =
    'https://github.com/bitmark-inc/autonomy-client';
const DEEP_LINKS = [
  'autonomy://',
  'https://autonomy.io',
  'https://au.bitmark.com',
  ...Constants.branchDeepLinks,
  'feralfile://',
];
const WEB3_PRIMER_URL = 'https://autonomy.io/catalog/primer/';
const COLLECTOR_RIGHTS_DEFAULT_DOCS =
    '/bitmark-inc/feral-file-docs/master/docs/collector-rights/standard/en.md';
const COLLECTOR_RIGHTS_MEMENTO_DOCS =
    '/bitmark-inc/feral-file-docs/master/docs/collector-rights/MoMA-Memento/en.md';
const COLLECTOR_RIGHTS_MOMA_009_UNSUPERVISED_DOCS =
    '/bitmark-inc/feral-file-docs/master/docs/collector-rights/009-unsupervised/en.md';

const POSTCARD_RIGHTS_DOCS =
    'https://raw.githubusercontent.com/bitmark-inc/autonomy-apps/main/docs/postcard_collector_rights.md';
const MOMA_MEMENTO_EXHIBITION_IDS = [
  '00370334-6151-4c04-b6be-dc09e325d57d',
  '3ee3e8a4-90dd-4843-8ec3-858e6bea1965'
];

const cloudFlarePrefix = 'https://imagedelivery.net/';

const POSTCARD_IPFS_PREFIX_TEST = 'https://ipfs.test.bitmark.com/ipfs';
const POSTCARD_IPFS_PREFIX_PROD = 'https://ipfs.bitmark.com/ipfs';

const TEIA_ART_CONTRACT_ADDRESSES = ['KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton'];
const OPENSEA_ASSET_PREFIX = 'https://opensea.io/assets/';
const OBJKT_ASSET_PREFIX_MAINNET = 'https://objkt.com/asset/';
const OBJKT_ASSET_PREFIX_TESTNET = 'https://ghostnet.objkt.com/asset/';
const TEIA_ART_ASSET_PREFIX = 'https://teia.art/objkt/';
const FXHASH_IDENTIFIER = 'fxhash.xyz';

String get objktAssetPrefix {
  if (Environment.appTestnetConfig) {
    return OBJKT_ASSET_PREFIX_TESTNET;
  } else {
    return OBJKT_ASSET_PREFIX_MAINNET;
  }
}

const MOMA_009_UNSUPERVISED_CONTRACT_ADDRESS =
    '0x7a15b36cB834AeA88553De69077D3777460d73Ac';
List<String> checkWeb3ContractAddress = [
  '0x7E6c132B8cb00899d17750E0fD982EA122C6b0f2',
  ...momaMementoContractAddresses,
  Environment.autonomyAirDropContractAddress,
];

const MOMA_MEMENTO_CONTRACT_ADDRESSES_TESTNET = [
  'KT1ESGez4dEuDjjNt4k2HPAK5Nzh7e8X8jyX',
  'KT1MDvWtwi8sCcyJdbWPScTdFa2uJ8mnKNJe',
  'KT1DPFXN2NeFjg1aQGNkVXYS1FAy4BymcbZz',
];

const MOMA_MEMENTO_CONTRACT_ADDRESSES_MAINNET = [
  'KT1CPeE8YGVG16xkpoE9sviUYoEzS7hWfu39',
  'KT1U49F46ZRK2WChpVpkUvwwQme7Z595V3nt',
  'KT19rZLpAurqKuDXtkMcJZWvWqGJz1CwWHzr',
  'KT1KzEtNm6Bb9qip8trTsnBohoriH2g2dvc7',
  'KT1RWFkvQPkhjxQQzg1ZvS2EKbprbkAdPRSc',
];

const wedgwoodActivationContractAddress =
    'KT1VNooU9Nrj6hB1SwTkCA5yFXJxjZQCtBRM';

const CASA_BATLLO_CONTRACT_ADDRESS_TESTNET =
    'KT1LHMthpZWUyzgjtxu4ktD9kCbzEYQJBHGp';

const CASA_BATLLO_CONTRACT_ADDRESS_MAINNET =
    'KT19VkuK7tw22m4P36xRpPiMT4qzEw8YAN8A';

String get casaBatlloContractAddress => Environment.appTestnetConfig
    ? CASA_BATLLO_CONTRACT_ADDRESS_TESTNET
    : CASA_BATLLO_CONTRACT_ADDRESS_MAINNET;

List<String> tranferNotAllowContractAddresses = [
  casaBatlloContractAddress,
];

List<String> get momaMementoContractAddresses {
  if (Environment.appTestnetConfig) {
    return MOMA_MEMENTO_CONTRACT_ADDRESSES_TESTNET;
  } else {
    return MOMA_MEMENTO_CONTRACT_ADDRESSES_MAINNET;
  }
}

const artworkDataDivider = Divider(
  height: 32,
  color: Color.fromRGBO(255, 255, 255, 0.3),
  thickness: 1,
);

const artworkSectionDivider = Divider(
  height: 32,
  color: AppColor.white,
  thickness: 1,
);

const int cellPerRowPhone = 3;
const int cellPerRowTablet = 6;
const double cellSpacing = 3;

const Duration SENT_ARTWORK_HIDE_TIME = Duration(minutes: 2);
const Duration STAMPING_POSTCARD_LIMIT_TIME = Duration(minutes: 60);

const Color POSTCARD_BACKGROUND_COLOR = Color.fromRGBO(242, 242, 242, 1);
const Color POSTCARD_PINK_BUTTON_COLOR = Color.fromRGBO(231, 75, 168, 1);
const Color POSTCARD_GREEN_BUTTON_COLOR = Color.fromRGBO(79, 174, 79, 1);

const POSTCARD_ABOUT_THE_PROJECT =
    'https://www.moma.org/calendar/exhibitions/5618?preview=true';

final moMAGeoLocation = GeoLocation(
    position: const Location(lat: 40.761, lon: -73.980), address: 'MoMA');

final internetUserGeoLocation =
    GeoLocation(position: const Location(lat: null, lon: null), address: 'Web');

const int MAX_STAMP_IN_POSTCARD = 15;

const int STAMP_SIZE = 2160;

const String POSTCARD_LOCATION_HIVE_BOX = 'postcard_location_hive_box';

const String MIXPANEL_HIVE_BOX = 'mixpanel_hive_box';

const String POSTCARD_SOFTWARE_FULL_LOAD_MESSAGE =
    'postcard software artwork loaded';
const String POSTCARD_FINISH_GETNEWSTAMP_MESSAGE = 'finish getNewStamp';

const double POSTCARD_ASPECT_RATIO_ANDROID = 368.0 / 268;
const double POSTCARD_ASPECT_RATIO_IOS = 348.0 / 268;

double get postcardAspectRatio => Platform.isAndroid
    ? POSTCARD_ASPECT_RATIO_ANDROID
    : POSTCARD_ASPECT_RATIO_IOS;

const double STAMP_ASPECT_RATIO = 345.0 / 378;

const POSTCARD_SHARE_LINK_VALID_DURATION = Duration(hours: 24);

const USDC_CONTRACT_ADDRESS_GOERLI =
    '0x07865c6E87B9F70255377e024ace6630C1Eaa37F';
const USDC_CONTRACT_ADDRESS = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const DEFAULT_FEE_OPTION = FeeOption.MEDIUM;

String get usdcContractAddress => Environment.appTestnetConfig
    ? USDC_CONTRACT_ADDRESS_GOERLI
    : USDC_CONTRACT_ADDRESS;

const TV_APP_STORE_URL =
    'https://play.google.com/store/apps/details?id=com.bitmark.autonomy_tv';

const MOMA_TERMS_CONDITIONS_URL =
    'https://github.com/bitmark-inc/autonomy-apps/blob/main/docs/postcard_terms.md';

const AUTONOMY_DOCUMENT_PREFIX = 'https://github.com/bitmark-inc';

const AUTONOMY_RAW_DOCUMENT_PREFIX =
    'https://raw.githubusercontent.com/bitmark-inc';

const markdownExt = '.md';

const String POSTCARD_SIGN_PREFIX = 'Tezos Signed Message:';

const CONNECT_FAILED_DURATION = Duration(seconds: 10);

const int COLLECTION_INITIAL_MIN_SIZE = 20;

const int LEADERBOARD_PAGE_SIZE = 50;

const int maxCollectionListSize = 3;

const maxRetryCount = 3;

const double collectionListArtworkAspectRatio = 375 / 210.94;
const String collectionListArtworkThumbnailVariant = 'thumbnailList';

const String POSTCARD_ONSITE_REQUEST_ID = 'moma-postcard-onsite';
const String POSTCARD_ONLINE_REQUEST_ID = 'moma-postcard-online';

const String SOURCE_EXHIBITION_ID = 'source';
const List<String> YOUTUBE_DOMAINS = ['youtube.com', 'youtu.be'];
const List<String> YOUTUBE_VARIANTS = [
  'maxresdefault', // Higher quality - May or may not exist
  'mqdefault', // Lower quality - Guaranteed to exist
];

const MAGIC_NUMBER = 168;

Future<bool> isAppCenterBuild() async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.packageName.contains('inhouse');
}

Future<String> getAppVariant() async =>
    await isAppCenterBuild() ? 'inhouse' : 'production';

String feralFileExhibitionUrl(String slug) =>
    '${Environment.feralFileAPIURL}/exhibitions/$slug';

String feralFileArtworkUrl(String slug) =>
    '${Environment.feralFileAPIURL}/artworks/$slug';

String get etherScanUrl {
  switch (Environment.web3ChainId) {
    case 11155111:
      return 'https://sepolia.etherscan.io';
    case 5:
      return 'https://goerli.etherscan.io';
    default:
      return 'https://etherscan.io';
  }
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
  static const Chain = 'Chain';

  static List<String> get getList => [Source, Medium, Artist, Chain];
}

extension RawValue on WalletApp {
  String get rawValue => toString().split('.').last;
}

class ReportIssueType {
  static const Bug = 'bug';
  static const Exception = 'exception';
  static const Announcement = 'announcement';
  static const MerchandiseIssue = 'merchandise postcard';
  static const ChatWithFeralfile = 'chat with Feral File';

  static List<String> get getList =>
      [Bug, Exception, Announcement, MerchandiseIssue, ChatWithFeralfile];

  static List<String> get getSuggestList => [Bug];

  static String toTitle(String item) {
    switch (item) {
      case Exception:
        return 'Report a bug';
      case Announcement:
        return 'announcement'.tr();
      case ChatWithFeralfile:
        return 'chat_with_feralfile'.tr();
      case MerchandiseIssue:
        return 'Merchandise issue';
      case Bug:
      default:
        return 'Contact Feral File';
    }
  }

  static String introMessage(String item) {
    switch (item) {
      case Exception:
        return 'Thanks for taking the time to help improve Feral File. We’ve received your automatic crash report and are looking into it. How else can we help?';
      case Bug:
      default:
        return 'Thanks for reaching out to the Feral File! How can we assist you with feedback, a bug, or a feature request?';
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
        return ' to play your collection on external devices.';
      default:
        return '';
    }
  }

  String get moreAutonomyDescription {
    switch (rawValue) {
      case 'AutonomyTV':
        return 'You must upgrade to an Feral File subscription to connect to Feral File on TV.';
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
  UNKNOWN;

  static CryptoType fromSource(String source) {
    switch (source.toLowerCase()) {
      case 'ethereum':
        return CryptoType.ETH;
      case 'tezos':
        return CryptoType.XTZ;
      case 'usdc':
        return CryptoType.USDC;
      default:
        return CryptoType.UNKNOWN;
    }
  }

  static CryptoType fromAddress(String source) {
    if (source.isValidTezosAddress) {
      return CryptoType.XTZ;
    } else if (source.toEthereumAddress() != null) {
      return CryptoType.ETH;
    } else {
      return CryptoType.UNKNOWN;
    }
  }
}

enum AnnouncementID {
  WELCOME('welcome'),
  SUBSCRIBE('subscription'),
  ;

  const AnnouncementID(this.value);

  final String value;
}

enum StatusCode {
  notFound(404),
  success(200),
  forbidden(403),
  badRequest(400);

  const StatusCode(this.value);

  final int value;
}

extension CryptoTypeHelpers on CryptoType {
  String get code {
    switch (this) {
      case CryptoType.ETH:
        return 'ETH';
      case CryptoType.XTZ:
        return 'XTZ';
      case CryptoType.USDC:
        return 'USDC';
      case CryptoType.UNKNOWN:
        return '';
    }
  }

  String get fullCode {
    switch (this) {
      case CryptoType.ETH:
        return 'Ethereum (ETH)';
      case CryptoType.XTZ:
        return 'Tezos (XTZ)';
      case CryptoType.USDC:
        return 'USD Coin (USDC)';
      case CryptoType.UNKNOWN:
        return '';
    }
  }

  String get source {
    switch (this) {
      case CryptoType.ETH:
        return 'Ethereum';
      case CryptoType.XTZ:
        return 'Tezos';
      case CryptoType.USDC:
        return 'USDC';
      case CryptoType.UNKNOWN:
        return 'Unknown';
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
    'https://autonomy-app.app.link',
    'https://autonomy-app-alternate.app.link',
    'https://link.autonomy.io',
    'https://feralfile-app.app.link',
    'https://feralfile-app-alternate.app.link',
    'https://feralfile-app.test-app.link',
    'https://feralfile-app-alternate.test-app.link',
    'https://app.feralfile.com',
  ];

  static const wcPrefixes = [
    'https://au.bitmark.com/apps/wc?uri=',
    'https://au.bitmark.com/apps/wc/wc?uri=',
    'https://autonomy.io/apps/wc?uri=',
    'https://autonomy.io/apps/wc/wc?uri=',
    'autonomy://wc?uri=',
    'autonomy-wc://wc?uri=',
    'https://app.feralfile.com/apps/wc?uri=',
    'https://app.feralfile.com/apps/wc/wc?uri=',
    'feralfile://wc?uri=',
    'feralfile-wc://wc?uri=',
  ];

  static const tzPrefixes = [
    'https://au.bitmark.com/apps/tezos?uri=',
    'https://autonomy.io/apps/tezos?uri=',
    'https://feralfile.com/apps/tezos?uri=',
  ];

  static const wcDeeplinkPrefixes = [
    'wc:',
    'autonomy-wc:',
    'feralfile-wc:',
  ];

  static const tbDeeplinkPrefixes = [
    'tezos://',
    'autonomy-tezos://',
    'feralfile-tezos://',
  ];

  static const postcardPayToMintPrefixes = [
    'https://autonomy.io/apps/moma-postcards/purchase',
  ];

  static const navigationPrefixes = [
    'feralfile://navigation/',
  ];

  static const dAppConnectPrefixes = [
    ...wcPrefixes,
    ...tzPrefixes,
    ...wcDeeplinkPrefixes,
    ...tbDeeplinkPrefixes,
    ...postcardPayToMintPrefixes,
    ...navigationPrefixes,
  ];
}

Map<String, String> specifiedSeriesTitle = {
  'faa810f7-7b75-4c02-bf8a-b7447a89c921':
      ExtendedArtworkModel.interactiveInstruction.title,
};

class LinkType {
  static const local = 'Local Deep Link';
  static const dAppConnect = 'Dapp Connect Deeplink';
  static const feralFile = 'FeralFile Deeplink';
  static const branch = 'Branch Deeplink';
  static const beaconConnect = 'Beacon Connect';
  static const feralFileToken = 'FeralFile Token';
  static const walletConnect = 'Wallet Connect';
  static const postcardPayToMint = 'Postcard Pay To Mint';
  static const undefined = 'Undefined';
}

class SocialApp {
  static String twitter = 'twitter';
  static String twitterPrefix = 'https://twitter.com/intent/tweet';
}

class KeyChain {
  static String device = 'device_keychain'.tr();
  static String cloud = 'cloud_keychain'.tr();
}

class IrlWebviewFunction {
  static String closeWebview = '_closeWebview';
}

const chatPrivateBannerId = 'chat_private_banner_id';
final chatPrivateBannerMessage = SystemMessage(
  id: chatPrivateBannerId,
  author: const User(id: chatPrivateBannerId),
  createdAt: 0,
  text: 'chat_is_private'.tr(),
  status: Status.delivered,
);
