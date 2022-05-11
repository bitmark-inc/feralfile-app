import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/credentials.dart';

// TODO:
abstract class FeralFileService {
  Future<FFAccount> getAccount(String token);

  Future<FFAccount> getWeb3Account(WalletStorage wallet);

  Future<List<AssetPrice>> getAssetPrices(List<String> ids);
}

class FeralFileServiceImpl extends FeralFileService {
  FeralFileApi _feralFileApi;

  FeralFileServiceImpl(this._feralFileApi);

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
