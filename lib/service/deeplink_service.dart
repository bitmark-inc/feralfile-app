//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/branch_api.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/util/dio_exception_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/stream_device_view.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:feralfile_app_tv_proto/models/canvas_device.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uni_links/uni_links.dart';

abstract class DeeplinkService {
  Future setup();

  void handleDeeplink(String? link, {Duration delay, Function? onFinished});

  void handleBranchDeeplinkData(Map<dynamic, dynamic> data);

  Future<void> openClaimEmptyPostcard(String id, {String? otp});
}

class DeeplinkServiceImpl extends DeeplinkService {
  final ConfigurationService _configurationService;
  final Wc2Service _walletConnect2Service;
  final TezosBeaconService _tezosBeaconService;
  final NavigationService _navigationService;
  final BranchApi _branchApi;
  final PostcardService _postcardService;
  final RemoteConfigService _remoteConfigService;

  String? currentExhibitionId;
  String? handlingDeepLink;

  final Map<String, bool> _deepLinkHandlingMap = {};

  DeeplinkServiceImpl(
    this._configurationService,
    this._walletConnect2Service,
    this._tezosBeaconService,
    this._navigationService,
    this._branchApi,
    this._postcardService,
    this._remoteConfigService,
  );

  final metricClient = injector<MetricClientService>();

