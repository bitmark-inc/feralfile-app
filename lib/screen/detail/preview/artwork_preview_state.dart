//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:nft_collection/models/asset_token.dart';

abstract class ArtworkPreviewEvent {}

class ArtworkPreviewGetAssetTokenEvent extends ArtworkPreviewEvent {
  final String id;

  ArtworkPreviewGetAssetTokenEvent(this.id);
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
  AssetToken? asset;
  bool isFullScreen;

  ArtworkPreviewLoadedState({this.asset, this.isFullScreen = false});

  ArtworkPreviewLoadedState copyWith({AssetToken? asset, bool? isFullScreen}) {
    return ArtworkPreviewLoadedState(
        asset: asset ?? this.asset,
        isFullScreen: isFullScreen ?? this.isFullScreen);
  }
}
