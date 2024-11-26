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
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/playlist_activation.dart';
import 'package:autonomy_flutter/screen/activation/playlist_activation/playlist_activation_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
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

  Future<void> handleReferralCode(String referralCode);
}

class DeeplinkServiceImpl extends DeeplinkService {
  final ConfigurationService _configurationService;
  final NavigationService _navigationService;
  final BranchApi _branchApi;

  final Map<String, bool> _deepLinkHandlingMap = {};

  DeeplinkServiceImpl(
    this._configurationService,
    this._navigationService,
    this._branchApi,
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

    final navigationPrefixes = [
      'feralfile://navigation/',
    ];

    final callingNavigationPrefix = navigationPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingNavigationPrefix != null) {
      final navigationPath = link.replaceFirst(callingNavigationPrefix, '');
      await _navigationService.navigatePath(navigationPath);
      return true;
    }
    return false;
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
      case 'autonomy_irl':
        final url = data['irl_url'];
        if (url != null) {
          log.info('[DeeplinkService] _handleIRL $url');
          await _handleIRL(url);
        }

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
              addressWallets.removeWhere(
                  (element) => element.cryptoType.toLowerCase() != chain);
              if (addressWallets.isEmpty) {
                primaryAddress = null;
              } else {
                primaryAddress = addressWallets.first.address;
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
