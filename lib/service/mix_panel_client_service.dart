import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixPanelClientService {
  final AccountService _accountService;
  final ConfigurationService _configurationService;

  MixPanelClientService(this._accountService, this._configurationService);

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

  MixpanelConfig getConfig() {
    return _configurationService.getMixpanelConfig();
  }

  Future<void> setConfig(MixpanelConfig config) async {
    await _configurationService.setMixpanelConfig(config);
  }
}

@JsonSerializable()
class MixpanelConfig {
  final int countUseAutonomyInWeek;
  final DateTime weekStartAt;

  MixpanelConfig({this.countUseAutonomyInWeek = 0, DateTime? weekStartAt})
      : weekStartAt = weekStartAt ?? DateTime.now().startDayOfWeek;

  Map<String, dynamic> toJson() => {
        'countUseAutonomyInWeek': countUseAutonomyInWeek,
        'weekStartAt': weekStartAt.millisecondsSinceEpoch,
      };

  factory MixpanelConfig.fromJson(Map<String, dynamic> json) {
    return MixpanelConfig(
        countUseAutonomyInWeek: json['countUseAutonomyInWeek'] ?? 0,
        weekStartAt: DateTime.fromMillisecondsSinceEpoch(
            json['weekStartAt'] ?? DateTime.now().millisecondsSinceEpoch));
  }

  MixpanelConfig copyWith(
      {int? countUseAutonomyInWeek, DateTime? weekStartAt}) {
    return MixpanelConfig(
      countUseAutonomyInWeek:
          countUseAutonomyInWeek ?? this.countUseAutonomyInWeek,
      weekStartAt: weekStartAt ?? this.weekStartAt,
    );
  }
}
