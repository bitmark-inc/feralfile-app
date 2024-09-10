//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/encrypt_env/secrets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get indexerURL =>
      appTestnetConfig ? indexerTestnetURL : indexerMainnetURL;

  static String get web3RpcURL =>
      appTestnetConfig ? web3RpcTestnetURL : web3RpcMainnetURL;

  static int get web3ChainId =>
      appTestnetConfig ? web3TestnetChainId : web3MainnetChainId;

  static String get feralFileAPIURL =>
      appTestnetConfig ? feralFileAPITestnetURL : feralFileAPIMainnetURL;

  static String get feralFileSecretKey =>
      appTestnetConfig ? feralFileSecretKeyTestnet : feralFileSecretKeyMainnet;

  static String get feralFileAssetURL =>
      appTestnetConfig ? feralFileAssetURLTestnet : feralFileAssetURLMainnet;

  static String get tvCastApiUrl => dotenv.env['TV_CAST_API_URL'] ?? '';

  static String get tokenWebviewPrefix =>
      dotenv.env['TOKEN_WEBVIEW_PREFIX'] ?? '';

  static String get indexerMainnetURL =>
      dotenv.env['INDEXER_MAINNET_API_URL'] ?? '';

  static String get indexerTestnetURL =>
      dotenv.env['INDEXER_TESTNET_API_URL'] ?? '';

  static int get web3MainnetChainId =>
      int.tryParse(dotenv.env['WEB3_MAINNET_CHAIN_ID'] ?? '1') ?? 1;

  static String get web3RpcTestnetURL =>
      dotenv.env['WEB3_RPC_TESTNET_URL'] ?? '';

  static int get web3TestnetChainId =>
      int.tryParse(dotenv.env['WEB3_TESTNET_CHAIN_ID'] ?? '5') ?? 5;

  static String get tezosNodeClientTestnetURL =>
      dotenv.env['TEZOS_NODE_CLIENT_TESTNET_URL'] ?? '';

  static String get feralFileAPIMainnetURL =>
      dotenv.env['FERAL_FILE_API_MAINNET_URL'] ?? '';

  static String get feralFileAPITestnetURL =>
      dotenv.env['FERAL_FILE_API_TESTNET_URL'] ?? '';

  static String get feralFileAssetURLTestnet =>
      dotenv.env['FERAL_FILE_ASSET_URL_TESTNET'] ?? '';

  static String get feralFileAssetURLMainnet =>
      dotenv.env['FERAL_FILE_ASSET_URL_MAINNET'] ?? '';

  static String get autonomyAuthURL => dotenv.env['AUTONOMY_AUTH_URL'] ?? '';

  static String get customerSupportURL =>
      dotenv.env['CUSTOMER_SUPPORT_URL'] ?? '';

  static String get currencyExchangeURL =>
      dotenv.env['CURRENCY_EXCHANGE_URL'] ?? '';

  static String get pubdocURL => dotenv.env['AUTONOMY_PUBDOC_URL'] ?? '';

  static String get autonomyIpfsPrefix =>
      dotenv.env['AUTONOMY_IPFS_PREFIX'] ?? '';

  static int? get pendingTokenExpireMs =>
      int.tryParse(dotenv.env['PENDING_TOKEN_EXPIRE_MS'] ?? '');

  static bool get appTestnetConfig =>
      dotenv.env['APP_TESTNET_CONFIG']?.toUpperCase() == 'TRUE';

  static String get auClaimAPIURL => dotenv.env['AU_CLAIM_API_URL'] ?? '';

  static List<String> get irlWhitelistUrls =>
      dotenv.env['IRL_WHITELIST_URL']?.split(',') ?? [];

  static String get cloudFlareImageUrlPrefix =>
      dotenv.env['CLOUD_FLARE_IMAGE_URL_PREFIX'] ?? '';

  static String get postcardContractAddress =>
      dotenv.env['POSTCARD_CONTRACT_ADDRESS'] ?? '';

  static String get merchandiseBaseUrl =>
      dotenv.env['AUTONOMY_MERCHANDISE_BASE_URL'] ?? '';

  static String get merchandiseApiUrl =>
      dotenv.env['AUTONOMY_MERCHANDISE_API_URL'] ?? '';

  static String get payToMintBaseUrl =>
      dotenv.env['PAY_TO_MINT_BASE_URL'] ?? '';

  static String get postcardChatServerUrl =>
      dotenv.env['CHAT_SERVER_URL'] ?? '';

  static String get tzktMainnetURL => dotenv.env['TZKT_MAINNET_URL'] ?? '';

  static String get tzktTestnetURL => dotenv.env['TZKT_TESTNET_URL'] ?? '';

  static String get autonomyAirDropContractAddress =>
      dotenv.env['AUTONOMY_AIRDROP_CONTRACT_ADDRESS'] ?? '';

  static String get chatServerHmacKey =>
      cachedSecretEnv['CHAT_SERVER_HMAC_KEY'] ?? '';

  static String get metricSecretKey =>
      cachedSecretEnv['METRIC_SECRET_KEY'] ?? '';

  static String get branchKey => cachedSecretEnv['BRANCH_KEY'] ?? '';

  static String get mixpanelKey => cachedSecretEnv['MIXPANEL_KEY'] ?? '';

  static String get auClaimSecretKey =>
      cachedSecretEnv['AU_CLAIM_SECRET_KEY'] ?? '';

  static String get feralFileSecretKeyTestnet =>
      cachedSecretEnv['FERAL_FILE_SECRET_KEY_TESTNET'] ?? '';

  static String get feralFileSecretKeyMainnet =>
      cachedSecretEnv['FERAL_FILE_SECRET_KEY_MAINNET'] ?? '';

  static String get web3RpcMainnetURL =>
      cachedSecretEnv['WEB3_RPC_MAINNET_URL'] ?? '';

  static String get sentryDSN => cachedSecretEnv['SENTRY_DSN'] ?? '';

  static String get onesignalAppID => cachedSecretEnv['ONESIGNAL_APP_ID'] ?? '';

  static String get tvKey => cachedSecretEnv['TV_API_KEY'] ?? '';
}
