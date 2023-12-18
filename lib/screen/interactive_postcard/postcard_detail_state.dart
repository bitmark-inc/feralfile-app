//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';

class PostcardDetailState {
  AssetToken? assetToken;
  List<Provenance> provenances;
  String? imagePath;
  String? metadataPath;
  PostcardLeaderboard? leaderboard;
  bool isFetchingLeaderboard;
  bool? showMerch;
  bool? enableMerch;
  bool? isViewOnly;

  PostcardDetailState({
    required this.provenances,
    this.isViewOnly,
    this.assetToken,
    this.imagePath,
    this.metadataPath,
    this.leaderboard,
    this.isFetchingLeaderboard = false,
    this.showMerch,
    this.enableMerch,
  });

  ArtworkDetailState toArtworkDetailState() => ArtworkDetailState(
        assetToken: assetToken,
        provenances: provenances,
      );

  PostcardDetailState copyWith({
    AssetToken? assetToken,
    List<Provenance>? provenances,
    String? imagePath,
    String? metadataPath,
    PostcardLeaderboard? leaderboard,
    bool? isFetchingLeaderboard,
    bool? showMerch,
    bool? isViewOnly,
    bool? enableMerch,
  }) =>
      PostcardDetailState(
        assetToken: assetToken ?? this.assetToken,
        provenances: provenances ?? this.provenances,
        imagePath: imagePath ?? this.imagePath,
        metadataPath: metadataPath ?? this.metadataPath,
        leaderboard: leaderboard ?? this.leaderboard,
        isFetchingLeaderboard:
            isFetchingLeaderboard ?? this.isFetchingLeaderboard,
        showMerch: showMerch ?? this.showMerch,
        isViewOnly: isViewOnly ?? this.isViewOnly,
        enableMerch: enableMerch ?? this.enableMerch,
      );
}
