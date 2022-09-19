//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:metric_client/metric_client.dart';
import 'package:nft_collection/nft_collection.dart';

// TODO:
abstract class FeralFileService {
  Future<Connection> linkFF(String token, {required bool delayLink});

  Future completeDelayedFFConnections();

  Future<FFAccount> getAccount(String token);

  Future<FFAccount> getWeb3Account(WalletStorage wallet);

  Future<List<AssetPrice>> getAssetPrices(List<String> ids);
}

class FeralFileServiceImpl extends FeralFileService {
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDB;
  final FeralFileApi _feralFileApi;

  FeralFileServiceImpl(
    this._configurationService,
    this._cloudDB,
    this._feralFileApi,
  );

  @override
  Future<Connection> linkFF(String token, {required bool delayLink}) async {
    log.info("[FeralFileService][start] linkFF");
    late Connection connection;

    try {
      final ffSource = Environment.feralFileAPIURL;
      final ffAccount = await getAccount(token);
      final alreadyLinkedAccount = (await _cloudDB.connectionDao
              .getConnectionsByAccountNumber(ffAccount.id))
          .firstOrNull;

      if (alreadyLinkedAccount != null) {
        throw AlreadyLinkedException(alreadyLinkedAccount);
      }

      connection = Connection.fromFFToken(token, ffSource, ffAccount);
    } on DioError catch (error) {
      final code = decodeErrorResponse(error);
      if (code == null) rethrow;

      final apiError = getAPIErrorCode(code);
      if (apiError == APIErrorCode.notLoggedIn) {
        throw InvalidDeeplink();
      }
      rethrow;
    }

    if (delayLink) {
      memoryValues.linkedFFConnections =
          (memoryValues.linkedFFConnections ?? []) + [connection];
    } else {
      await _cloudDB.connectionDao.insertConnection(connection);
      injector<NftCollectionBloc>()
          .tokensService
          .fetchTokensForAddresses(connection.accountNumbers);
    }

    // mark survey from FeralFile as referrer if user hasn't answerred
    final finishedSurveys = _configurationService.getFinishedSurveys();
    if (!finishedSurveys.contains(Survey.onboarding)) {
      await MetricClient.addEvent(
        Survey.onboarding,
        message: 'Feral File Website',
      );
      injector<ConfigurationService>().setFinishedSurvey([Survey.onboarding]);
    }

    await MetricClient.addEvent(
      "link_feralfile",
      hashedData: {"address": connection.accountNumber},
    );

    log.info("[FeralFileService][end] linkFF");
    return connection;
  }

  @override
  Future completeDelayedFFConnections() async {
    log.info("[FeralFileService][Start] completeDelayedFFConnections");
    for (var connection in memoryValues.linkedFFConnections ?? []) {
      final alreadyLinkedAccount = (await _cloudDB.connectionDao
              .getConnectionsByAccountNumber(connection.accountNumber))
          .firstOrNull;

      if (alreadyLinkedAccount == null) {
        await _cloudDB.connectionDao.insertConnection(connection);
      }
    }

    memoryValues.linkedFFConnections = [];
    log.info("[FeralFileService][Done] completeDelayedFFConnections");
  }

  @override
  Future<FFAccount> getAccount(String token) async {
    final response = await _feralFileApi.getAccount("Bearer $token");

    final ffAccount = response["result"];
    if (ffAccount == null) {
      throw Exception('Invalid response');
    }

    return ffAccount;
  }

  @override
  Future<FFAccount> getWeb3Account(WalletStorage wallet) async {
    final token = await _getToken(wallet);
    final response = await _feralFileApi.getAccount("Bearer $token");

    final ffAccount = response["result"];
    if (ffAccount == null) {
      throw Exception('Invalid response');
    }
    return ffAccount;
  }

  @override
  Future<List<AssetPrice>> getAssetPrices(List<String> ids) async {
    final response = await _feralFileApi.getAssetPrice({"editionIDs": ids});

    return response["result"] ?? [];
  }

  Future<String> _getToken(WalletStorage wallet) async {
    final address = await wallet.getETHEip55Address();
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final message = Secret.ffAuthorizationPrefix + timestamp;
    final signature = await wallet
        .signPersonalMessage(Uint8List.fromList(utf8.encode(message)));
    final rawToken = "$address|$message|$signature";
    final bytes = utf8.encode(rawToken);
    return base64.encode(bytes);
  }
}
