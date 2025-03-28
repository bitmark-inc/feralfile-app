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
import 'package:autonomy_flutter/screen/device_setting/check_bluetooth_state.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
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
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class DeeplinkService {
  Future<void> setup();

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
  Future<void> setup() async {
    log.info('[DeeplinkService] setup');

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
        log.info('[DeeplinkService] deeplink $link is handling');
        return;
      }
      _deepLinkHandlingMap[link] = true;
      final handlerType = DeepLinkHandlerType.fromString(link);

      Future<void> onFinishDeeplink() async {
        try {
          await onFinished?.call();
        } catch (e) {
          log.info('[DeeplinkService] onFinishDeeplink error: $e');
        }
        _deepLinkHandlingMap.remove(link);
      }

      log.info('[DeeplinkService] handlerType $handlerType');
      switch (handlerType) {
        case DeepLinkHandlerType.branch:
          await _handleBranchDeeplink(link, onFinish: onFinishDeeplink);
        case DeepLinkHandlerType.dAppConnect:
          await _handleDappConnectDeeplink(link);
        case DeepLinkHandlerType.homeWidget:
          await _handleHomeWidgetDeeplink(link);
        case DeepLinkHandlerType.bluetoothConnect:
          await _handleBluetoothConnectDeeplink(link);
        case DeepLinkHandlerType.unknown:
          unawaited(_navigationService.showUnknownLink());
      }
      if (handlerType != DeepLinkHandlerType.branch) {
        await onFinishDeeplink.call();
      }
      // this function is called in onFinishDeeplink, so we don't need to call it here
      // _deepLinkHandlingMap.remove(link);
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

  Future<void> _handleBluetoothConnectDeeplink(String link,
      {Function? onFinish}) async {
    final prefix = Constants.bluetoothConnectDeepLinks
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (prefix == null) {
      log.info(
          '[DeeplinkService] _handleBluetoothConnectDeeplink prefix not found');
      return;
    }
    unawaited(
        injector<ConfigurationService>().setDidShowLiveWithArt(true).then((_) {
      log.info('setDidShowLiveWithArt to true');
    }));

    await injector<NavigationService>().navigateTo(
      AppRouter.handleBluetoothDeviceScanDeeplinkScreen,
      arguments: HandleBluetoothDeviceScanDeeplinkScreenPayload(
        deeplink: link,
        onFinish: () {},
      ),
    );
  }

  Future<bool> _handleBranchDeeplink(String link, {Function? onFinish}) async {
    log.info('[DeeplinkService] _handleBranchDeeplink');
    final callingBranchDeepLinkPrefix = Constants.branchDeepLinks
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingBranchDeepLinkPrefix != null) {
      try {
        final response =
            await _branchApi.getParams(Environment.branchKey, link);
        await handleBranchDeeplinkData(
            response['data'] as Map<dynamic, dynamic>,
            onFinish: onFinish);
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
      await _navigationService.navigatePath(navigatePath as String);
    }
    log.info('[DeeplinkService] handleBranchDeeplinkData $data');
    log.info('source: ${data['source']}');
    final source = data['source'];
    switch (source) {
      case 'feralfile_display':
        {
          final reportId = data['reportId'];
          if (reportId != null) {
            await _handleFeralFileDisplayReport(reportId as String);
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

      case 'gift_membership':
        final giftCode = data['gift_code'] as String;
        await GiftHandler.handleGiftMembership(giftCode);

      case 'referral_code':
        final referralCode = data['referralCode'];
        log.info('[DeeplinkService] referralCode: $referralCode');
        await handleReferralCode(referralCode as String);

      case 'playlist_activation':
        try {
          log.info('[DeeplinkService] playlist_activation');
          unawaited(
              injector<ConfigurationService>().setDidShowLiveWithArt(true));
          final expiredAt = int.tryParse(data['expired_at'] as String);
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
            name: activationName as String,
            source: activationSource as String,
            thumbnailURL: thumbnailURL as String,
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

  Future<void> _handleFeralFileDisplayConnecting(
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
          showSimpleNotificationToast(
            key: const Key('connected_to_canvas'),
            content: '${'connected_to_display'.tr()} ',
            addOnTextSpan: [
              TextSpan(
                text: device.name,
                style: Theme.of(_navigationService.context)
                    .textTheme
                    .ppMori400FFYellow14
                    .copyWith(color: AppColor.feralFileLightBlue),
              )
            ],
          );
        }
        return;
      }
      if (isSuccessful) {
        showSimpleNotificationToast(
          key: const Key('connected_to_canvas'),
          content: '${'connected_to_display'.tr()} ',
          addOnTextSpan: [
            TextSpan(
              text: device.name,
              style: Theme.of(_navigationService.context)
                  .textTheme
                  .ppMori400FFYellow14
                  .copyWith(color: AppColor.feralFileLightBlue),
            )
          ],
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
  homeWidget,
  bluetoothConnect,
  unknown,
  ;

  static DeepLinkHandlerType fromString(String value) {
    if (Constants.dAppConnectPrefixes
        .any((prefix) => value.startsWith(prefix))) {
      return DeepLinkHandlerType.dAppConnect;
    }

    if (Constants.branchDeepLinks.any((prefix) => value.startsWith(prefix))) {
      return DeepLinkHandlerType.branch;
    }

    if (Constants.homeWidgetDeepLinks
        .any((prefix) => value.startsWith(prefix))) {
      return DeepLinkHandlerType.homeWidget;
    }

    if (Constants.bluetoothConnectDeepLinks
        .any((prefix) => value.startsWith(prefix))) {
      return DeepLinkHandlerType.bluetoothConnect;
    }
    return DeepLinkHandlerType.unknown;
  }
}
