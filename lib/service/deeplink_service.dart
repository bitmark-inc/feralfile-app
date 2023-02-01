//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/branch_api.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/airdrop_data.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_connect_ext.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uni_links/uni_links.dart';

import '../database/cloud_database.dart';
import '../screen/app_router.dart';
import '../util/migration/migration_util.dart';
import 'account_service.dart';
import 'audit_service.dart';
import 'backup_service.dart';
import 'iap_service.dart';

abstract class DeeplinkService {
  Future setup();

  void handleDeeplink(String? link, {Duration delay});
}

class DeeplinkServiceImpl extends DeeplinkService {
  final ConfigurationService _configurationService;
  final WalletConnectService _walletConnectService;
  final Wc2Service _walletConnect2Service;
  final TezosBeaconService _tezosBeaconService;
  final FeralFileService _feralFileService;
  final NavigationService _navigationService;
  final BranchApi _branchApi;

  String? currentExhibitionId;
  String? handlingDeepLink;

  DeeplinkServiceImpl(
    this._configurationService,
    this._walletConnectService,
    this._walletConnect2Service,
    this._tezosBeaconService,
    this._feralFileService,
    this._navigationService,
    this._branchApi,
  );

  @override
  Future setup() async {
    FlutterBranchSdk.initSession().listen((data) async {
      log.info("[DeeplinkService] _handleFeralFileDeeplink with Branch");

      if (data["+clicked_branch_link"] == true) {
        _deepLinkHandleClock(
            "Handle Branch Deep Link Data Time Out", data["source"]);
        await _handleBranchDeeplinkData(data);
        handlingDeepLink = null;
      }
    }, onError: (error) {
      log.warning(
          '[DeeplinkService] InitBranchSession error: ${error.toString()}');
    });

    try {
      final initialLink = await getInitialLink();
      handleDeeplink(initialLink);

      linkStream.listen(handleDeeplink);
    } on PlatformException {
      //Ignore
    }
  }

  @override
  void handleDeeplink(
    String? link, {
    Duration delay = const Duration(seconds: 2),
  }) {
    // return for case when FeralFile pass empty deeplink to return Autonomy
    if (link == "autonomy://") return;

    if (link == null) return;

    log.info("[DeeplinkService] receive deeplink $link");

    final metricClient = injector<MetricClientService>();
    metricClient.addEvent(MixpanelEvent.scanQR, hashedData: {"link": link});

    Timer.periodic(delay, (timer) async {
      timer.cancel();
      _deepLinkHandleClock("Handle Deep Link Time Out", link);
      await _handleDappConnectDeeplink(link) ||
          await _handleFeralFileDeeplink(link) ||
          await _handleBranchDeeplink(link);
      handlingDeepLink = null;
    });
  }

  Future<bool> _handleDappConnectDeeplink(String link) async {
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
    if (!_configurationService.isDoneOnboarding()) {
      memoryValues.deepLink.value = link;
      await _restoreIfNeeded();
    }
    // Check Universal Link
    final callingWCPrefix =
        wcPrefixes.firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingWCPrefix != null) {
      final wcUri = link.substring(callingWCPrefix.length);
      final decodedWcUri = Uri.decodeFull(wcUri);
      if (decodedWcUri.isAutonomyConnectUri) {
        await _walletConnect2Service.connect(decodedWcUri);
      } else {
        await _walletConnectService.connect(decodedWcUri);
      }
      return true;
    }

