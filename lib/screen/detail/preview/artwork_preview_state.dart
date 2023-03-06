//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:nft_collection/models/asset_token.dart';

abstract class ArtworkPreviewEvent {}

class ArtworkPreviewGetAssetTokenEvent extends ArtworkPreviewEvent {
  final ArtworkIdentity identity;

  ArtworkPreviewGetAssetTokenEvent(this.identity);
}

abstract class ArtworkPreviewState {
  ArtworkPreviewState();
}

class ChangeFullScreen extends ArtworkPreviewEvent {
  bool isFullscreen;
  ChangeFullScreen({this.isFullscreen = false});
}

class ArtworkPreviewLoadingState extends ArtworkPreviewState {
  ArtworkPreviewLoadingState();
}

class ArtworkPreviewLoadedState extends ArtworkPreviewState {
  AssetToken? assetToken;
  bool isFullScreen;

  ArtworkPreviewLoadedState({this.assetToken, this.isFullScreen = false});

  ArtworkPreviewLoadedState copyWith(
      {AssetToken? assetToken, bool? isFullScreen}) {
    return ArtworkPreviewLoadedState(
        assetToken: assetToken ?? this.assetToken,
        isFullScreen: isFullScreen ?? this.isFullScreen);
  }
}
