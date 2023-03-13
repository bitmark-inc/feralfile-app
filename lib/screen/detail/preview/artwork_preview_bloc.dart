//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:nft_collection/database/dao/dao.dart';

class ArtworkPreviewBloc
    extends AuBloc<ArtworkPreviewEvent, ArtworkPreviewState> {
  final AssetTokenDao _assetTokenDao;
  final AssetDao _assetDao;
  ArtworkPreviewBloc(this._assetTokenDao, this._assetDao)
      : super(ArtworkPreviewLoadingState()) {
    on<ArtworkPreviewGetAssetTokenEvent>((event, emit) async {
      final assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
          event.identity.id, event.identity.owner);
      if (state is ArtworkPreviewLoadedState) {
        final currentState = state as ArtworkPreviewLoadedState;
        emit(currentState.copyWith(assetToken: assetToken));
      } else {
        emit(ArtworkPreviewLoadedState(assetToken: assetToken));
      }
      // change ipfs if the cloud_flare ipfs has not worked
      try {
        if (assetToken?.previewURL != null) {
          final response =
              await callRequest(Uri.parse(assetToken!.previewURL!));
          if (response.statusCode == 520) {
            assetToken.asset?.previewURL = assetToken.previewURL!.replaceRange(
                0, Environment.autonomyIpfsPrefix.length, DEFAULT_IPFS_PREFIX);
            await _assetDao.insertAsset(assetToken.asset!);
            emit(ArtworkPreviewLoadedState(assetToken: assetToken));
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
