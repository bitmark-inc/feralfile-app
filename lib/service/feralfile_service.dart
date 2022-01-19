import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/app_config.dart';
import 'package:autonomy_flutter/gateway/bitmark_api.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/model/asset.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/bitmark.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';

abstract class FeralFileService {
  Future<void> saveAccount();

  String getAccountNumber();

  Future<List<Asset>> getFeralFileAssets();

  Future<List<Provenance>> getAssetProvenance(String id);

  Future<List<AssetPrice>> getAssetPrices(List<String> ids);
}

class FeralFileServiceImpl extends FeralFileService {
  ConfigurationService _configurationService;
  FeralFileApi _feralFileApi;
  BitmarkApi _bitmarkApi;
  IndexerApi _indexerApi;
  EthereumService _ethereumService;

  FeralFileServiceImpl(this._configurationService, this._feralFileApi,
      this._bitmarkApi, this._indexerApi, this._ethereumService);

  @override
  String getAccountNumber() {
    return _configurationService.getAccount()?.accountNumber ?? "";
  }

  @override
  Future<void> saveAccount() async {
    final token = await _getToken();

    final response = await _feralFileApi.getAccount("Bearer $token");

    final account = response["result"];
    if (account != null) {
      await _configurationService.setAccount(account);
    }
  }

  @override
  Future<List<Asset>> getFeralFileAssets() async {
    final accountNumber = getAccountNumber();
    final response = await _bitmarkApi.getBitmarkIDs(accountNumber, false);
    final List<String> bitmarkIds =
        response["bitmarks"]?.map((e) => e.id).toList() ?? [];

    return await _indexerApi.getNftTokens({"ids": bitmarkIds});
  }

  @override
  Future<List<Provenance>> getAssetProvenance(String id) async {
    final response = await _bitmarkApi.getBitmarkAssetInfo(id, true, true);
    return response["bitmark"]?.provenance ?? [];
  }

  @override
  Future<List<AssetPrice>> getAssetPrices(List<String> ids) async {
    final token = await _getToken();
    final response = await _feralFileApi.getAssetPrice("Bearer $token", { "editionIDs" : ids });

    return response["result"] ?? [];
  }

  Future<String> _getToken() async {
    final address = await _ethereumService.getETHAddress();
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final message = AppConfig.ffAuthorizationPrefix + timestamp;
    final signature = await _ethereumService
        .signPersonalMessage(Uint8List.fromList(utf8.encode(message)));
    final rawToken = "$address|$message|$signature";
    final bytes = utf8.encode(rawToken);
    return base64.encode(bytes);
  }
}