  @override
  Future setup() async {
    await FlutterBranchSdk.init(enableLogging: true);
    FlutterBranchSdk.listSession().listen((data) async {
      log.info('[DeeplinkService] _handleFeralFileDeeplink with Branch');
      log.info('[DeeplinkService] data: $data');
      if (data['+clicked_branch_link'] == true &&
          _deepLinkHandlingMap[data['~referring_link']] == null) {
        _deepLinkHandlingMap[data['~referring_link']] = true;
        unawaited(_deepLinkHandleClock(
            'Handle Branch Deep Link Data Time Out', data['source']));
        await handleBranchDeeplinkData(data);
        handlingDeepLink = null;
      }
    }, onError: (error, stacktrace) {
      Sentry.captureException(error, stackTrace: stacktrace);
      log.warning('[DeeplinkService] InitBranchSession error: $error');
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
    Function? onFinished,
  }) {
    // return for case when FeralFile pass empty deeplink to return Autonomy
    if (link == 'autonomy://') {
      return;
    }

    if (link == null) {
      return;
    }

    log.info('[DeeplinkService] receive deeplink $link');

    Timer.periodic(delay, (timer) async {
      timer.cancel();
      if (_deepLinkHandlingMap[link] != null) {
        return;
      }
      unawaited(_deepLinkHandleClock('Handle Deep Link Time Out', link));
      _deepLinkHandlingMap[link] = true;
      await _handleLocalDeeplink(link) ||
          await _handleDappConnectDeeplink(link) ||
          await _handleBranchDeeplink(link) ||
          await _handleIRL(link);
      _deepLinkHandlingMap.remove(link);
      handlingDeepLink = null;
      memoryValues.irlLink.value = null;
      onFinished?.call();
    });
  }

  Future<bool> _handleLocalDeeplink(String link) async {
    log.info('[DeeplinkService] _handleLocalDeeplink');
    const deeplink = 'autonomy://';

    if (link.startsWith(deeplink)) {
      final data = link.replacePrefix(deeplink, '');
      if (!_configurationService.isDoneOnboarding()) {
        // Local deeplink should only available after onboarding.
        return false;
      }

      switch (data) {
        case 'home':
          _navigationService.restorablePushHomePage();
        case 'support':
          unawaited(
              _navigationService.navigateTo(AppRouter.supportCustomerPage));
        default:
          return false;
      }
      return true;
    }

    return false;
  }

  Future<bool> _handleDappConnectDeeplink(String link) async {
    log.info('[DeeplinkService] _handleDappConnectDeeplink');
    final wcPrefixes = [
      'https://au.bitmark.com/apps/wc?uri=',
      'https://au.bitmark.com/apps/wc/wc?uri=',
      // maybe something wrong with WC register; fix by this for now
      'https://autonomy.io/apps/wc?uri=',
      'https://autonomy.io/apps/wc/wc?uri=',
      'autonomy://wc?uri=',
      'autonomy-wc://wc?uri=',
      'https://app.feralfile.com/apps/wc?uri=',
      'https://app.feralfile.com/apps/wc/wc?uri=',
      'feralfile://wc?uri=',
      'feralfile-wc://wc?uri=',
    ];

    final tzPrefixes = [
      'https://au.bitmark.com/apps/tezos?uri=',
      'https://autonomy.io/apps/tezos?uri=',
      'https://feralfile.com/apps/tezos?uri=',
    ];

    final wcDeeplinkPrefixes = [
      'wc:',
      'autonomy-wc:',
      'feralfile-wc:',
    ];

    final tbDeeplinkPrefixes = [
      'tezos://',
      'autonomy-tezos://',
      'feralfile-tezos://',
    ];

    final postcardPayToMintPrefixes = [
      'https://autonomy.io/apps/moma-postcards/purchase',
    ];
    if (!_configurationService.isDoneOnboarding()) {
      memoryValues.deepLink.value = link;
      await injector<AccountService>().restoreIfNeeded();
    }
    // Check Universal Link

    final callingWCPrefix =
        wcPrefixes.firstWhereOrNull((prefix) => link.startsWith(prefix));

    if (callingWCPrefix != null) {
      final wcUri = link.substring(callingWCPrefix.length);
      final decodedWcUri = Uri.decodeFull(wcUri);
      await _walletConnect2Service.connect(decodedWcUri);
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
      final wcLink = link.replaceFirst(callingWCDeeplinkPrefix, 'wc:');
      await _walletConnect2Service.connect(wcLink);
      return true;
    }

    final callingTBDeeplinkPrefix = tbDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingTBDeeplinkPrefix != null) {
      await _tezosBeaconService.addPeer(link);
      if (_configurationService.isDoneOnboarding()) {
        unawaited(_navigationService.showContactingDialog());
      }
      return true;
    }

    final callingPostcardPayToMintPrefix = postcardPayToMintPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingPostcardPayToMintPrefix != null) {
      await _handlePayToMintDeepLink(link);
      return true;
    }
    memoryValues.deepLink.value = null;
    return false;
  }

  Future<void> _handlePayToMintDeepLink(String link) async {
    log.info('[DeeplinkService] _handlePayToMint');
    _deepLinkHandlingMap.remove(link);
    await _handlePayToMint();
  }

  Future<void> _handlePayToMint() async {
    if (!_remoteConfigService.getBool(
        ConfigGroup.payToMint, ConfigKey.enable)) {
      return;
    }
    final address = await _navigationService.navigateTo(
      AppRouter.postcardSelectAddressScreen,
      arguments: {
        'blockchain': 'Tezos',
        'onConfirm': (String address) async {
          _navigationService.goBack(result: address);
        },
        'withLinked': _remoteConfigService.getBool(
            ConfigGroup.payToMint, ConfigKey.allowViewOnly),
      },
    );
    if (address == null) {
      return;
    }
    final url =
        '${Environment.payToMintBaseUrl}/moma-postcard?address=$address';
    final response = (await _navigationService.goToIRLWebview(
            IRLWebScreenPayload(url,
                isPlainUI: true, statusBarColor: POSTCARD_BACKGROUND_COLOR)))
        as Map<String, dynamic>;

    if (response['result'] == true) {
      final previewURL = response['previewURL'];
      final title = response['title'];
      final address = response['address'];
      final tokenId = response['tokenId'];

      await _navigationService.navigateTo(AppRouter.payToMintPostcard,
          arguments: PayToMintRequest(
            claimID: '',
            previewURL: previewURL,
            name: title,
            address: address,
            tokenId: tokenId,
          ));
    }
  }

  Future<bool> _handleIRL(String link) async {
    log.info('[DeeplinkService] _handleIRL');
    memoryValues.irlLink.value = link;
    if (!_configurationService.isDoneOnboarding()) {
      await injector<AccountService>().restoreIfNeeded();
    }
    final irlPrefix = IRL_DEEPLINK_PREFIXES
        .firstWhereOrNull((element) => link.startsWith(element));
    if (irlPrefix != null) {
      final urlDecode = Uri.decodeFull(link.replaceFirst(irlPrefix, ''));

      final uri = Uri.tryParse(urlDecode);
      if (uri == null) {
        return false;
      }

      if (Environment.irlWhitelistUrls.isNotEmpty) {
        final validUrl = Environment.irlWhitelistUrls.any(
          (element) => uri.host.contains(element),
        );
        if (!validUrl) {
          return false;
        }
      }
      unawaited(_navigationService.navigateTo(AppRouter.irlWebView,
          arguments: IRLWebScreenPayload(urlDecode)));
      return true;
    }

    return false;
  }

  Future<bool> _handleBranchDeeplink(String link) async {
    log.info('[DeeplinkService] _handleBranchDeeplink');
    //star
    memoryValues.branchDeeplinkData.value = null;
    final callingBranchDeepLinkPrefix = Constants.branchDeepLinks
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingBranchDeepLinkPrefix != null) {
      final response = await _branchApi.getParams(Environment.branchKey, link);
      await handleBranchDeeplinkData(response['data']);
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
    final source = data['source'];
    switch (source) {
      case 'Postcard':
        final String? type = data['type'];
        final String? id = data['id'];
        final expiredAtData = data['expired_at'];
        final DateTime expiredAt = expiredAtData != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (int.tryParse(expiredAtData) ?? 0) * 1000)
            : DateTime.now().add(const Duration(days: 1));
        if (expiredAt.isBefore(DateTime.now())) {
          unawaited(_navigationService.showPostcardShareLinkExpired());
          break;
        }
        if (type == 'claim_empty_postcard' && id != null) {
          final requiredOTP = id == POSTCARD_ONSITE_REQUEST_ID;
          if (requiredOTP) {
            final otp = _getOtpFromBranchData(data);
            if (otp == null) {
              log.info('[DeeplinkService] MoMA onsite otp is null');
              return;
            }
            if (otp.isExpired) {
              log.info('[DeeplinkService] MoMA onsite otp is expired');
              unawaited(_navigationService.showPostcardQRCodeExpired());
              return;
            }
            unawaited(_handleClaimEmptyPostcardDeeplink(id, otp: otp.code));
          } else {
            unawaited(_handleClaimEmptyPostcardDeeplink(id));
          }
          return;
        }
        final String? sharedCode = data['share_code'];
        if (sharedCode != null) {
          log.info('[DeeplinkService] _handlePostcardDeeplink $sharedCode');
          await _handlePostcardDeeplink(sharedCode);
        }

      case 'autonomy_irl':
        final url = data['irl_url'];
        if (url != null) {
          log.info('[DeeplinkService] _handleIRL $url');
          await _handleIRL(url);
          memoryValues.irlLink.value = null;
        }

      case 'moma_postcard_purchase':
        await _handlePayToMint();

      case 'autonomy_connect':
        final wcUri = data['uri'];
        final decodedWcUri = Uri.decodeFull(wcUri);
        await _walletConnect2Service.connect(decodedWcUri);

      case 'feralfile_display':
        final payload = data['device'];
        final device = CanvasDevice.fromJson(payload);
        final canvasClient = injector<CanvasClientServiceV2>();
        final result = await canvasClient.addQrDevice(device);
        final isSuccessful = result != null;
        if (!_navigationService.context.mounted) {
          return;
        }
        if (isSuccessful) {
          if (CustomRouteObserver.currentRoute?.settings.name ==
              AppRouter.scanQRPage) {
            /// in case scan when open scanQRPage,
            /// scan with navigation home page does not go to this flow
            _navigationService.goBack(result: device);
          } else {
            await UIHelper.showFlexibleDialog(
              _navigationService.context,
              BlocProvider.value(
                value: injector<CanvasDeviceBloc>(),
                child: const StreamDeviceView(),
              ),
              isDismissible: true,
            );
          }
        }

      default:
        memoryValues.branchDeeplinkData.value = null;
    }
    _deepLinkHandlingMap.remove(data['~referring_link']);
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

  Future<void> _handlePostcardDeeplink(String shareCode) async {
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
      unawaited(_navigationService.openPostcardReceivedPage(
          asset: postcard, shareCode: sharedInfor.shareCode));
    } catch (e) {
      log.info('[DeeplinkService] _handlePostcardDeeplink error $e');
      if (e is DioException &&
          (e.response?.statusCode == StatusCode.notFound.value)) {
        unawaited(_navigationService.showPostcardShareLinkInvalid());
      }
    }
  }

  @override
  Future<void> openClaimEmptyPostcard(String id, {String? otp}) async {
    await _handleClaimEmptyPostcardDeeplink(id, otp: otp);
  }

  Future<void> _handleClaimEmptyPostcardDeeplink(String? id,
      {String? otp}) async {
    if (id == null) {
      return;
    }
    try {
      final claimRequest = await _postcardService
          .requestPostcard(RequestPostcardRequest(id: id, otp: otp));
      unawaited(_navigationService.navigateTo(
        AppRouter.claimEmptyPostCard,
        arguments: claimRequest,
      ));
    } catch (e) {
      log.info('[DeeplinkService] _handleClaimEmptyPostcardDeeplink error $e');
      if (e is DioException) {
        if (e.isPostcardClaimEmptyLimited) {
          unawaited(_navigationService.showPostcardClaimLimited());
          return;
        }
        if (e.isPostcardNotInMiami) {
          unawaited(_navigationService.showPostcardNotInMiami());
          return;
        }
      }
      if (otp == null) {
        unawaited(_navigationService.showPostcardRunOut());
      } else {
        unawaited(_navigationService.showPostcardQRCodeExpired());
      }
    }
  }
}

Otp? _getOtpFromBranchData(Map<dynamic, dynamic> json) {
  if (json.containsKey('otp')) {
    final otp = json['otp'];
    final expiredAt = int.tryParse(json['otp_expired_at']);
    return Otp(
      otp,
      expiredAt != null ? DateTime.fromMillisecondsSinceEpoch(expiredAt) : null,
    );
  }
  return null;
}

class SharedPostcardStatus {
  static String available = 'available';
  static String claimed = 'claimed';
}
