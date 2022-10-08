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
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:metric_client/metric_client.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/tokens_service.dart';

// TODO:
abstract class FeralFileService {
  Future<Connection> linkFF(String token, {required bool delayLink});

  Future completeDelayedFFConnections();

  Future<FFAccount> getAccount(String token);

  Future<FFAccount> getWeb3Account(WalletStorage wallet);

  Future<List<AssetPrice>> getAssetPrices(List<String> ids);

  Future<Exhibition> getExhibition(String id);

  Future<bool> claimToken({
    required String exhibitionId,
    String? address,
    bool delayed = false,
    Future<bool> Function(Exhibition)? onConfirm,
  });
}

class FeralFileServiceImpl extends FeralFileService {
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDB;
  final FeralFileApi _feralFileApi;
  final AccountService _accountService;

  FeralFileServiceImpl(
    this._configurationService,
    this._cloudDB,
    this._feralFileApi,
    this._accountService,
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
    final metricClient = injector.get<MetricClientService>();

    // mark survey from FeralFile as referrer if user hasn't answerred
    final finishedSurveys = _configurationService.getFinishedSurveys();
    if (!finishedSurveys.contains(Survey.onboarding)) {
      await metricClient.addEvent(
        Survey.onboarding,
        message: 'Feral File Website',
      );
      injector<ConfigurationService>().setFinishedSurvey([Survey.onboarding]);
    }

    await metricClient.addEvent(
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

  @override
  Future<Exhibition> getExhibition(String id) async {
    final resp = await _feralFileApi.getExhibition(id);
    return resp.result;
  }

  @override
  Future<bool> claimToken(
      {required String exhibitionId,
      String? address,
      bool delayed = false,
      Future<bool> Function(Exhibition)? onConfirm}) async {
    log.info(
        "[FeralFileService] Claim token - exhibitionId: $exhibitionId, delayed: $delayed");
    if (delayed) {
      memoryValues.airdropFFExhibitionId.value = exhibitionId;
      return false;
    }

    final exhibition = (await _feralFileApi.getExhibition(exhibitionId)).result;

    if (exhibition.airdropInfo == null ||
        exhibition.airdropInfo?.endedAt?.isBefore(DateTime.now()) == true) {
      throw AirdropExpired();
    }

    if ((exhibition.airdropInfo?.remainAmount ?? 0) > 0) {
      final accepted = await onConfirm?.call(exhibition) ?? true;
      if (!accepted) {
        log.info("[FeralFileService] User refused claim token");
        return false;
      }
      final wallet = await _accountService.getDefaultAccount();
      final message =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final accountDID = await wallet.getAccountDID();
      final signature = await wallet.getAccountDIDSignature(message);
      final receiver = address ?? (await wallet.getTezosWallet()).address;
      Map<String, dynamic> body = {
        "claimer": accountDID,
        "timestamp": message,
        "signature": signature,
        "address": receiver,
      };
      final response = await _feralFileApi.claimToken(exhibitionId, body);
      final indexer = injector<TokensService>();
      await indexer.reindexAddresses([receiver]);
      indexer.setCustomTokens(
        [
          createPendingAssetToken(
            exhibition: exhibition,
            owner: receiver,
            tokenId: response.result.editionID,
          )
        ],
      );
      return true;
    } else {
      throw NoRemainingToken();
    }
  }
}
