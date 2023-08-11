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
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/claim/activation/claim_activation_page.dart';
import 'package:autonomy_flutter/screen/claim/airdrop/claim_airdrop_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/activation_service.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
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
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uni_links/uni_links.dart';

import '../screen/app_router.dart';

abstract class DeeplinkService {
  Future setup();

  void handleDeeplink(String? link, {Duration delay});

  void handleBranchDeeplinkData(Map<dynamic, dynamic> data);
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
  final AirdropService _airdropService;
  final ActivationService _activationService;
  final IndexerService _indexerService;

  String? currentExhibitionId;
  String? handlingDeepLink;

  final Map<String, bool> _deepLinkHandlingMap = {};

  DeeplinkServiceImpl(
    this._configurationService,
    this._walletConnectService,
    this._walletConnect2Service,
    this._tezosBeaconService,
    this._feralFileService,
    this._navigationService,
    this._branchApi,
    this._postcardService,
    this._airdropService,
    this._activationService,
    this._indexerService,
  );

  final metricClient = injector<MetricClientService>();

  @override
  Future setup() async {
    FlutterBranchSdk.initSession().listen((data) async {
      log.info("[DeeplinkService] _handleFeralFileDeeplink with Branch");
      log.info("[DeeplinkService] data: $data");
      _addScanQREvent(link: "", linkType: "", prefix: "", addData: data);
      if (data["+clicked_branch_link"] == true &&
          _deepLinkHandlingMap[data["~referring_link"]] == null) {
        _deepLinkHandlingMap[data["~referring_link"]] = true;
        _deepLinkHandleClock(
            "Handle Branch Deep Link Data Time Out", data["source"]);
        await handleBranchDeeplinkData(data);
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
    if (_deepLinkHandlingMap[link] != null) return;

    log.info("[DeeplinkService] receive deeplink $link");

    Timer.periodic(delay, (timer) async {
      timer.cancel();
      _deepLinkHandleClock("Handle Deep Link Time Out", link);
      _deepLinkHandlingMap[link] = true;
      await _handleLocalDeeplink(link) ||
          await _handleDappConnectDeeplink(link) ||
          await _handleFeralFileDeeplink(link) ||
          await _handleBranchDeeplink(link) ||
          await _handleIRL(link);
      _deepLinkHandlingMap.remove(link);
      handlingDeepLink = null;
      memoryValues.irlLink.value = null;
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
      "autonomy://wc?uri=",
      "autonomy-wc://wc?uri=",
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
      await injector<AccountService>().restoreIfNeeded();
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
      final wcLink = link.replaceFirst(callingWCDeeplinkPrefix, "wc:");
      _addScanQREvent(
          link: link,
          linkType: LinkType.dAppConnect,
          prefix: callingWCDeeplinkPrefix);
      if (link.isAutonomyConnectUri) {
        await _walletConnect2Service.connect(wcLink);
      } else {
        await _walletConnectService.connect(wcLink);
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

  Future<bool> _handleIRL(String link) async {
    log.info("[DeeplinkService] _handleIRL");
    memoryValues.irlLink.value = link;
    if (!_configurationService.isDoneOnboarding()) {
      await injector<AccountService>().restoreIfNeeded();
    }
    if (link.startsWith(IRL_DEEPLINK_PREFIX)) {
      final urlDecode =
          Uri.decodeFull(link.replaceFirst(IRL_DEEPLINK_PREFIX, ''));

      final uri = Uri.tryParse(urlDecode);
      if (uri == null) return false;

      if (Environment.irlWhitelistUrls.isNotEmpty) {
        final validUrl = Environment.irlWhitelistUrls.any(
          (element) => uri.host.contains(element),
        );
        if (!validUrl) return false;
      }
      await _navigationService.navigateTo(AppRouter.irlWebView,
          arguments: urlDecode);
      return true;
    }

    return false;
  }

  Future<bool> _handleBranchDeeplink(String link) async {
    log.info("[DeeplinkService] _handleBranchDeeplink");
    //star
    memoryValues.branchDeeplinkData.value = null;
    final callingBranchDeepLinkPrefix = Constants.branchDeepLinks
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingBranchDeepLinkPrefix != null) {
      final response = await _branchApi.getParams(Environment.branchKey, link);
      _addScanQREvent(
          link: link,
          linkType: LinkType.branch,
          prefix: callingBranchDeepLinkPrefix,
          addData: response["data"]);
      handleBranchDeeplinkData(response["data"]);
      return true;
    }
    return false;
  }

  @override
  Future<void> handleBranchDeeplinkData(Map<dynamic, dynamic> data) async {
    final doneOnboarding = _configurationService.isDoneOnboarding();
    if (!doneOnboarding) {
      memoryValues.branchDeeplinkData.value = data;
      return;
    }
    final source = data["source"];
    switch (source) {
      case "FeralFile":
        final String? tokenId = data["token_id"];
        if (tokenId != null) {
          log.info("[DeeplinkService] _linkFeralFileToken $tokenId");
          await _linkFeralFileToken(tokenId);
        }
        memoryValues.branchDeeplinkData.value = null;
        break;
      case "FeralFile_AirDrop":
        final String? exhibitionId = data["exhibition_id"];
        final String? seriesId = data["series_id"];
        final String? expiredAt = data["expired_at"];

        if (expiredAt != null &&
            DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(expiredAt) ?? 0))) {
          log.info("[DeeplinkService] FeralFile Airdrop expired");
          _navigationService.showAirdropExpired(seriesId);
          break;
        }

        if (exhibitionId?.isNotEmpty == true || seriesId?.isNotEmpty == true) {
          _claimFFAirdropToken(
            exhibitionId: exhibitionId,
            seriesId: seriesId,
            otp: _getOtpFromBranchData(data),
          );
        }
        break;
      case "Postcard":
        final String? type = data["type"];
        final String? id = data["id"];
        final DateTime expiredAt = data['expired'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (int.tryParse(data['expired_at']) ?? 0) * 1000)
            : DateTime.now().add(const Duration(days: 1));
        if (expiredAt.isBefore(DateTime.now())) {
          _navigationService.showPostcardShareLinkExpired();
          break;
        }
        if (type == "claim_empty_postcard" && id != null) {
          _handleClaimEmptyPostcardDeeplink(id);
          return;
        }
        final String? sharedCode = data["share_code"];
        if (sharedCode != null) {
          log.info("[DeeplinkService] _handlePostcardDeeplink $sharedCode");
          await _handlePostcardDeeplink(sharedCode);
        } else {
          _navigationService.waitTooLongDialog();
        }
        break;
      case "autonomy_irl":
        final url = data["irl_url"];
        if (url != null) {
          log.info("[DeeplinkService] _handleIRL $url");
          await _handleIRL(url);
          memoryValues.irlLink.value = null;
        }
        break;
      case "autonomy_airdrop":
        final String? sharedCode = data["share_code"];
        if (sharedCode != null) {
          log.info("[DeeplinkService] _handlePostcardDeeplink $sharedCode");
          final sharedInfor = await _airdropService.claimShare(
            AirdropClaimShareRequest(shareCode: sharedCode),
          );
          final series =
              await _feralFileService.getSeries(sharedInfor.seriesID);
          _navigationService.navigateTo(
            AppRouter.claimAirdropPage,
            arguments: ClaimTokenPagePayload(
                claimID: "", shareCode: sharedInfor.shareCode, series: series),
          );
        } else {
          _navigationService.waitTooLongDialog();
        }
        break;

      case "Autonomy_Activation":
        final String? activationID = data["activationID"];
        final String? expiredAt = data["expired_at"];

        if (expiredAt != null &&
            DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(expiredAt) ?? 0))) {
          log.info("[DeeplinkService] FeralFile Airdrop expired");
          // _navigationService.showAirdropExpired(seriesId);
          break;
        }

        if (activationID?.isNotEmpty == true) {
          _handleActivationDeeplink(activationID, _getOtpFromBranchData(data));
        }
        break;
      default:
        memoryValues.branchDeeplinkData.value = null;
    }
    _deepLinkHandlingMap.remove(data["~referring_link"]);
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
    String? seriesId,
    Otp? otp,
  }) async {
    log.info(
        "[DeeplinkService] Claim FF Airdrop token. Exhibition $exhibitionId, otp: ${otp?.toJson()}");
    final id = "${exhibitionId}_${seriesId}_${otp?.code}";
    if (currentExhibitionId == id) {
      return;
    }
    try {
      currentExhibitionId = id;
      final doneOnboarding = _configurationService.isDoneOnboarding();
      if (doneOnboarding) {
        final seriesFuture = (seriesId?.isNotEmpty == true)
            ? _feralFileService.getSeries(seriesId!)
            : _feralFileService.getAirdropSeriesFromExhibitionId(exhibitionId!);

        await Future.delayed(const Duration(seconds: 1), () {
          _navigationService.popUntilHomeOrSettings();
        });

        final series = await seriesFuture;
        final endTime = series.airdropInfo?.endedAt;
        if (series.airdropInfo == null ||
            (endTime != null && endTime.isBefore(DateTime.now()))) {
          await _navigationService.showAirdropExpired(seriesId);
        } else if (series.airdropInfo?.isAirdropStarted != true) {
          await _navigationService.showAirdropNotStarted(seriesId);
        } else if (series.airdropInfo?.remainAmount == 0) {
          await _navigationService.showNoRemainingToken(
            series: series,
          );
        } else if (otp?.isExpired == true) {
          await _navigationService.showOtpExpired(seriesId);
        } else {
          Future.delayed(const Duration(seconds: 5), () {
            currentExhibitionId = null;
          });
          await _navigationService.openClaimTokenPage(
            series,
            otp: otp,
          );
        }
        currentExhibitionId = null;
      } else {
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

  _handlePostcardDeeplink(String shareCode) async {
    try {
      final sharedInfor =
          await _postcardService.getSharedPostcardInfor(shareCode);
      if (sharedInfor.status == SharedPostcardStatus.claimed) {
        await _navigationService.showAlreadyDeliveredPostcard();
        return;
      }
      final contractAddress = Environment.postcardContractAddress;
      final tokenId = 'tez-$contractAddress-${sharedInfor.tokenID}';
      final postcard = await _postcardService.getPostcard(tokenId);
      _navigationService.openPostcardReceivedPage(
          asset: postcard, shareCode: sharedInfor.shareCode);
    } catch (e) {
      log.info("[DeeplinkService] _handlePostcardDeeplink error $e");
      if (e is DioError &&
          (e.response?.statusCode == StatusCode.notFound.value)) {
        _navigationService.showPostcardShareLinkInvalid();
      }
    }
  }

  _handleClaimEmptyPostcardDeeplink(String? id) async {
    if (id == null) {
      return;
    }
    final claimRequest =
        await _postcardService.requestPostcard(RequestPostcardRequest(id: id));
    _navigationService.navigatorKey.currentState?.pushNamed(
      AppRouter.claimEmptyPostCard,
      arguments: claimRequest,
    );
  }

  _handleActivationDeeplink(String? activationID, Otp? otp) async {
    if (activationID == null) {
      return;
    }
    final activationInfo =
        await _activationService.getActivation(activationID: activationID);
    final indexerId = _activationService.getIndexerID(activationInfo.blockchain,
        activationInfo.contractAddress, activationInfo.tokenID);
    final request = QueryListTokensRequest(
      ids: [indexerId],
    );
    final assetToken = await _indexerService.getNftTokens(request);
    await _navigationService.openActivationPage(
      payload: ClaimActivationPagePayload(
        activationID: activationID,
        assetToken: assetToken.first,
        otp: otp!,
      ),
    );
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

class SharedPostcardStatus {
  static String available = "available";
  static String claimed = "claimed";
}
