//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:nft_collection/models/asset_token.dart';

abstract class ArtworkPreviewDetailEvent {}

class ArtworkPreviewDetailGetAssetTokenEvent extends ArtworkPreviewDetailEvent {
  final String id;

  ArtworkPreviewDetailGetAssetTokenEvent(this.id);
}

abstract class ArtworkPreviewDetailState {
  ArtworkPreviewDetailState();
}

class ArtworkPreviewDetailLoadingState extends ArtworkPreviewDetailState {
  ArtworkPreviewDetailLoadingState();
}

class ArtworkPreviewDetailLoadedState extends ArtworkPreviewDetailState {
  AssetToken? asset;

  ArtworkPreviewDetailLoadedState({this.asset});
}
