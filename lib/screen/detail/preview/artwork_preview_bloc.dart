//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';

class ArtworkPreviewBloc
    extends AuBloc<ArtworkPreviewEvent, ArtworkPreviewState> {
  final AssetTokenDao _assetTokenDao;
  final ConfigurationService _configurationService;

  ArtworkPreviewBloc(this._assetTokenDao, this._configurationService)
      : super(ArtworkPreviewLoadingState()) {
    on<ArtworkPreviewGetAssetTokenEvent>((event, emit) async {
      final asset = await _assetTokenDao.findAssetTokenByIdAndOwner(event.identity.id, event.identity.owner);
      if (state is ArtworkPreviewLoadedState) {
        final currentState = state as ArtworkPreviewLoadedState;
        emit(currentState.copyWith(asset: asset));
      } else {
        emit(ArtworkPreviewLoadedState(asset: asset));
      }
      // change ipfs if the cloud_flare ipfs has not worked
      try {
        if (asset?.previewURL != null) {
          final response = await callRequest(Uri.parse(asset!.previewURL!));
          if (response.statusCode == 520) {
            asset.previewURL = asset.previewURL!.replaceRange(
                0, Environment.autonomyIpfsPrefix.length, DEFAULT_IPFS_PREFIX);
            await _assetTokenDao.insertAsset(asset);
            emit(ArtworkPreviewLoadedState(asset: asset));
          }
        }
      } catch (_) {
        // ignore this error
      }
    });

    on<ChangeFullScreen>((event, emit) async {
      if (state is ArtworkPreviewLoadedState) {
        final currentState = state as ArtworkPreviewLoadedState;
        emit(currentState.copyWith(isFullScreen: event.isFullscreen));
      }
    });
  }
}
