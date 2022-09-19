//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/social_recovery/setup/recovery_institutional_verify_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:uni_links/uni_links.dart';

abstract class DeeplinkService {
  Future setup();
}

class DeeplinkServiceImpl extends DeeplinkService {
  final ConfigurationService _configurationService;
  final WalletConnectService _walletConnectService;
  final TezosBeaconService _tezosBeaconService;
  final FeralFileService _feralFileService;
  final NavigationService _navigationService;

  DeeplinkServiceImpl(
    this._configurationService,
    this._walletConnectService,
    this._tezosBeaconService,
    this._feralFileService,
    this._navigationService,
  );

  @override
  Future setup() async {
    FlutterBranchSdk.initSession().listen((data) {
      log.info("[DeeplinkService] _handleFeralFileDeeplink with Branch");

      if (data["+clicked_branch_link"] == true) {
        final source = data["source"];
        if (source == "FeralFile") {
          final String? tokenId = data["token_id"];
          if (tokenId != null) {
            _linkFeralFileToken(tokenId);
          }
        }
      }
    }, onError: (error) {
      log.warning(
          '[DeeplinkService] InitBranchSession error: ${error.toString()}');
    });

    try {
      final initialLink = await getInitialLink();
      _handleDeeplink(initialLink);

      linkStream.listen(_handleDeeplink);
    } on PlatformException {
      //Ignore
    }
  }

