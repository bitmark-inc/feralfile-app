//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:dio/dio.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/tokens_service.dart';

class ActivationService {
  final ActivationApi _airdropApi;
  final TokensService _tokensService;
  final NavigationService _navigationService;

  const ActivationService(
      this._airdropApi, this._tokensService, this._navigationService);

  Future<ActivationInfo> getActivation({required String activationID}) async =>
      await _airdropApi.getActivation(activationID);

  Future<ActivationClaimResponse> claimActivation(
      {required ActivationClaimRequest request,
      required AssetToken assetToken}) async {
    try {
      final response = await _airdropApi.claim(request);
      await _tokensService.setCustomTokens([
        assetToken.copyWith(
            owner: request.address,
            pending: true,
            balance: 1,
            lastActivityTime: DateTime.now(),
            lastRefreshedTime: DateTime(1),
            asset: assetToken.asset?.copyWith(initialSaleModel: "airdrop"))
      ]);
      return response;
    } catch (e) {
      log.info("[Activation service] claimActivation: $e");
      if (e is DioException) {
        switch (e.response?.data['message']) {
          case "cannot self claim":
            _navigationService.showAirdropJustOnce();
            break;
          case "invalid claim":
            _navigationService.showAirdropAlreadyClaimed();
            break;
          case "the token is not available for share":
            _navigationService.showAirdropAlreadyClaimed();
            break;
          default:
            UIHelper.showActivationError(
              _navigationService.navigatorKey.currentContext!,
              e,
              assetToken.id,
            );
        }
      }
      rethrow;
    }
  }

  String getIndexerID(String chain, String contract, String tokenID) {
    switch (chain) {
      case 'ethereum':
        return "eth-$contract-$tokenID";
      case 'tezos':
        return "tez-$contract-$tokenID";
      default:
        return '';
    }
  }
}
