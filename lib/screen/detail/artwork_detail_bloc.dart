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
import 'package:autonomy_flutter/util/log.dart';
import 'package:nft_collection/database/dao/dao.dart';
import 'package:http/http.dart' as http;

class ArtworkDetailBloc extends AuBloc<ArtworkDetailEvent, ArtworkDetailState> {
  final FeralFileService _feralFileService;
  final AssetTokenDao _assetTokenDao;
  final AssetDao _assetDao;
  final ProvenanceDao _provenanceDao;

  ArtworkDetailBloc(
    this._feralFileService,
    this._assetTokenDao,
    this._assetDao,
    this._provenanceDao,
  ) : super(ArtworkDetailState(provenances: [])) {
    on<ArtworkDetailGetInfoEvent>((event, emit) async {
      final assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
          event.identity.id, event.identity.owner);
      if (assetToken != null &&
          assetToken.asset != null &&
          (assetToken.mimeType?.isEmpty ?? true)) {
        final uri = Uri.tryParse(assetToken.previewURL ?? '');
        if (uri != null) {
          try {
            final res = await http.head(uri);
            assetToken.asset!.mimeType = res.headers["content-type"];
            _assetDao.updateAsset(assetToken.asset!);
          } catch (error) {
            log.info("ArtworkDetailGetInfoEvent: preview url error", error);
          }
        }
      }
      final provenances =
          await _provenanceDao.findProvenanceByTokenID(event.identity.id);

      emit(ArtworkDetailState(assetToken: assetToken, provenances: []));

      List<AssetPrice> assetPrices = [];

      if (event.identity.id.startsWith('bmk--')) {
        assetPrices = await _feralFileService
            .getAssetPrices([event.identity.id.replaceAll("bmk--", "")]);
      }

      emit(ArtworkDetailState(
          assetToken: assetToken,
          provenances: provenances,
          assetPrice: assetPrices.isNotEmpty ? assetPrices.first : null));
    });
  }
}
