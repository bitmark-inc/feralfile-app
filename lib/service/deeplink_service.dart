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
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/util/dio_exception_ext.dart';
import 'package:autonomy_flutter/util/gift_handler.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/models/canvas_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uni_links/uni_links.dart';

abstract class DeeplinkService {
  Future setup();

  void handleDeeplink(String? link, {Duration delay, Function? onFinished});

  void handleBranchDeeplinkData(Map<dynamic, dynamic> data);

  Future<void> openClaimEmptyPostcard(String id, {String? otp});

  void activateBranchDataListener();

  void activateDeepLinkListener();
}

class DeeplinkServiceImpl extends DeeplinkService {
  final ConfigurationService _configurationService;
  final Wc2Service _walletConnect2Service;
  final TezosBeaconService _tezosBeaconService;
  final NavigationService _navigationService;
  final BranchApi _branchApi;
  final PostcardService _postcardService;
  final RemoteConfigService _remoteConfigService;

  final Map<String, bool> _deepLinkHandlingMap = {};

  DeeplinkServiceImpl(
    this._configurationService,
    this._walletConnect2Service,
    this._tezosBeaconService,
    this._navigationService,
    this._branchApi,
    this._postcardService,
    this._remoteConfigService,
  ) {
    _branchDataStream = _branchDataStreamController.stream;
    _linkStream = _deepLinkStreamController.stream;
  }

  final StreamController<Map<dynamic, dynamic>> _branchDataStreamController =
      StreamController<Map<dynamic, dynamic>>();
  final StreamController<String> _deepLinkStreamController =
      StreamController<String>();

  late final Stream<Map<dynamic, dynamic>> _branchDataStream;
  late final Stream<String> _linkStream;

  @override
  Future setup() async {
    await FlutterBranchSdk.init(enableLogging: true);
    FlutterBranchSdk.listSession().listen((data) async {
      log.info('[DeeplinkService] _handleFeralFileDeeplink with Branch');
      log.info('[DeeplinkService] data: $data');
      log.info('[DeeplinkService] _deepLinkHandlingMap: $_deepLinkHandlingMap');
      if (data['+clicked_branch_link'] == true &&
          _deepLinkHandlingMap[data['~referring_link']] == null) {
        _deepLinkHandlingMap[data['~referring_link']] = true;

        _branchDataStreamController.add(data);
      }
    }, onError: (error, stacktrace) {
      Sentry.captureException(error, stackTrace: stacktrace);
      log.warning('[DeeplinkService] InitBranchSession error: $error');
    });

    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _deepLinkStreamController.add(initialLink);
      }

