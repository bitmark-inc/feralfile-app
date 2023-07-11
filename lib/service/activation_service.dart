//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';

class ActivationService {
  final ActivationApi _airdropApi;
  final AssetTokenDao _assetTokenDao;
  final AccountService _accountService;
  final TezosService _tezosService;
  final TokensService _tokensService;
  final FeralFileService _feralFileService;
  final IndexerService _indexerService;
  final NavigationService _navigationService;

  const ActivationService(
      this._airdropApi,
      this._assetTokenDao,
      this._accountService,
      this._tezosService,
      this._tokensService,
      this._feralFileService,
      this._indexerService,
      this._navigationService);

  Future<ActivationInfo> getActivation(String activationID) {
    return _airdropApi.getActivation(activationID);
  }

  Future<ActivationClaimResponse> claimActivation(
      ActivationClaimRequest request) async {
    return _airdropApi.claim(request);
  }
}
