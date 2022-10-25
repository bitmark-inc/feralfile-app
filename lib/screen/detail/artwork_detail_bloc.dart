//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/database/dao/provenance_dao.dart';

class ArtworkDetailBloc extends AuBloc<ArtworkDetailEvent, ArtworkDetailState> {
  final FeralFileService _feralFileService;
  final AssetTokenDao _assetTokenDao;
  final ProvenanceDao _provenanceDao;

  ArtworkDetailBloc(
      this._feralFileService, this._assetTokenDao, this._provenanceDao)
      : super(ArtworkDetailState(provenances: [])) {
    on<ArtworkDetailGetInfoEvent>((event, emit) async {
      final asset = await _assetTokenDao.findAssetTokenByIdAndOwner(event.identity.id, event.identity.owner);
      final provenances =
          await _provenanceDao.findProvenanceByTokenID(event.identity.id);

      emit(ArtworkDetailState(asset: asset, provenances: []));

      List<AssetPrice> assetPrices = [];

      if (event.identity.id.startsWith('bmk--')) {
        assetPrices = await _feralFileService
            .getAssetPrices([event.identity.id.replaceAll("bmk--", "")]);
      }

      emit(ArtworkDetailState(
          asset: asset,
          provenances: provenances,
          assetPrice: assetPrices.isNotEmpty ? assetPrices.first : null));
    });
  }
}
