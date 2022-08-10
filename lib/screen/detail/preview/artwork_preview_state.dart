//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/asset_token.dart';

abstract class ArtworkPreviewEvent {}

class ArtworkPreviewGetAssetTokenEvent extends ArtworkPreviewEvent {
  final String id;

  ArtworkPreviewGetAssetTokenEvent(this.id);
}

class ArtworkPreviewState {
  AssetToken? asset;

  ArtworkPreviewState({this.asset});
}
