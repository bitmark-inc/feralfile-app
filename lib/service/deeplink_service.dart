//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';

abstract class DeeplinkService {
  Future setup();
}

class DeeplinkServiceImpl extends DeeplinkService {
  StreamSubscription? _streamSubscription;
  ConfigurationService _configurationService;
  WalletConnectService _walletConnectService;
  TezosBeaconService _tezosBeaconService;
  FeralFileService _feralFileService;
  NavigationService _navigationService;

  DeeplinkServiceImpl(
    this._configurationService,
    this._walletConnectService,
    this._tezosBeaconService,
    this._feralFileService,
    this._navigationService,
  );

  Future setup() async {
    try {
      final initialLink = await getInitialLink();
      _handleDeeplink(initialLink);

      _streamSubscription = linkStream.listen(_handleDeeplink);
    } on PlatformException {}
  }

  void _handleDeeplink(String? link) async {
    // return for case when FeralFile pass empty deeplink to return Autonomy
    if (link == "autonomy://") return;

    if (link == null) return;

    log.info("[DeeplinkService] receive deeplink $link");

    Timer.periodic(Duration(seconds: 2), (timer) async {
      final context = _navigationService.navigatorKey.currentContext;
      if (context == null) return;
      timer.cancel();

      _handleDappConnectDeeplink(link) ||
          await _handleFeralFileDeeplink(context, link);
    });
  }

  bool _handleDappConnectDeeplink(String link) {
    log.info("[DeeplinkService] _handleDappConnectDeeplink");
    final wcPrefixes = [
      "https://au.bitmark.com/apps/wc?uri=",
      "https://au.bitmark.com/apps/wc/wc?uri=", // maybe something wrong with WC register; fix by this for now
      "https://autonomy.io/apps/wc?uri=",
      "https://autonomy.io/apps/wc/wc?uri=",
    ];

    final tzPrefixes = [
      "https://au.bitmark.com/apps/tezos?uri=",
      "https://autonomy.io/apps/tezos?uri=",
    ];

    final wcDeeplinkPrefixes = [
      'wc:',
      'autonomy-wc:',
    ];

    final tbDeeplinkPrefixes = [
      "tezos://",
      "autonomy-tezos://",
    ];

    // Check Universal Link
    final callingWCPrefix =
        wcPrefixes.firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingWCPrefix != null) {
      final wcUri = link.substring(callingWCPrefix.length);
      final decodedWcUri = Uri.decodeFull(wcUri);
      _walletConnectService.connect(decodedWcUri);
      return true;
    }

    final callingTBPrefix =
        tzPrefixes.firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingTBPrefix != null) {
      final tzUri = link.substring(callingTBPrefix.length);
      _tezosBeaconService.addPeer(tzUri);
      return true;
    }

    final callingWCDeeplinkPrefix = wcDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingWCDeeplinkPrefix != null) {
      _walletConnectService.connect(link);
      return true;
    }

    final callingTBDeeplinkPrefix = tbDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingTBDeeplinkPrefix != null) {
      _tezosBeaconService.addPeer(link);
      return true;
    }

    return false;
  }

  Future<bool> _handleFeralFileDeeplink(
      BuildContext context, String link) async {
    log.info("[DeeplinkService] _handleFeralFileDeeplink");

    if (link.startsWith(FF_TOKEN_DEEPLINK_PREFIX)) {
      final doneOnboarding = _configurationService.isDoneOnboarding();

      final connection = await _feralFileService.linkFF(
        link.replacePrefix(FF_TOKEN_DEEPLINK_PREFIX, ""),
        delayLink: !doneOnboarding,
      );

      if (doneOnboarding) {
        UIHelper.showFFAccountLinked(context, connection.name);

        await Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
          _navigationService.popUntilHomeOrSettings();
        });
      } else {
        UIHelper.showFFAccountLinked(context, connection.name,
            inOnboarding: true);
      }

      return true;
    }

    return false;
  }
}
