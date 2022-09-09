//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';

class ArtworkPreviewDetailBloc
    extends AuBloc<ArtworkPreviewDetailEvent, ArtworkPreviewDetailState> {
  final AssetTokenDao _assetTokenDao;
  final ConfigurationService _configurationService;

  ArtworkPreviewDetailBloc(this._assetTokenDao, this._configurationService)
      : super(ArtworkPreviewDetailLoadingState()) {
    on<ArtworkPreviewDetailGetAssetTokenEvent>((event, emit) async {
      final asset = await _assetTokenDao.findAssetTokenById(event.id);
      emit(ArtworkPreviewDetailLoadedState(asset: asset));
    });
  }
}
