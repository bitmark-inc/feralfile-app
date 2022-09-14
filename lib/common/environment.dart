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

  static String get tezosNodeClientURL =>
      appTestnetConfig ? tezosNodeClientTestnetURL : tezosNodeClientMainnetURL;

  static String get bitmarkAPIURL =>
      appTestnetConfig ? bitmarkAPITestnetURL : bitmarkAPIMainnetURL;

  static String get feralFileAPIURL =>
      appTestnetConfig ? feralFileAPITestnetURL : feralFileAPIMainnetURL;

  static String get extensionSupportURL =>
      appTestnetConfig ? extensionSupportTestnetURL : extensionSupportMainnetURL;

  static String get connectWebsocketURL =>
      appTestnetConfig ? connectWebsocketTestnetURL : connectWebsocketMainnetURL;

  static String get indexerMainnetURL =>
      dotenv.env['INDEXER_MAINNET_API_URL'] ?? '';

  static String get indexerTestnetURL =>
      dotenv.env['INDEXER_TESTNET_API_URL'] ?? '';

  static String get web3RpcMainnetURL =>
      dotenv.env['WEB3_RPC_MAINNET_URL'] ?? '';

  static String get web3RpcTestnetURL =>
      dotenv.env['WEB3_RPC_TESTNET_URL'] ?? '';

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

  static String get feralFileAPITestnetURL =>
      dotenv.env['FERAL_FILE_API_TESTNET_URL'] ?? '';

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

  static String get autonomyShardService =>
      dotenv.env['AUTONOMY_SHARD_SERVICE'] ?? '';
}

class Secret {
  static String get ffAuthorizationPrefix =>
      dotenv.env['FERAL_FILE_AUTHORIZATION_PREFIX'] ?? '';
}
