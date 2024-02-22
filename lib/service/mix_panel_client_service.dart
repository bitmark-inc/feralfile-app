import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixPanelClientService {
  final AccountService _accountService;
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDatabase;

  MixPanelClientService(
      this._accountService, this._configurationService, this._cloudDatabase);

  late Mixpanel mixpanel;
  late Box configHiveBox;

  Future<void> initService() async {
    mixpanel = await Mixpanel.init(Environment.mixpanelKey,
        trackAutomaticEvents: true);
    // await _initIfDefaultAccount();
    mixpanel
      ..setLoggingEnabled(false)
      ..setUseIpAddressForGeolocation(true);

    mixpanel
        .getPeople()
        .set(MixpanelProp.subscription, SubscriptionStatus.free);
    mixpanel.getPeople().set(MixpanelProp.enableNotification,
        _configurationService.isNotificationEnabled() ?? false);
    mixpanel.registerSuperPropertiesOnce({
      MixpanelProp.client: 'Autonomy Wallet',
    });
    configHiveBox = await Hive.openBox(MIXPANEL_HIVE_BOX);
  }

  Future initIfDefaultAccount() async {
    final defaultAccount = await _accountService.getCurrentDefaultAccount();

    if (defaultAccount == null) {
      return;
    }
    final defaultDID = await defaultAccount.getAccountDID();
    final hashedUserID = '${sha256.convert(utf8.encode(defaultDID))}_test';
    final distinctId = await mixpanel.getDistinctId();
    if (hashedUserID != distinctId) {
      mixpanel.alias(hashedUserID, distinctId);
      final defaultAddress = await defaultAccount.getETHEip55Address();
      final hashedDefaultAddress =
          sha256.convert(utf8.encode(defaultAddress)).toString();

      mixpanel.identify(hashedUserID);
      mixpanel.getPeople().set(MixpanelProp.address, hashedDefaultAddress);
      mixpanel.getPeople().set(MixpanelProp.didKey, hashedUserID);
    }
  }

  Future reset() async {
    mixpanel.reset();
  }

  void timerEvent(String name) {
    mixpanel.timeEvent(name.snakeToCapital());
  }

  Future<void> trackEvent(
    String name, {
    String? message,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> hashedData = const {},
  }) async {
    if (!_configurationService.isAnalyticsEnabled()) {
      return;
    }

    // track with Mixpanel
    if (hashedData.isNotEmpty) {
      hashedData = hashedData.map((key, value) {
        final salt = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final valueWithSalt = '$value$salt';
        return MapEntry(
            key, sha256.convert(utf8.encode(valueWithSalt)).toString());
      });
    }
    var mixedData = Map<String, dynamic>.from(hashedData);
    if (message != null) {
      mixedData['message'] = message;
    }

    data.forEach((key, value) {
      mixedData[key] = value;
    });

    mixpanel.track(name.snakeToCapital(), properties: mixedData);
  }

  Future<void> sendData() async {
    try {
      await mixpanel.flush();
    } catch (e) {
      log(e.toString());
    }
  }

  // ignore: avoid_annotating_with_dynamic
  void setLabel(String prop, dynamic value) {
    mixpanel.getPeople().set(prop, value);
  }

  void incrementPropertyLabel(String prop, double value) {
    mixpanel.getPeople().increment(prop, value);
  }

  void onAddConnection(Connection connection) {
    if ([
      ConnectionType.beaconP2PPeer.rawValue,
      ConnectionType.dappConnect2.rawValue,
      ConnectionType.walletConnect2.rawValue
    ].contains(connection.connectionType)) {
      incrementPropertyLabel(
          MixpanelProp.connectedToMarket(connection.name), 1);
    }
  }

  void onRemoveConnection(Connection connection) {
    if ([
      ConnectionType.beaconP2PPeer.rawValue,
      ConnectionType.dappConnect2.rawValue,
      ConnectionType.walletConnect2.rawValue
    ].contains(connection.connectionType)) {
      incrementPropertyLabel(
          MixpanelProp.connectedToMarket(connection.name), -1);
    }
  }

  Future<void> onRestore() async {
    final connections = await _cloudDatabase.connectionDao.getConnections();
    for (var connection in connections) {
      onAddConnection(connection);
    }
  }

  Future<void> initConfigIfNeed(Map<String, dynamic> config) async {
    for (var entry in config.entries) {
      if (getConfig(entry.key) == null) {
        await setConfig(entry.key, entry.value);
      }
    }
  }

  // ignore: avoid_annotating_with_dynamic
  dynamic getConfig(String key, {dynamic defaultValue}) =>
      configHiveBox.get(key, defaultValue: defaultValue);

  // ignore: avoid_annotating_with_dynamic
  Future<void> setConfig(String key, dynamic value) async {
    await configHiveBox.put(key, value);
  }
}
