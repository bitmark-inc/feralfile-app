//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';

abstract class ArtworkDetailEvent {}

class ArtworkDetailGetInfoEvent extends ArtworkDetailEvent {
  final ArtworkIdentity identity;
  final bool useIndexer;

  ArtworkDetailGetInfoEvent(this.identity, {this.useIndexer = false});
}

class ArtworkDetailGetAirdropDeeplink extends ArtworkDetailEvent {
  final AssetToken assetToken;

  ArtworkDetailGetAirdropDeeplink({required this.assetToken});
}

class ArtworkDetailState {
  AssetToken? assetToken;
  List<Provenance> provenances;
  Map<String, int> owners;
  String? airdropDeeplink;
  bool isViewOnly;

  ArtworkDetailState({
    this.assetToken,
    required this.provenances,
    this.owners = const {},
    this.airdropDeeplink,
    this.isViewOnly = true,
  });

  //copyWith
  ArtworkDetailState copyWith({
    AssetToken? assetToken,
    List<Provenance>? provenances,
    Map<String, int>? owners,
    String? airdropDeeplink,
    bool? isViewOnly,
  }) {
    return ArtworkDetailState(
      assetToken: assetToken ?? this.assetToken,
      provenances: provenances ?? this.provenances,
      owners: owners ?? this.owners,
      airdropDeeplink: airdropDeeplink ?? this.airdropDeeplink,
      isViewOnly: isViewOnly ?? this.isViewOnly,
    );
  }
}
