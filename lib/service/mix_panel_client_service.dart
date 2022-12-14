import 'dart:convert';
import 'dart:developer';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixPanelClientService {
  final AccountService _accountService;
  MixPanelClientService(this._accountService);

  late Mixpanel mixpanel;
  Future<void> initService() async {
    final currentDefaultAccount =
        await _accountService.getCurrentDefaultAccount();

    final defaultDID =
        await currentDefaultAccount?.getAccountDID() ?? 'unknown';
    final hashedUserID = sha256.convert(utf8.encode(defaultDID)).toString();

    final defaultAddress =
        await currentDefaultAccount?.getETHAddress() ?? "unknown";

    final hashedDefaultAddress =
        sha256.convert(utf8.encode(defaultAddress)).toString();

    mixpanel = await Mixpanel.init(Environment.mixpanelKey,
        trackAutomaticEvents: true);
    mixpanel.setLoggingEnabled(true);
    mixpanel.setUseIpAddressForGeolocation(true);

    mixpanel.identify(hashedUserID);
    mixpanel.getPeople().set("Address", hashedDefaultAddress);
    mixpanel.getPeople().set("Subscription", "Free");
    mixpanel.registerSuperPropertiesOnce({
      "client": "Autonomy Wallet",
    });
  }

  timerEvent(String name) {
    mixpanel.timeEvent(name);
  }

  Future<void> trackEvent(
    String name, {
    String? message,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> hashedData = const {},
  }) async {
    final configurationService = injector.get<ConfigurationService>();

    if (configurationService.isAnalyticsEnabled() == false) {
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
}
