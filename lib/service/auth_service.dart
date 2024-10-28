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
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthService {
  final IAPApi _authApi;
  final UserApi _userApi;
  final ConfigurationService _configurationService;
  final AddressService _addressService;
  JWT? _jwt;

  AuthService(
    this._authApi,
    this._userApi,
    this._configurationService,
    this._addressService,
  );

  void reset() {
    _jwt = null;
  }

  Future<JWT> refreshJWT({String? receiptData}) async {
    final refreshToken = _jwt?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw JwtException(message: 'refresh_token_empty'.tr());
    }
    final Map<String, dynamic> payload = {'refresh_token': refreshToken};
    if (receiptData != null) {
      // add the receipt data if available
      final String platform;
      if (Platform.isIOS) {
        platform = 'apple';
      } else {
        platform = 'google';
      }
      payload.addAll({
        'receipt': {'platform': platform, 'receipt_data': receiptData}
      });
    }
    final newJwt = await _userApi.refreshJWT(payload);
    setAuthToken(newJwt);
    _refreshSubscriptionStatus(newJwt, receiptData: receiptData);
    return newJwt;
  }

  Future<JWT> authenticateAddress() async {
    final payload = await _addressService.getAddressAuthenticationMap();
    final jwt = await _userApi.authenticateAddress(payload);
    _jwt = jwt;
    _refreshSubscriptionStatus(jwt);
    return jwt;
  }

  void _refreshSubscriptionStatus(JWT jwt, {String? receiptData}) {
    if (jwt.isValid(withSubscription: true)) {
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

  void setAuthToken(JWT jwt) {
    _jwt = jwt;
  }

  Future<JWT?> getAuthToken() async {
    if (_jwt == null) {
      return null;
    }
    if (!_jwt!.isValid()) {
      await refreshJWT();
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
