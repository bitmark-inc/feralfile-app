//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/gateway/user_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/passkey_service.dart';
import 'package:autonomy_flutter/util/exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthService {
  final IAPApi _authApi;
  final UserApi _userApi;
  final ConfigurationService _configurationService;
  JWT? _jwt;
  final UserAccountChannel _userAccountChannel;

  AuthService(this._authApi,
      this._userApi,
      this._configurationService,
      this._userAccountChannel,);

  Future<void> reset() async {
    await setAuthToken(null);
  }

  Future<JWT> _refreshJWT({String? receiptData}) async {
    final jwt = _jwt;
    final refreshToken = jwt?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw JwtException(message: 'refresh_token_empty'.tr());
    }
    final Map<String, dynamic> payload = {'refreshToken': refreshToken};
    if (receiptData != null) {
      // add the receipt data if available
      final String platform;
      if (Platform.isIOS) {
        platform = 'apple';
      } else {
        platform = 'google';
      }
      payload.addAll({
        'inAppReceipt': {'platform': platform, 'receipt_data': receiptData}
      });
    }
    final newJwt = await _userApi.refreshJWT(payload);
    return newJwt;
  }

  Future<JWT> refreshJWT({String? receiptData}) async {
    JWT? refreshedJwt;
    try {
      final newJwt = await _refreshJWT(receiptData: receiptData);
      refreshedJwt = _jwt!.copyWith(
        jwtToken: newJwt.jwtToken,
        expireIn: newJwt.expireIn,
      );
    } catch (e) {
      refreshedJwt =
      await injector<NavigationService>().showRefreshJwtFailedDialog(
        onRetry: () async {
          final refreshJwt = await injector<PasskeyService>().requestJwt();
          return refreshJwt;
        },
      );
    }
    if (refreshedJwt == null) {
      throw JwtException(message: 'jwt_refresh_failed'.tr());
    }
    await setAuthToken(refreshedJwt, receiptData: receiptData);
    return refreshedJwt;
  }

  void _refreshSubscriptionStatus(JWT? jwt, {String? receiptData}) {
    if (jwt?.isValid(withSubscription: true) ?? false) {
      log.info('jwt with valid subscription');
      unawaited(_configurationService
          .setIAPReceipt(receiptData ?? _configurationService.getIAPReceipt()));
      unawaited(_configurationService.setIAPJWT(jwt));
    } else {
      log.info('jwt with invalid subscription');
      unawaited(_configurationService.setIAPReceipt(null));
      unawaited(_configurationService.setIAPJWT(null));
    }
    injector<SubscriptionBloc>().add(GetSubscriptionEvent());
    injector<UpgradesBloc>().add(UpgradeQueryInfoEvent());
  }

  Future<void> setAuthToken(JWT? jwt, {String? receiptData}) async {
    if (jwt == null) {
      await _userAccountChannel.clearJWT();
    } else {
      await _userAccountChannel.setJWT(jwt);
    }
    _jwt = jwt;
    _refreshSubscriptionStatus(jwt, receiptData: receiptData);
  }

  Future<JWT?> getAuthToken({bool shouldRefresh = true}) async {
    // if current jwt is null, try to get it from the channel
    _jwt ??= await _userAccountChannel.getJWT();

    if (shouldRefresh) {
      // if jwt is invalid, try to refresh it
      if (_jwt?.isValid() != true) {
        _jwt = await refreshJWT();
      }
    }
    return _jwt;
  }

  Future<bool> redeemGiftCode(String giftCode) async {
    final response = await _authApi.redeemGiftCode(giftCode);
    return response.ok == 1;
  }

  Future<void> registerReferralCode({required String referralCode}) async {
    final body = {'code': referralCode};
    await _authApi.registerReferralCode(body);
  }
}
