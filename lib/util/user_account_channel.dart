import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:flutter/services.dart';
import 'package:sentry/sentry.dart';

class UserAccountChannel {
  final MethodChannel _channel;

  UserAccountChannel()
      : _channel = Platform.isIOS
            ? const MethodChannel('migration_util')
            : const MethodChannel('backup');

  String? _userId;
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

  Future<bool> setUserId(String userId) async {
    try {
      await _channel.invokeMethod('setUserId', {'data': userId});
      _userId = userId;
      return true;
    } catch (e) {
      log.info('setUserId error', e);
      unawaited(Sentry.captureException(
        e,
        hint: Hint.withMap({
          'method': 'setUserId',
          'userId': userId,
        }),
      ));
      return false;
    }
  }

  Future<String?> getUserId() async {
    if (_userId != null) {
      return _userId!;
    }
    try {
      final userId = await _channel.invokeMethod('getUserId', {});
      _userId = userId;
      return _userId!;
    } catch (e) {
      log.info('getUserId error', e);
      return null;
    }
  }

  Future<void> clearUserId() async {
    try {
      await _channel.invokeMethod('clearUserId', {});
      _userId = null;
    } catch (e) {
      log.info('clearUserId error', e);
    }
  }

  Future<bool> didCreateUser() async {
    final userId = await getUserId();
    return userId != null;
  }

  Future<bool> didRegisterPasskey() async {
    if (Platform.isAndroid) {
      return injector<ConfigurationService>().didRegisterPasskey();
    }
    final didRegister = await _channel.invokeMethod('didRegisterPasskey', {});
    return didRegister;
  }

  Future<bool> setDidRegisterPasskey(bool value) async {
    if (Platform.isAndroid) {
      // for Android device, passkey is stored in Google Password Manager,
      // so it is not synced
      await injector<ConfigurationService>().setDidRegisterPasskey(value);
      return true;
    }
    final didRegister = await _channel.invokeMethod('setDidRegisterPasskey', {
      'data': value,
    });
    return didRegister;
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