      linkStream.listen(handleDeeplink);
    } on PlatformException {
      //Ignore
    }
  }

  @override
  void activateBranchDataListener() {
    if (_branchDataStreamController.hasListener) {
      return;
    }
    _branchDataStream.listen(handleBranchDeeplinkData);
  }

  @override
  void activateDeepLinkListener() {
    if (_deepLinkStreamController.hasListener) {
      return;
    }
    _linkStream.listen(handleDeeplink);
  }

  @override
  void handleDeeplink(
    String? link, {
    Duration delay = Duration.zero,
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
      _deepLinkHandlingMap[link] = true;
      final handlerType = DeepLinkHandlerType.fromString(link);
      log.info('[DeeplinkService] handlerType $handlerType');
      switch (handlerType) {
        case DeepLinkHandlerType.branch:
          await _handleBranchDeeplink(link);
        case DeepLinkHandlerType.dAppConnect:
          await _handleDappConnectDeeplink(link);
        case DeepLinkHandlerType.irl:
          await _handleIRL(link);
        case DeepLinkHandlerType.unknown:
          unawaited(_navigationService.showUnknownLink());
      }
      _deepLinkHandlingMap.remove(link);
      onFinished?.call();
    });
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

    final navigationPrefixes = [
      'feralfile://navigation/',
    ];

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

    final callingNavigationPrefix = navigationPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingNavigationPrefix != null) {
      final navigationPath = link.replaceFirst(callingNavigationPrefix, '');
      await _navigationService.navigatePath(navigationPath);
      return true;
    }
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
            isPlainUI: true,
            statusBarColor: POSTCARD_BACKGROUND_COLOR,
            isDarkStatusBar: false))) as Map<String, dynamic>;

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
    final callingBranchDeepLinkPrefix = Constants.branchDeepLinks
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingBranchDeepLinkPrefix != null) {
      try {
        final response =
            await _branchApi.getParams(Environment.branchKey, link);
        await handleBranchDeeplinkData(response['data']);
      } catch (e) {
        log.info('[DeeplinkService] _handleBranchDeeplink error $e');
        await _navigationService.showCannotResolveBranchLink();
      }
      return true;
    }
    return false;
  }

  @override
  Future<void> handleBranchDeeplinkData(Map<dynamic, dynamic> data) async {
    final navigatePath = data['navigation_route'];
    if (navigatePath != null) {
      await _navigationService.navigatePath(navigatePath);
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
        }

      case 'moma_postcard_purchase':
        await _handlePayToMint();

      case 'autonomy_connect':
        final wcUri = data['uri'];
        final decodedWcUri = Uri.decodeFull(wcUri);
        await _walletConnect2Service.connect(decodedWcUri);

      case 'feralfile_display':
        final rawPayload = data['device'] as Map<dynamic, dynamic>;
        final Map<String, dynamic> payload = {};
        rawPayload.forEach((key, value) {
          payload[key.toString()] = value;
        });
        final device = CanvasDevice.fromJson(payload);
        final canvasClient = injector<CanvasClientServiceV2>();
        final result = await canvasClient.addQrDevice(device);
        final isSuccessful = result != null;
        if (!_navigationService.context.mounted) {
          return;
        }
        if (CustomRouteObserver.currentRoute?.settings.name ==
            AppRouter.scanQRPage) {
          /// in case scan when open scanQRPage,
          /// scan with navigation home page does not go to this flow
          _navigationService.goBack(result: result);
          if (!isSuccessful) {
            await _navigationService.showCannotConnectTv();
          } else {
            showInfoNotification(
              const Key('connected_to_canvas'),
              'connected_to_display'.tr(),
              addOnTextSpan: [
                TextSpan(
                  text: device.name,
                  style: Theme.of(_navigationService.context)
                      .textTheme
                      .ppMori400FFYellow14
                      .copyWith(color: AppColor.feralFileLightBlue),
                )
              ],
              frontWidget: SvgPicture.asset(
                'assets/images/checkbox_icon.svg',
                width: 24,
              ),
            );
          }
          break;
        }
        if (isSuccessful) {
          showInfoNotification(
            const Key('connected_to_canvas'),
            'connected_to_display'.tr(),
            addOnTextSpan: [
              TextSpan(
                text: device.name,
                style: Theme.of(_navigationService.context)
                    .textTheme
                    .ppMori400FFYellow14
                    .copyWith(color: AppColor.feralFileLightBlue),
              )
            ],
            frontWidget: SvgPicture.asset(
              'assets/images/checkbox_icon.svg',
              width: 24,
            ),
          );
        } else {
          await _navigationService.showCannotConnectTv();
        }

      case 'InstantPurchase':
        final url = data['callback_url'];
        final expiredAt = data['expired_at'];
        if (expiredAt != null) {
          final expiredAtDate =
              DateTime.fromMillisecondsSinceEpoch(int.tryParse(expiredAt) ?? 0);
          if (expiredAtDate.isBefore(DateTime.now())) {
            unawaited(_navigationService.showQRExpired());
            break;
          }
        }
        final instantToken = data['instant_purchase_token'];
        final purchaseToken = data['purchase_token'];
        if (url != null &&
            data['chain'] != null &&
            instantToken != null &&
            purchaseToken != null) {
          final chain = data['chain'].toString().toLowerCase();
          late String? primaryAddress;
          final addressService = injector<AddressService>();
          try {
            final primaryAddressInfo =
                await addressService.getPrimaryAddressInfo();
            if (primaryAddressInfo != null &&
                primaryAddressInfo.chain == chain) {
              log.info(
                  '[DeeplinkService] InstancePurchase: primary address found');
              primaryAddress =
                  await addressService.getAddress(info: primaryAddressInfo);
            } else {
              log.info('[DeeplinkService] '
                  'InstancePurchase: use address with most tokens');
              final addressWallets = await addressService.getAllAddress();
              addressWallets.removeWhere((element) =>
                  element.cryptoType.toLowerCase() != chain ||
                  element.isHidden);
              if (addressWallets.isEmpty) {
                primaryAddress = null;
              } else {
                if (addressWallets.length == 1) {
                  primaryAddress = addressWallets.first.address;
                } else {
                  final address =
                      await addressService.pickMostNftAddress(addressWallets);
                  primaryAddress = address.address;
                }
              }
            }
          } catch (e) {
            log.info('[DeeplinkService] get primary address error $e');
            primaryAddress = null;
          }
          _navigationService.popUntilHome();
          if (primaryAddress == null) {
            await _navigationService.addressNotFoundError();
          } else {
            final link =
                '$url&ba=$primaryAddress&ipt=$instantToken&pt=$purchaseToken';
            log.info('InstantPurchase: $link');
            await _navigationService.goToIRLWebview(IRLWebScreenPayload(link,
                isPlainUI: true,
                statusBarColor: AppColor.white,
                isDarkStatusBar: false));
          }
        }

      case 'gift_membership':
        final giftCode = data['gift_code'];
        await GiftHandler.handleGiftMembership(giftCode);

      default:
    }
    _deepLinkHandlingMap.remove(data['~referring_link']);
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

enum DeepLinkHandlerType {
  branch,
  dAppConnect,
  irl,
  unknown,
  ;

  static DeepLinkHandlerType fromString(String value) {
    if (Constants.dAppConnectPrefixes
        .any((prefix) => value.startsWith(prefix))) {
      return DeepLinkHandlerType.dAppConnect;
    }

    if (IRL_DEEPLINK_PREFIXES.any((prefix) => value.startsWith(prefix))) {
      return DeepLinkHandlerType.irl;
    }

    if (Constants.branchDeepLinks.any((prefix) => value.startsWith(prefix))) {
      return DeepLinkHandlerType.branch;
    }

    return DeepLinkHandlerType.unknown;
  }
}
