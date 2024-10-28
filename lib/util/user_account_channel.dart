import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:flutter/services.dart';

class UserAccountChannel {
  final MethodChannel _channel;

  UserAccountChannel()
      : _channel = Platform.isIOS
            ? const MethodChannel('migration_util')
            : const MethodChannel('backup');

  AddressInfo? _primaryAddress;

  Future<void> setPrimaryAddress(AddressInfo info) async {
    try {
      await _channel
          .invokeMethod('setPrimaryAddress', {'data': info.toString()});
      _primaryAddress = info;
    } catch (e) {
      log.info('setPrimaryAddress error: $e');
    }
  }

  Future<AddressInfo?> getPrimaryAddress() async {
    if (_primaryAddress != null) {
      return _primaryAddress;
    }
    try {
      final String data = await _channel.invokeMethod('getPrimaryAddress', {});
      final primaryAddressInfo = json.decode(data);
      _primaryAddress = AddressInfo.fromJson(primaryAddressInfo);
    } catch (e) {
      log.info('getPrimaryAddress error: $e');
      _primaryAddress = null;
    }
    return _primaryAddress;
  }

  Future<bool> clearPrimaryAddress() async {
    try {
      final result = await _channel.invokeMethod('clearPrimaryAddress', {});
      _primaryAddress = null;
      return result;
    } catch (e) {
      log.info('clearPrimaryAddress error', e);
      return false;
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
