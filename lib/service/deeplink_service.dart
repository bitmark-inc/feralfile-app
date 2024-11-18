//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/branch_api.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/playlist_activation.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/activation/playlist_activation/playlist_activation_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class DeeplinkService {
  Future setup();

  void handleDeeplink(String? link, {Duration delay, Function? onFinished});

  void handleBranchDeeplinkData(Map<dynamic, dynamic> data);

  Future<void> openClaimEmptyPostcard(String id, {String? otp});

  Future<void> handleReferralCode(String referralCode);
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
  );

  @override
  Future setup() async {
    log.info('[DeeplinkService] setup');
    await FlutterBranchSdk.init(enableLogging: true);
    FlutterBranchSdk.listSession().listen((data) async {
      log.info('[DeeplinkService] _handleFeralFileDeeplink with Branch');
      log.info('[DeeplinkService] data: $data');
      log.info('[DeeplinkService] _deepLinkHandlingMap: $_deepLinkHandlingMap');
      if (data['+clicked_branch_link'] == true &&
          _deepLinkHandlingMap[data['~referring_link']] == null) {
        _deepLinkHandlingMap[data['~referring_link']] = true;

        await handleBranchDeeplinkData(data);
      }
    }, onError: (error, stacktrace) {
      Sentry.captureException(error, stackTrace: stacktrace);
      log.warning('[DeeplinkService] InitBranchSession error: $error');
    });

    try {
      final appLink = AppLinks();
      final initialLink = await appLink.getInitialLinkString();
      log.info('[DeeplinkService] initialLink: $initialLink');
      if (initialLink != null) {
        handleDeeplink(initialLink);
      }

      appLink.uriLinkStream.listen((link) {
        log.info('[DeeplinkService] uriLinkStream: $link');
        handleDeeplink(link.toString());
      });
    } on PlatformException {
      //Ignore
    }
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
          await _handleBranchDeeplink(link, onFinish: onFinished);
        case DeepLinkHandlerType.dAppConnect:
          await _handleDappConnectDeeplink(link);
        case DeepLinkHandlerType.irl:
          await _handleIRL(link);
        case DeepLinkHandlerType.homeWidget:
          await _handleHomeWidgetDeeplink(link);
        case DeepLinkHandlerType.unknown:
          unawaited(_navigationService.showUnknownLink());
      }
      _deepLinkHandlingMap.remove(link);
      if (handlerType != DeepLinkHandlerType.branch) {
        onFinished?.call();
      }
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

  Future<bool> _handleHomeWidgetDeeplink(String link) async {
    log.info('[DeeplinkService] _handleHomeWidgetDeeplink');
    final homeWidgetPrefix = Constants.homeWidgetDeepLinks
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (homeWidgetPrefix != null) {
      final urlDecode = Uri.decodeFull(link.replaceFirst(homeWidgetPrefix, ''));
      final uri = Uri.tryParse(urlDecode);
      if (uri == null) {
        return false;
      }

      final widget = uri.queryParameters['widget'];
      switch (widget) {
        case 'daily':
          try {
            await _navigationService.navigatePath(
              AppRouter.dailyWorkPage,
            );
          } catch (e) {
            log.info('[DeeplinkService] navigatePath to dailyPage error: $e');
          }

        default:
          break;
      }

      return true;
    }

    return false;
  }

  Future<bool> _handleBranchDeeplink(String link, {Function? onFinish}) async {
    log.info('[DeeplinkService] _handleBranchDeeplink');
    final callingBranchDeepLinkPrefix = Constants.branchDeepLinks
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingBranchDeepLinkPrefix != null) {
      try {
        final response =
            await _branchApi.getParams(Environment.branchKey, link);
        await handleBranchDeeplinkData(response['data'], onFinish: onFinish);
      } catch (e, s) {
        unawaited(Sentry.captureException('Branch deeplink error: $e',
            stackTrace: s));
        log.info('[DeeplinkService] _handleBranchDeeplink error $e');
        await _navigationService.showCannotResolveBranchLink();
      }
      return true;
    }
    return false;
  }

  // TODO: handle onFinish is only for feralfile_display.
  // Please handle for other cases if needed
  @override
  Future<void> handleBranchDeeplinkData(
    Map<dynamic, dynamic> data, {
    Function? onFinish,
  }) async {
    final navigatePath = data['navigation_route'];
    if (navigatePath != null) {
      await _navigationService.navigatePath(navigatePath);
    }
    log.info('[DeeplinkService] handleBranchDeeplinkData $data');
    log.info('source: ${data['source']}');
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
        {
          final reportId = data['reportId'];
          if (reportId != null) {
            await _handleFeralFileDisplayReport(reportId);
          } else {
            final deviceRawPayload = data['device'] as Map<dynamic, dynamic>;
            final Map<String, dynamic> payload = {};
            deviceRawPayload.forEach((key, value) {
              payload[key.toString()] = value;
            });
            final device = CanvasDevice.fromJson(payload);
            await _handleFeralFileDisplayConnecting(device, onFinish);
          }
        }

      case 'membership_subscription':
        final String url = data['callbackURL']!;
        final primaryAddress =
            await injector<AddressService>().getPrimaryAddress();
        _navigationService.popUntilHome();
        if (primaryAddress == null) {
          await _navigationService.addressNotFoundError();
        } else {
          final uri = Uri.parse(url);
          final isPremium = await injector<IAPService>().isSubscribed();
          final queryParameters = {
            'a': primaryAddress,
            'mt': isPremium ? 'premium' : 'none',
          }..addAll(uri.queryParameters);
          final newUri = uri.replace(queryParameters: queryParameters);
          final link = newUri.toString();
          log.info('MembershipSubscription: $link');
          await _navigationService.goToIRLWebview(
            IRLWebScreenPayload(
              link,
              isPlainUI: true,
              statusBarColor: AppColor.white,
              isDarkStatusBar: false,
            ),
          );
        }

      case 'gift_membership':
        final giftCode = data['gift_code'];
        await GiftHandler.handleGiftMembership(giftCode);

      case 'referral_code':
        final referralCode = data['referralCode'];
        log.info('[DeeplinkService] referralCode: $referralCode');
        await handleReferralCode(referralCode);

      case 'playlist_activation':
        try {
          log.info('[DeeplinkService] playlist_activation');
          unawaited(
              injector<ConfigurationService>().setDidShowLiveWithArt(true));
          final expiredAt = int.tryParse(data['expired_at']);
          log.info('[DeeplinkService] expiredAt: $expiredAt');
          if (expiredAt != null) {
            final expiredAtDate =
                DateTime.fromMillisecondsSinceEpoch(expiredAt);
            if (expiredAtDate.isBefore(DateTime.now())) {
              log.info('[DeeplinkService] playlist_activation expired');
              unawaited(_navigationService.showPlaylistActivationExpired());
              break;
            }
          }
          log.info('[DeeplinkService] playlist_activation not expired');
          final playlistJson = (data['playlist'] as Map<dynamic, dynamic>)
              .map((key, value) => MapEntry(key.toString(), value));

          final playlist = PlayListModel.fromJson(playlistJson)
              .copyWith(source: PlayListSource.activation);
          final activationName = data['activation_name'];
          final activationSource = data['activation_source'];
          final thumbnailURL = data['activation_thumbnail'];
          final activation = PlaylistActivation(
            playListModel: playlist,
            name: activationName,
            source: activationSource,
            thumbnailURL: thumbnailURL,
          );
          log.info('[DeeplinkService] playlist_activation $activation');
          await _navigationService.navigateTo(
            AppRouter.playlistActivationPage,
            arguments: PlaylistActivationPagePayload(
              activation: activation,
            ),
          );
        } catch (e) {
          log.info('[DeeplinkService] playlist_activation error $e');
        }
      default:
        log.info('[DeeplinkService] source not found');
    }
    _deepLinkHandlingMap.remove(data['~referring_link']);
  }

  @override
  Future<void> handleReferralCode(String referralCode) async {
    log.info('[DeeplinkService] handleReferralCode $referralCode');
    // save referral code to local storage, for case when user register failed
    await _configurationService.setReferralCode(referralCode);
    try {
      await injector<AddressService>()
          .registerReferralCode(referralCode: referralCode);
      // clear referral code after register success
      await _configurationService.setReferralCode('');
    } catch (e, s) {
      log.info('[DeeplinkService] _handleReferralCode error $e');
      unawaited(
          Sentry.captureException('Referral code error: $e', stackTrace: s));
      if (e is DioException) {
        if (e.isAlreadySetReferralCode) {
          log.info('[DeeplinkService] referral code already set');
          // if referral code is already set, clear it
          await _configurationService.setReferralCode('');
        }
      }
    }
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

  Future _handleFeralFileDisplayReport(String reportId) async {
    await _navigationService.navigateTo(
      AppRouter.supportThreadPage,
      arguments: NewIssuePayload(
        reportIssueType: ReportIssueType.Bug,
        artworkReportID: reportId,
      ),
    );
  }

  Future _handleFeralFileDisplayConnecting(
    CanvasDevice device,
    Function? onFinish,
  ) async {
    final canvasClient = injector<CanvasClientServiceV2>();
    try {
      final result = await canvasClient.addQrDevice(device);
      final isSuccessful = result != null;
      if (isSuccessful) {
        onFinish?.call(device);
      }
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
        return;
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
    } catch (e) {
      log.info('[DeeplinkService] feralfile_display error $e');
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
  homeWidget,
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

    if (Constants.homeWidgetDeepLinks
        .any((prefix) => value.startsWith(prefix))) {
      return DeepLinkHandlerType.homeWidget;
    }

    return DeepLinkHandlerType.unknown;
  }
}