    final callingTBPrefix =
        tzPrefixes.firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingTBPrefix != null) {
      final tzUri = link.substring(callingTBPrefix.length);
      await _tezosBeaconService.addPeer(tzUri);
      return true;
    }

    final callingWCDeeplinkPrefix = wcDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingWCDeeplinkPrefix != null) {
      if (link.isAutonomyConnectUri) {
        await _walletConnect2Service.connect(link);
      } else {
        await _walletConnectService.connect(link);
      }
      return true;
    }

    final callingTBDeeplinkPrefix = tbDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingTBDeeplinkPrefix != null) {
      await _tezosBeaconService.addPeer(link);
      if (_configurationService.isDoneOnboarding()) {
        _navigationService.showContactingDialog();
      }
      return true;
    }
    memoryValues.deepLink.value = null;
    return false;
  }

  Future<bool> _handleFeralFileDeeplink(String link) async {
    log.info("[DeeplinkService] _handleFeralFileDeeplink");

    if (link.startsWith(FF_TOKEN_DEEPLINK_PREFIX)) {
      await _linkFeralFileToken(
          link.replacePrefix(FF_TOKEN_DEEPLINK_PREFIX, ""));
      return true;
    }

    return false;
  }

  Future<bool> _handleBranchDeeplink(String link) async {
    log.info("[DeeplinkService] _handleBranchDeeplink");
    //star
    memoryValues.airdropFFExhibitionId.value = AirdropQrData(
      exhibitionId: '',
      artworkId: '',
    );
    if (Constants.branchDeepLinks.any((prefix) => link.startsWith(prefix))) {
      final response = await _branchApi.getParams(Environment.branchKey, link);
      _handleBranchDeeplinkData(response["data"]);
      return true;
    }
    return false;
  }

  Future<void> _handleBranchDeeplinkData(Map<dynamic, dynamic> data) async {
    final source = data["source"];
    switch (source) {
      case "FeralFile":
        final String? tokenId = data["token_id"];
        if (tokenId != null) {
          log.info("[DeeplinkService] _linkFeralFileToken $tokenId");
          await _linkFeralFileToken(tokenId);
        }
        memoryValues.airdropFFExhibitionId.value = null;
        break;
      case "FeralFile_AirDrop":
        final String? exhibitionId = data["exhibition_id"];
        final String? artworkId = data["artwork_id"];
        final String? expiredAt = data["expired_at"];

        if (expiredAt != null &&
            DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(expiredAt) ?? 0))) {
          log.info("[DeeplinkService] FeralFile Airdrop expired");
          _navigationService.showAirdropExpired();
          break;
        }

        if (exhibitionId?.isNotEmpty == true || artworkId?.isNotEmpty == true) {
          _claimFFAirdropToken(
            exhibitionId: exhibitionId,
            artworkId: artworkId,
            otp: _getOtpFromBranchData(data),
          );
        }
        break;
      default:
        memoryValues.airdropFFExhibitionId.value = null;
    }
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

  Future _claimFFAirdropToken({
    String? exhibitionId,
    String? artworkId,
    Otp? otp,
  }) async {
    log.info(
        "[DeeplinkService] Claim FF Airdrop token. Exhibition $exhibitionId, otp: ${otp?.toJson()}");
    final id = "${exhibitionId}_${artworkId}_${otp?.code}";
    if (currentExhibitionId == id) {
      return;
    }
    try {
      currentExhibitionId = id;
      final doneOnboarding = _configurationService.isDoneOnboarding();
      if (doneOnboarding) {
        final artworkFuture = (artworkId?.isNotEmpty == true)
            ? _feralFileService.getArtwork(artworkId!)
            : _feralFileService
                .getAirdropArtworkFromExhibitionId(exhibitionId!);

        await Future.delayed(const Duration(seconds: 1), () {
          _navigationService.popUntilHomeOrSettings();
        });

        final artwork = await artworkFuture;
        final endTime = artwork.airdropInfo?.endedAt;
        if (artwork.airdropInfo == null ||
            (endTime != null && endTime.isBefore(DateTime.now()))) {
          await _navigationService.showAirdropExpired();
        } else if (artwork.airdropInfo?.isAirdropStarted != true) {
          await _navigationService.showAirdropNotStarted();
        } else if (artwork.airdropInfo?.remainAmount == 0) {
          await _navigationService.showNoRemainingToken(
            artwork: artwork,
          );
        } else if (otp?.isExpired == true) {
          await _navigationService.showOtpExpired();
        } else {
          Future.delayed(const Duration(seconds: 5), () {
            currentExhibitionId = null;
          });
          await _navigationService.openClaimTokenPage(
            artwork,
            otp: otp,
          );
        }
        currentExhibitionId = null;
      } else {
        memoryValues.airdropFFExhibitionId.value = AirdropQrData(
          exhibitionId: exhibitionId,
          artworkId: artworkId,
          otp: otp,
        );
        handlingDeepLink = null;
        await Future.delayed(const Duration(seconds: 5), () {
          currentExhibitionId = null;
        });
      }
    } catch (e) {
      log.info("[DeeplinkService] _claimFFAirdropToken error $e");
      currentExhibitionId = null;
    }
  }

  Future<void> _deepLinkHandleClock(String message, String param,
      {Duration duration = const Duration(seconds: 2)}) async {
    handlingDeepLink = message;
    Future.delayed(duration, () {
      if (handlingDeepLink != null) {
        Sentry.captureMessage(message,
            level: SentryLevel.warning, params: [param]);
      }
      handlingDeepLink = null;
    });
  }

  Future<void> _restoreIfNeeded() async {
    final configurationService = injector<ConfigurationService>();
    if (configurationService.isDoneOnboarding()) return;

    final cloudDB = injector<CloudDatabase>();
    final backupService = injector<BackupService>();
    final accountService = injector<AccountService>();
    final iapService = injector<IAPService>();
    final auditService = injector<AuditService>();
    final migrationUtil = MigrationUtil(configurationService, cloudDB,
        accountService, iapService, auditService, backupService);
    await accountService.androidBackupKeys();
    await migrationUtil.migrationFromKeychain();
    final personas = await cloudDB.personaDao.getPersonas();
    final connections = await cloudDB.connectionDao.getConnections();
    if (personas.isNotEmpty || connections.isNotEmpty) {
      final defaultAccount = await accountService.getDefaultAccount();
      final backupVersion =
          await backupService.fetchBackupVersion(defaultAccount);
      if (backupVersion.isNotEmpty) {
        backupService.restoreCloudDatabase(defaultAccount, backupVersion);
        for (var persona in personas) {
          if (persona.name != "") {
            persona.wallet().updateName(persona.name);
          }
        }
        await cloudDB.connectionDao.getUpdatedLinkedAccounts();
        configurationService.setDoneOnboarding(true);
        injector<NavigationService>()
            .navigateTo(AppRouter.homePageNoTransition);
      }
    }
  }
}

Otp? _getOtpFromBranchData(Map<dynamic, dynamic> json) {
  if (json.containsKey("otp")) {
    final otp = json["otp"];
    final expiredAt = int.tryParse(json["otp_expired_at"]);
    return Otp(
      otp,
      expiredAt != null ? DateTime.fromMillisecondsSinceEpoch(expiredAt) : null,
    );
  }
  return null;
}
