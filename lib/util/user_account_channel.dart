import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:flutter/services.dart';

class UserAccountChannel {
  final MethodChannel _channel;

  UserAccountChannel()
      : _channel = Platform.isIOS
            ? const MethodChannel('migration_util')
            : const MethodChannel('backup');

  Future<void> setPrimaryAddress(AddressInfo info) async {
    try {
      await _channel
          .invokeMethod('setPrimaryAddress', {'data': info.toString()});
    } catch (e) {
      log.info('setPrimaryAddress error: $e');
    }
  }

  Future<AddressInfo?> getPrimaryAddress() async {
    try {
      final String data = await _channel.invokeMethod('getPrimaryAddress', {});
      final primaryAddressInfo = json.decode(data);
      return AddressInfo.fromJson(primaryAddressInfo);
    } catch (e) {
      log.info('getPrimaryAddress error: $e');
    }
    return null;
  }

  Future<bool> clearPrimaryAddress() async {
    try {
      final result = await _channel.invokeMethod('clearPrimaryAddress', {});
      return result;
    } catch (e) {
      log.info('clearPrimaryAddress error', e);
      return false;
    }
  }

  Future<bool> didRegisterPasskey() async {
    final didRegister = await _channel.invokeMethod('didRegisterPasskey', {});
    return didRegister;
  }

  Future<bool> setDidRegisterPasskey(bool value) async {
    final didRegister = await _channel.invokeMethod('setDidRegisterPasskey', {
      'data': value,
    });
    return didRegister;
  }

  Future<void> setJWT(JWT jwt) async {
    try {
      await _channel.invokeMethod('setJWT', {'data': jsonEncode(jwt.toJson())});
    } catch (e) {
      log.info('setJWT error: $e');
    }
  }

  Future<JWT?> getJWT() async {
    try {
      log.info('getJWT from channel');
      final String? data = await _channel.invokeMethod('getJWT', {});
      final jwt = json.decode(data ?? '{}');
      return JWT.fromJson(jwt);
    } catch (e) {
      log.info('getJWT error: $e');
    }
    return null;
  }

  Future<void> clearJWT() async {
    try {
      await _channel.invokeMethod('clearJWT', {});
    } catch (e) {
      log.info('clearJWT error: $e');
    }
  }
}

class AddressInfo {
  final String uuid;
  final String chain;
  final int index;

  AddressInfo({required this.uuid, required this.chain, required this.index});

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'chain': chain,
        'index': index,
      };

  factory AddressInfo.fromJson(Map<String, dynamic> json) => AddressInfo(
        uuid: json['uuid'],
        chain: json['chain'],
        index: json['index'],
      );

  bool get isEthereum => chain == 'ethereum';

  @override
  String toString() => jsonEncode(toJson());

  WalletType get walletType {
    if (chain == 'ethereum') {
      return WalletType.Ethereum;
    } else if (chain == 'tezos') {
      return WalletType.Tezos;
    } else {
      throw UnsupportedError('Unsupported chain: $chain');
    }
  }
}
