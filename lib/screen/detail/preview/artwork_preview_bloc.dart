//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/helpers.dart';

class ArtworkPreviewBloc
    extends AuBloc<ArtworkPreviewEvent, ArtworkPreviewState> {
  AssetTokenDao _assetTokenDao;
  ConfigurationService _configurationService;

  ArtworkPreviewBloc(this._assetTokenDao, this._configurationService)
      : super(ArtworkPreviewState()) {
    on<ArtworkPreviewGetAssetTokenEvent>((event, emit) async {
      final asset = await _assetTokenDao.findAssetTokenById(event.id);
      emit(ArtworkPreviewState(asset: asset));

      // change ipfs if the CLOUDFLARE_IPFS_PREFIX has not worked
      // try {
      //   if (asset?.previewURL != null) {
      //     final response = await callRequest(Uri.parse(asset!.previewURL!));
      //     if (response.statusCode == 520) {
      //       asset.previewURL = asset.previewURL!.replaceRange(
      //           0, CLOUDFLARE_IPFS_PREFIX.length, DEFAULT_IPFS_PREFIX);
      //       final hiddenAssets = await _assetTokenDao.findAllHiddenAssets();
      //       final hiddenIds =
      //           _configurationService.getTempStorageHiddenTokenIDs() +
      //               hiddenAssets.map((e) => e.id).toList();
      //       if (hiddenIds.contains(asset.id)) {
      //         asset.hidden = 1;
      //       }
      //       await _assetTokenDao.insertAsset(asset);
      //       emit(ArtworkPreviewState(asset: asset));
      //     }
      //   }
      // } catch (_) {
      //   // ignore this error
      // }
    });
  }
}
