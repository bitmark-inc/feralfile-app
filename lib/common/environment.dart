//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static const String openSeaApiKey = "";

  static String get indexerURL =>
      appTestnetConfig ? indexerTestnetURL : indexerMainnetURL;

  static String get web3RpcURL =>
      appTestnetConfig ? web3RpcTestnetURL : web3RpcMainnetURL;

  static int get web3ChainId =>
      appTestnetConfig ? web3TestnetChainId : web3MainnetChainId;

  static String get tezosNodeClientURL =>
      appTestnetConfig ? tezosNodeClientTestnetURL : tezosNodeClientMainnetURL;

  static String get bitmarkAPIURL =>
      appTestnetConfig ? bitmarkAPITestnetURL : bitmarkAPIMainnetURL;

  static String get feralFileAPIURL =>
      appTestnetConfig ? feralFileAPITestnetURL : feralFileAPIMainnetURL;

  static String get feralFileSecretKey =>
      appTestnetConfig ? feralFileSecretKeyTestnet : feralFileSecretKeyMainnet;

  static String get feralFileAssetURL =>
      appTestnetConfig ? feralFileAssetURLTestnet : feralFileAssetURLMainnet;

  static String get extensionSupportURL => appTestnetConfig
      ? extensionSupportTestnetURL
      : extensionSupportMainnetURL;

  static String get connectWebsocketURL => appTestnetConfig
      ? connectWebsocketTestnetURL
      : connectWebsocketMainnetURL;

  static String get auClaimSecretKey => dotenv.env['AU_CLAIM_SECRET_KEY'] ?? '';

  static String get tokenWebviewPrefix =>
      dotenv.env['TOKEN_WEBVIEW_PREFIX'] ?? '';

  static String get indexerMainnetURL =>
      dotenv.env['INDEXER_MAINNET_API_URL'] ?? '';

  static String get indexerTestnetURL =>
      dotenv.env['INDEXER_TESTNET_API_URL'] ?? '';

  static String get web3RpcMainnetURL =>
      dotenv.env['WEB3_RPC_MAINNET_URL'] ?? '';

  static int get web3MainnetChainId =>
      int.tryParse(dotenv.env['WEB3_MAINNET_CHAIN_ID'] ?? "1") ?? 1;

  static String get web3RpcTestnetURL =>
      dotenv.env['WEB3_RPC_TESTNET_URL'] ?? '';

  static int get web3TestnetChainId =>
      int.tryParse(dotenv.env['WEB3_TESTNET_CHAIN_ID'] ?? "5") ?? 5;

  static String get tezosNodeClientMainnetURL =>
      dotenv.env['TEZOS_NODE_CLIENT_MAINNET_URL'] ?? '';

  static String get tezosNodeClientTestnetURL =>
      dotenv.env['TEZOS_NODE_CLIENT_TESTNET_URL'] ?? '';

  static String get bitmarkAPIMainnetURL =>
      dotenv.env['BITMARK_API_MAINNET_URL'] ?? '';

  static String get bitmarkAPITestnetURL =>
      dotenv.env['BITMARK_API_TESTNET_URL'] ?? '';

  static String get feralFileAPIMainnetURL =>
      dotenv.env['FERAL_FILE_API_MAINNET_URL'] ?? '';

  static String get feralFileSecretKeyMainnet =>
      dotenv.env['FERAL_FILE_SECRET_KEY_MAINNET'] ?? '';

  static String get feralFileAPITestnetURL =>
      dotenv.env['FERAL_FILE_API_TESTNET_URL'] ?? '';

  static String get feralFileSecretKeyTestnet =>
      dotenv.env['FERAL_FILE_SECRET_KEY_TESTNET'] ?? '';

  static String get feralFileAssetURLMainnet =>
      dotenv.env['FERAL_FILE_ASSET_URL_MAINNET'] ?? '';

  static String get feralFileAssetURLTestnet =>
      dotenv.env['FERAL_FILE_ASSET_URL_TESTNET'] ?? '';

  static String get extensionSupportMainnetURL =>
      dotenv.env['EXTENSION_SUPPORT_MAINNET_URL'] ?? '';

  static String get extensionSupportTestnetURL =>
      dotenv.env['EXTENSION_SUPPORT_TESTNET_URL'] ?? '';

  static String get connectWebsocketMainnetURL =>
      dotenv.env['CONNECT_WEBSOCKET_MAINNET_URL'] ?? '';

  static String get connectWebsocketTestnetURL =>
      dotenv.env['CONNECT_WEBSOCKET_TESTNET_URL'] ?? '';

  static String get autonomyAuthURL => dotenv.env['AUTONOMY_AUTH_URL'] ?? '';

  static String get feedURL => dotenv.env['FEED_URL'] ?? '';

  static String get customerSupportURL =>
      dotenv.env['CUSTOMER_SUPPORT_URL'] ?? '';

  static String get currencyExchangeURL =>
      dotenv.env['CURRENCY_EXCHANGE_URL'] ?? '';

  static String get pubdocURL => dotenv.env['AUTONOMY_PUBDOC_URL'] ?? '';

  static String get sentryDSN => dotenv.env['SENTRY_DSN'] ?? '';

  static String get onesignalAppID => dotenv.env['ONESIGNAL_APP_ID'] ?? '';

  static String get awsIdentityPoolId =>
      dotenv.env['AWS_IDENTITY_POOL_ID'] ?? '';

  static String get renderingReportURL =>
      dotenv.env['RENDERING_REPORT_URL'] ?? '';

  static String get autonomyIpfsPrefix =>
      dotenv.env['AUTONOMY_IPFS_PREFIX'] ?? '';

  static int? get pendingTokenExpireMs =>
      int.tryParse(dotenv.env['PENDING_TOKEN_EXPIRE_MS'] ?? "");

  static bool get appTestnetConfig =>
      dotenv.env['APP_TESTNET_CONFIG']?.toUpperCase() == "TRUE";

  static String get metricEndpoint => dotenv.env['METRIC_ENDPOINT'] ?? '';

  static String get metricSecretKey => dotenv.env['METRIC_SECRET_KEY'] ?? '';

  static String get branchKey => dotenv.env['BRANCH_KEY'] ?? '';

  static String get mixpanelKey => dotenv.env['MIXPANEL_KEY'] ?? '';

  static String get auClaimAPIURL => dotenv.env['AU_CLAIM_API_URL'] ?? '';

  static List<String> get irlWhitelistUrls =>
      dotenv.env['IRL_WHITELIST_URL']?.split(',') ?? [];

  static String get cloudFlareImageUrlPrefix =>
      dotenv.env['CLOUD_FLARE_IMAGE_URL_PREFIX'] ?? '';

  static String get postcardContractAddress =>
      dotenv.env['POSTCARD_CONTRACT_ADDRESS'] ?? '';

  static String get chatServerHmacKey =>
      dotenv.env['CHAT_SERVER_HMAC_KEY'] ?? '';

  static String get postcardChatServerUrl =>
      dotenv.env['CHAT_SERVER_URL'] ?? '';

  static String get tzktMainnetURL => dotenv.env['TZKT_MAINNET_URL'] ?? '';

  static String get tzktTestnetURL => dotenv.env['TZKT_TESTNET_URL'] ?? '';

  static String get autonomyAirdropURL =>
      dotenv.env['AUTONOMY_AIRDROP_URL'] ?? '';

  static String get autonomyAirDropContractAddress =>
      dotenv.env['AUTONOMY_AIRDROP_CONTRACT_ADDRESS'] ?? '';

  static String get autonomyActivationURL =>
      dotenv.env['AUTONOMY_ACTIVATION_URL'] ?? '';
}

class Secret {
  static String get ffAuthorizationPrefix =>
      dotenv.env['FERAL_FILE_AUTHORIZATION_PREFIX'] ?? '';
}