  void _handleDeeplink(String? link) async {
    // return for case when FeralFile pass empty deeplink to return Autonomy
    if (link == "autonomy://") return;

    if (link == null) return;

    log.info("[DeeplinkService] receive deeplink $link");

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      timer.cancel();

      final validLink = _handleDappConnectDeeplink(link) ||
          await _handleFeralFileDeeplink(link) ||
          await _handleSendDeckToShardService(link) ||
          await _handleGetDeckToShardService(link);

      if (!validLink) throw InvalidDeeplink();
    });
  }

  bool _handleDappConnectDeeplink(String link) {
    log.info("[DeeplinkService] _handleDappConnectDeeplink");
    final wcPrefixes = [
      "https://au.bitmark.com/apps/wc?uri=",
      "https://au.bitmark.com/apps/wc/wc?uri=",
      // maybe something wrong with WC register; fix by this for now
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

  Future<bool> _handleFeralFileDeeplink(String link) async {
    log.info("[DeeplinkService] _handleFeralFileDeeplink");

    if (link.startsWith(FF_TOKEN_DEEPLINK_PREFIX)) {
      _linkFeralFileToken(link.replacePrefix(FF_TOKEN_DEEPLINK_PREFIX, ""));
      return true;
    }

    return false;
  }

  Future<void> _linkFeralFileToken(String tokenId) async {
    final doneOnboarding = _configurationService.isDoneOnboarding();

    final connection = await _feralFileService.linkFF(
      tokenId,
      delayLink: !doneOnboarding,
    );

    if (doneOnboarding) {
      _navigationService.showFFAccountLinked(connection.name);

      await Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
        _navigationService.popUntilHomeOrSettings();
      });
    } else {
      _navigationService.showFFAccountLinked(connection.name,
          inOnboarding: true);
    }
  }

  Future<bool> _handleSendDeckToShardService(String link) async {
    log.info("[DeeplinkService] _handleSendDeckToShardService");
    final uri = Uri.parse(link);

    if (uri.path == "/apps/social-recovery/set") {
      final code = uri.queryParameters['code'];
      final domain = uri.queryParameters['domain'];

      if (code == null || domain == null) {
        throw InvalidDeeplink();
      }

      await injector<NavigationService>()
          .navigatorKey
          .currentState
          ?.pushNamedAndRemoveUntil(
            AppRouter.recoveryInstitutionalVerifyPage,
            (route) =>
                route.settings.name !=
                AppRouter.recoveryInstitutionalVerifyPage,
            arguments: RecoveryVerifyPayload(code, domain),
          );
      // final context = injector<NavigationService>().navigatorKey.currentContext!;
      //
      // UIHelper.showInfoDialog(
      //   context,
      //   'Processing...',
      //   'Sending ShardDeck to $domain',
      //   autoDismissAfter: 5,
      //   isDismissible: false,
      // );
      //
      // await injector<SocialRecoveryService>()
      //     .sendDeckToShardService(domain, code);
      //
      // injector<NavigationService>().popUntilHomeOrSettings();

      return true;
    } else {
      return false;
    }
  }

  Future<bool> _handleGetDeckToShardService(String link) async {
    log.info("[DeeplinkService] _handleGetDeckToShardService");

    final uri = Uri.parse(link);
    if (uri.path == "/apps/social-recovery/get") {
      final code = uri.queryParameters['code'];
      final domain = uri.queryParameters['domain'];

      if (code == null ||
          domain == null ||
          (await injector<AccountService>().getCurrentDefaultAccount()) !=
              null) {
        throw InvalidDeeplink();
      }

      await injector<NavigationService>()
          .navigatorKey
          .currentState
          ?.pushNamedAndRemoveUntil(
            AppRouter.restoreInstitutionalVerifyPage,
            (route) =>
                route.settings.name != AppRouter.restoreInstitutionalVerifyPage,
            arguments: RecoveryVerifyPayload(code, domain),
          );

      // final context =
      //     injector<NavigationService>().navigatorKey.currentContext!;
      //
      // UIHelper.showInfoDialog(
      //   context,
      //   'Processing...',
      //   'Getting ShardDeck from $domain',
      //   isDismissible: false,
      // );
      //
      // late ShardDeck shardServiceDeck;
      // try {
      //   shardServiceDeck = await injector<SocialRecoveryService>()
      //       .requestDeckFromShardService(domain, code);
      // } catch (_) {
      //   Navigator.of(context).pop();
      //   rethrow;
      // }
      // await _configurationService
      //     .setCachedDeckFromShardService(shardServiceDeck);
      // await Future.delayed(SHOW_DIALOG_DURATION);
      //
      // final hasPlatformShards =
      //     await injector<SocialRecoveryService>().hasPlatformShards();
      // if (hasPlatformShards) {
      //   // try to restore from PlatformShards & ShardService's ShardDeck
      //   Navigator.of(context).pop();
      //   UIHelper.showInfoDialog(context, "RESTORING...",
      //       'Restoring your account with 2 shardDecks: Platform & ShardService');
      //   await Future.delayed(SHORT_SHOW_DIALOG_DURATION);
      //
      //   try {
      //     await injector<SocialRecoveryService>()
      //         .restoreAccountWithPlatformKey(shardServiceDeck);
      //     doneOnboardingRestore(context);
      //   } on SocialRecoveryMissingShard catch (_) {
      //     Navigator.of(context).pop();
      //     final theme = Theme.of(context);
      //     UIHelper.showDialog(
      //       context,
      //       "Error",
      //       Text("ShardDecks don't match.",
      //           style: theme.primaryTextTheme.bodyText1),
      //       submitButton: AuFilledButton(
      //           text: 'RESTORE WITH EMERGENCY CONTACT',
      //           onPress: () => Navigator.of(context).pushNamedAndRemoveUntil(
      //               AppRouter.restoreWithEmergencyContactPage,
      //               (route) =>
      //                   route.settings.name == AppRouter.onboardingPage)),
      //       closeButton: 'CLOSE',
      //     );
      //   } catch (_) {
      //     Navigator.of(context).pop();
      //     rethrow;
      //   }
      // } else {
      //   // missing platformShards, ask EC's ShardDeck to restore
      //   Navigator.of(context).pop();
      //   await injector<NavigationService>()
      //       .navigatorKey
      //       .currentState
      //       ?.pushNamedAndRemoveUntil(AppRouter.restoreWithEmergencyContactPage,
      //           (route) => route.settings.name == AppRouter.onboardingPage);
      // }

      return true;
    } else {
      return false;
    }
  }
}
