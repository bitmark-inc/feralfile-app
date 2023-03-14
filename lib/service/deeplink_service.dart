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
import 'package:autonomy_flutter/service/postcard_service.dart';
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
  final PostcardService _postcardService;

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
    this._postcardService,
  );

  final metricClient = injector<MetricClientService>();

  @override
  Future setup() async {
    FlutterBranchSdk.initSession().listen((data) async {
      log.info("[DeeplinkService] _handleFeralFileDeeplink with Branch");
      _addScanQREvent(link: "", linkType: "", prefix: "", addData: data);
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

    Timer.periodic(delay, (timer) async {
      timer.cancel();
      _deepLinkHandleClock("Handle Deep Link Time Out", link);
      await _handleLocalDeeplink(link) ||
          await _handleDappConnectDeeplink(link) ||
          await _handleFeralFileDeeplink(link) ||
          await _handleBranchDeeplink(link);
      handlingDeepLink = null;
    });
  }

  Future _addScanQREvent(
      {required String link,
      required String linkType,
      required String prefix,
      Map<dynamic, dynamic> addData = const {}}) async {
    final uri = Uri.parse(link);
    final uriData = uri.queryParameters;
    final data = {
      "link": link,
      'linkType': linkType,
      "prefix": prefix,
    };
    data.addAll(uriData);
    data.addAll(addData.map((key, value) => MapEntry(key, value.toString())));

    metricClient.addEvent(MixpanelEvent.scanQR, data: data);
  }

  Future<bool> _handleLocalDeeplink(String link) async {
    log.info("[DeeplinkService] _handleLocalDeeplink");
    const deeplink = "autonomy://";

    if (link.startsWith(deeplink)) {
      final data = link.replacePrefix(deeplink, "");

      metricClient.addEvent(MixpanelEvent.scanQR, data: {
        "link": link,
        'linkType': LinkType.local,
        "prefix": deeplink,
        'data': data
      });

      if (!_configurationService.isDoneOnboarding()) {
        // Local deeplink should only available after onboarding.
        return false;
      }

      switch (data) {
        case "home":
          _navigationService.restorablePushHomePage();
          break;
        case "editorial":
          memoryValues.homePageInitialTab = HomePageTab.EDITORIAL;
          _navigationService.restorablePushHomePage();
          break;
        case "discover":
          memoryValues.homePageInitialTab = HomePageTab.DISCOVER;
          _navigationService.restorablePushHomePage();
          break;
        case "support":
          _navigationService.navigateTo(AppRouter.supportCustomerPage);
          break;
        default:
          return false;
      }
      return true;
    }

    return false;
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
      _addScanQREvent(
          link: link, linkType: LinkType.dAppConnect, prefix: callingWCPrefix);
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
      _addScanQREvent(
          link: link, linkType: LinkType.dAppConnect, prefix: callingTBPrefix);
      final tzUri = link.substring(callingTBPrefix.length);
      await _tezosBeaconService.addPeer(tzUri);
      return true;
    }

    final callingWCDeeplinkPrefix = wcDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingWCDeeplinkPrefix != null) {
      _addScanQREvent(
          link: link,
          linkType: LinkType.dAppConnect,
          prefix: callingWCDeeplinkPrefix);
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
      _addScanQREvent(
          link: link,
          linkType: LinkType.dAppConnect,
          prefix: callingTBDeeplinkPrefix);
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
      _addScanQREvent(
          link: link,
          linkType: LinkType.feralFile,
          prefix: FF_TOKEN_DEEPLINK_PREFIX);
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
    final callingBranchDeepLinkPrefix = Constants.branchDeepLinks
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingBranchDeepLinkPrefix != null) {
      final response = await _branchApi.getParams(Environment.branchKey, link);
      _addScanQREvent(
          link: link,
          linkType: LinkType.branch,
          prefix: callingBranchDeepLinkPrefix,
          addData: response["data"]);
      _handleBranchDeeplinkData(response["data"]);
      return true;
    }
    return false;
  }

  Future<void> _handleBranchDeeplinkData(Map<dynamic, dynamic> data) async {
    data['source'] = "Postcard";
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
          _navigationService.showAirdropExpired(artworkId);
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
      case "Postcard":
        final String? sharedCode = data["shared_code"] ?? "shared_code";
        if (sharedCode != null) {
          log.info("[DeeplinkService] _handlePostcardDeeplink $sharedCode");
          await _handlePostcardDeeplink(sharedCode);
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
          await _navigationService.showAirdropExpired(artworkId);
        } else if (artwork.airdropInfo?.isAirdropStarted != true) {
          await _navigationService.showAirdropNotStarted(artworkId);
        } else if (artwork.airdropInfo?.remainAmount == 0) {
          await _navigationService.showNoRemainingToken(
            artwork: artwork,
          );
        } else if (otp?.isExpired == true) {
          await _navigationService.showOtpExpired(artworkId);
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
      configurationService.setOldUser();
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
        injector<MetricClientService>().mixPanelClient.initIfDefaultAccount();
        injector<NavigationService>()
            .navigateTo(AppRouter.homePageNoTransition);
      }
    }
  }

  _handlePostcardDeeplink(String shareCode) async {
    final sharedInfor =
        await _postcardService.getSharedPostcardInfor(shareCode);
    if (sharedInfor != null) {
      final postcard = await _postcardService.getPostcard(sharedInfor.tokenId);
      if (postcard != null) {
        _navigationService.openPostcardReceivedPage(
            asset: postcard,
            shareId: sharedInfor.shareId,
            counter: sharedInfor.counter);
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
