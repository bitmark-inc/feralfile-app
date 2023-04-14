//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/postcard_bigmap.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';

class PostcardDetailState {
  AssetToken? assetToken;
  List<Provenance> provenances;
  PostcardValue? postcardValue;

  PostcardDetailState({
    this.assetToken,
    required this.provenances,
    this.postcardValue,
  });

  ArtworkDetailState toArtworkDetailState() {
    return ArtworkDetailState(
      assetToken: assetToken,
      provenances: provenances,
    );
  }

  PostcardDetailState copyWith({
    AssetToken? assetToken,
    List<Provenance>? provenances,
    PostcardValue? postcardValue,
  }) {
    return PostcardDetailState(
      assetToken: assetToken ?? this.assetToken,
      provenances: provenances ?? this.provenances,
      postcardValue: postcardValue ?? this.postcardValue,
    );
  }
}
