import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/services.dart';

class PrimaryAddressChannel {
  late final MethodChannel _channel;

  PrimaryAddressChannel() {
    if (Platform.isIOS) {
      _channel = const MethodChannel('migration_util');
    } else {
      _channel = const MethodChannel('backup');
    }
  }

  Future<void> setPrimaryAddress(AddressInfo info) async {
    try {
      await _channel.invokeMethod(
          'setPrimaryAddress', {'data': info.toString()});
    } catch (e) {
      log.warning('setPrimaryAddress error', e);
    }
  }

  Future<AddressInfo?> getPrimaryAddress() async {
    try {
      final String data = await _channel.invokeMethod('getPrimaryAddress', {});
      if (data.isEmpty) {
        return null;
      }
      final primaryAddressInfo = json.decode(data);
      return AddressInfo.fromJson(primaryAddressInfo);
    } catch (e) {
      log.warning('getPrimaryAddress error', e);
      return null;
    }
  }

  Future<bool> clearPrimaryAddress() async {
    try {
      final result = await _channel.invokeMethod('clearPrimaryAddress', {});
      return result;
    } catch (e) {
      log.warning('clearPrimaryAddress error', e);
      return false;
    }
  }
}

class AddressInfo {
  final String uuid;
  final String chain;
  final int index;

  AddressInfo(this.uuid, this.chain, this.index);

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'chain': chain,
        'index': index,
      };

  factory AddressInfo.fromJson(Map<String, dynamic> json) => AddressInfo(
        json['uuid'],
        json['chain'],
        json['index'],
      );

  bool get isEthereum => chain == 'ethereum';

  @override
  String toString() => jsonEncode(toJson());
}
