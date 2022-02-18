import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/app_config.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/gateway/bitmark_api.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/bitmark.dart';
import 'package:autonomy_flutter/model/blockchain.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';

// TODO:
abstract class FeralFileService {
  Future<void> saveAccount();

  Future<FFAccount> getAccount(String token);

  String getAccountNumber();

  Future requestIndex();

  Future<Map<Blockchain, List<AssetToken>>> getNftAssets();

  Future<List<Provenance>> getAssetProvenance(String id);

  Future<List<AssetPrice>> getAssetPrices(List<String> ids);
}

class FeralFileServiceImpl extends FeralFileService {
  ConfigurationService _configurationService;
  FeralFileApi _feralFileApi;
  BitmarkApi _bitmarkApi;
  IndexerApi _indexerApi;
  EthereumService _ethereumService;
  TezosService _tezosService;
  AppDatabase _appDatabase;

  FeralFileServiceImpl(
      this._configurationService,
      this._feralFileApi,
      this._bitmarkApi,
      this._indexerApi,
      this._ethereumService,
      this._tezosService,
      this._appDatabase);

  @override
  String getAccountNumber() {
    // TODO
    return "";
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
  Future<void> saveAccount() async {
    final token = await _getToken();

    final response = await _feralFileApi.getAccount("Bearer $token");

    final account = response["result"];
    if (account != null) {
      // await _configurationService.setAccount(account);
    }
  }

  @override
  Future requestIndex() async {
    // final ethAddress = await _ethereumService.getETHAddress();
    // await _indexerApi.requestIndex({"owner": ethAddress, "blockchain": "eth"});

    // final xtzAddress = await _tezosService.getTezosAddress();
    // await _indexerApi
    //     .requestIndex({"owner": xtzAddress, "blockchain": "tezos"});
  }

  @override
  Future<Map<Blockchain, List<AssetToken>>> getNftAssets() async {
    // final accountNumber = getAccountNumber();
    // final response = await _bitmarkApi.getBitmarkIDs(accountNumber, false);
    // final List<String> bitmarkIds =
    //     response["bitmarks"]?.map((e) => e.id).toList() ?? [];

    // final ffAssets = await _indexerApi.getNftTokens({"ids": bitmarkIds});
    // final ffAssetTokens = ffAssets.map((e) => AssetToken.fromAsset(e)).toList();

    // final ethAddress = await _ethereumService.getETHAddress();
    // final ethAssets = await _indexerApi.getNftTokensByOwner(ethAddress);
    // final ethAssetTokens =
    //     ethAssets.map((e) => AssetToken.fromAsset(e)).toList();

    // final xtzAddress = await _tezosService.getTezosAddress();
    // final xtzAssets = await _indexerApi.getNftTokensByOwner(xtzAddress);
    // final xtzAssetTokens =
    //     xtzAssets.map((e) => AssetToken.fromAsset(e)).toList();
    // try {
    //   await _appDatabase.assetDao
    //       .insertAssets(ffAssetTokens + ethAssetTokens + xtzAssetTokens);
    // } catch (err) {}

    // return {
    //   Blockchain.BITMARK: ffAssetTokens,
    //   Blockchain.ETHEREUM: ethAssetTokens,
    //   Blockchain.TEZOS: xtzAssetTokens,
    // };
    return {};
  }

  @override
  Future<List<Provenance>> getAssetProvenance(String id) async {
    final response = await _bitmarkApi.getBitmarkAssetInfo(id, true, true);
    return response["bitmark"]?.provenance ?? [];
  }

  @override
  Future<List<AssetPrice>> getAssetPrices(List<String> ids) async {
    final token = await _getToken();
    final response =
        await _feralFileApi.getAssetPrice("Bearer $token", {"editionIDs": ids});

    return response["result"] ?? [];
  }

  Future<String> _getToken() async {
    // final address = await _ethereumService.getETHAddress();
    // final timestamp =
    //     (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    // final message = AppConfig.ffAuthorizationPrefix + timestamp;
    // final signature = await _ethereumService
    //     .signPersonalMessage(Uint8List.fromList(utf8.encode(message)));
    // final rawToken = "$address|$message|$signature";
    // final bytes = utf8.encode(rawToken);
    // return base64.encode(bytes);
    return "";
  }
}
