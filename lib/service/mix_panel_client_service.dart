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
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixPanelClientService {
  final AccountService _accountService;
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDatabase;

  MixPanelClientService(
      this._accountService, this._configurationService, this._cloudDatabase);

  late Mixpanel mixpanel;

  Future<void> initService() async {
    mixpanel = await Mixpanel.init(Environment.mixpanelKey,
        trackAutomaticEvents: true);
    await initIfDefaultAccount();
    mixpanel.setLoggingEnabled(false);
    mixpanel.setUseIpAddressForGeolocation(true);

    mixpanel
        .getPeople()
        .set(MixpanelProp.subscription, SubscriptionStatus.free);
    mixpanel.getPeople().set(MixpanelProp.enableNotification,
        _configurationService.isNotificationEnabled() ?? false);
    mixpanel.registerSuperPropertiesOnce({
      MixpanelProp.client: "Autonomy Wallet",
    });
  }

  Future initIfDefaultAccount() async {
    final defaultAccount = await _accountService.getCurrentDefaultAccount();

    if (defaultAccount == null) {
      return;
    }
    final defaultDID = await defaultAccount.getAccountDID();
    final hashedUserID =
        '${sha256.convert(utf8.encode(defaultDID)).toString()}_test';
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

  timerEvent(String name) {
    mixpanel.timeEvent(name.snakeToCapital());
  }

  Future<void> trackEvent(
    String name, {
    String? message,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> hashedData = const {},
  }) async {
    if (_configurationService.isAnalyticsEnabled() == false) {
      return;
    }

    // track with Mixpanel
    if (hashedData.isNotEmpty) {
      hashedData = hashedData.map((key, value) {
        final salt = DateFormat("yyyy-MM-dd").format(DateTime.now()).toString();
        final valueWithSalt = "$value$salt";
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
      mixpanel.flush();
    } catch (e) {
      log(e.toString());
    }
  }

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

  MixpanelConfig? getConfig() {
    return _configurationService.getMixpanelConfig();
  }

  Future<void> setConfig(MixpanelConfig config) async {
    await _configurationService.setMixpanelConfig(config);
  }
}

@JsonSerializable()
class MixpanelConfig {
  final DateTime? editorialPeriodStart;
  final double? totalEditorialReading;

  MixpanelConfig({this.editorialPeriodStart, this.totalEditorialReading});

  Map<String, dynamic> toJson() => {
        "editorialPeriodStart": editorialPeriodStart?.toIso8601String(),
        "totalEditorialReading": totalEditorialReading,
      };

  factory MixpanelConfig.fromJson(Map<String, dynamic> json) {
    return MixpanelConfig(
      editorialPeriodStart: DateTime.tryParse(json['editorialPeriodStart']),
      totalEditorialReading: json['totalEditorialReading'],
    );
  }

  MixpanelConfig copyWith(
      {DateTime? editorialPeriodStart, double? totalEditorialReading}) {
    return MixpanelConfig(
      editorialPeriodStart: editorialPeriodStart ?? this.editorialPeriodStart,
      totalEditorialReading:
          totalEditorialReading ?? this.totalEditorialReading,
    );
  }
}
