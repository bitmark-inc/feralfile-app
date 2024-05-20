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
  final bool useIndexer;

  ArtworkPreviewGetAssetTokenEvent(this.identity, {this.useIndexer = false});
}

abstract class ArtworkPreviewState {
  ArtworkPreviewState();
}

class ArtworkPreviewLoadingState extends ArtworkPreviewState {
  ArtworkPreviewLoadingState();
}

class ArtworkPreviewLoadedState extends ArtworkPreviewState {
  AssetToken? assetToken;

  ArtworkPreviewLoadedState({this.assetToken});

  ArtworkPreviewLoadedState copyWith({AssetToken? assetToken}) =>
      ArtworkPreviewLoadedState(assetToken: assetToken ?? this.assetToken);
}
