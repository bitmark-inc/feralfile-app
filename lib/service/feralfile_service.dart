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
import 'package:autonomy_flutter/model/airdrop_data.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/tokens_service.dart';

abstract class FeralFileService {
  Future<Connection> linkFF(String token, {required bool delayLink});

  Future completeDelayedFFConnections();

  Future<FFAccount> getAccount(String token);

  Future<FFAccount> getWeb3Account(WalletStorage wallet);

  Future<List<AssetPrice>> getAssetPrices(List<String> ids);

  Future<FFArtwork> getAirdropArtworkFromExhibitionId(String id);

  Future<FFArtwork> getArtwork(String id);

  Future<bool> claimToken({
    required String artworkId,
    String? address,
    Otp? otp,
    bool delayed = false,
    Future<bool> Function(FFArtwork)? onConfirm,
  });

  Future<String?> getExhibitionIdFromTokenID(String tokenID);

  Future<FeralFileResaleInfo> getResaleInfo(String exhibitionID);

  Future<String?> getPartnerFullName(String exhibitionId);

  Future<Exhibition> getExhibition(String id);
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
      metricClient.addEvent(
        Survey.onboarding,
        message: 'Feral File Website',
      );
      injector<ConfigurationService>().setFinishedSurvey([Survey.onboarding]);
    }

    metricClient.addEvent(
      MixpanelEvent.linkFeralfile,
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
        .ethSignPersonalMessage(Uint8List.fromList(utf8.encode(message)));
    final rawToken = "$address|$message|$signature";
    final bytes = utf8.encode(rawToken);
    return base64.encode(bytes);
  }

  @override
  Future<FFArtwork> getAirdropArtworkFromExhibitionId(String id) async {
    final resp = await _feralFileApi.getExhibition(id);
    final exhibition = resp.result;
    final airdropArtworkId = exhibition.artworks
        ?.firstWhereOrNull((e) => e.settings?.isAirdrop == true)
        ?.id;
    if (airdropArtworkId != null) {
      final airdropArtwork = await _feralFileApi.getArtwork(airdropArtworkId);
      return airdropArtwork.result;
    } else {
      throw Exception("Not airdrop exhibition");
    }
  }

  @override
  Future<FFArtwork> getArtwork(String id) async {
    return (await _feralFileApi.getArtwork(id)).result;
  }

  @override
  Future<bool> claimToken(
      {required String artworkId,
      String? address,
      Otp? otp,
      bool delayed = false,
      Future<bool> Function(FFArtwork)? onConfirm}) async {
    log.info(
        "[FeralFileService] Claim token - artwork: $artworkId, delayed: $delayed");
    if (delayed) {
      memoryValues.airdropFFExhibitionId.value = AirdropQrData(
        artworkId: artworkId,
        otp: otp,
      );
      return false;
    }

    final artwork = await getArtwork(artworkId);

    if (artwork.airdropInfo == null ||
        artwork.airdropInfo?.endedAt?.isBefore(DateTime.now()) == true) {
      throw AirdropExpired();
    }

    if ((artwork.airdropInfo?.remainAmount ?? 0) > 0) {
      final accepted = await onConfirm?.call(artwork) ?? true;
      if (!accepted) {
        log.info("[FeralFileService] User refused claim token");
        return false;
      }
      final wallet = await _accountService.getDefaultAccount();
      final message =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final accountDID = await wallet.getAccountDID();
      final signature = await wallet.getAccountDIDSignature(message);
      final receiver = address ?? await wallet.getTezosAddress();
      Map<String, dynamic> body = {
        "claimer": accountDID,
        "timestamp": message,
        "signature": signature,
        "address": receiver,
        if (otp != null) ...{"airdropTOTPPasscode": otp.code}
      };
      final response = await _feralFileApi.claimArtwork(artwork.id, body);
      final indexer = injector<TokensService>();
      await indexer.reindexAddresses([receiver]);

      final indexerId =
          artwork.airdropInfo!.getTokenIndexerId(response.result.editionID);
      final tokens = await _fetchTokens(
        indexerId: indexerId,
        receiver: receiver,
      );
      if (tokens.isNotEmpty) {
        await indexer.setCustomTokens(tokens);
      } else {
        await indexer.setCustomTokens(
          [
            createPendingAssetToken(
              artwork: artwork,
              owner: receiver,
              tokenId: response.result.editionID,
            )
          ],
        );
      }
      return true;
    } else {
      throw NoRemainingToken();
    }
  }

  @override
  Future<Exhibition> getExhibition(String id) async {
    final resp = await _feralFileApi.getExhibition(id);
    return resp.result;
  }

  Future<List<AssetToken>> _fetchTokens({
    required String indexerId,
    required String receiver,
  }) async {
    try {
      final indexerApi = injector<IndexerApi>();
      final assets = await indexerApi.getNftTokens({
        "ids": [indexerId]
      });
      final tokens = assets
          .map((e) => AssetToken.fromAsset(e))
          .map((e) => e
            ..pending = true
            ..ownerAddress = receiver
            ..owners.putIfAbsent(receiver, () => 1)
            ..lastActivityTime = DateTime.now())
          .toList();
      return tokens;
    } catch (e) {
      log.info("[FeralFileService] Fetch token failed ($indexerId) $e");
      return [];
    }
  }

  @override
  Future<String?> getExhibitionIdFromTokenID(String tokenID) async {
    final artworkEditions = await _feralFileApi.getArtworkEditions(tokenID);
    final String? exhibitionID = artworkEditions.result.artwork.exhibition?.id;
    return exhibitionID;
  }

  @override
  Future<FeralFileResaleInfo> getResaleInfo(String exhibitionID) async {
    final resaleInfo = await _feralFileApi.getResaleInfo(exhibitionID);
    return resaleInfo.result;
  }

  @override
  Future<String?> getPartnerFullName(String exhibitionId) async {
    final exhibition = await _feralFileApi.getExhibition(exhibitionId);
    return exhibition.result.partner?.fullName;
  }
}
