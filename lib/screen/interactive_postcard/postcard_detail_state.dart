//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_bigmap.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:collection/collection.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';

class PostcardDetailState {
  AssetToken? assetToken;
  List<Provenance> provenances;
  PostcardValue? postcardValue;
  String? imagePath;
  String? metadataPath;
  bool postcardValueLoaded;
  PostcardLeaderboard? leaderboard;
  bool isFetchingLeaderboard;

  PostcardDetailState({
    this.assetToken,
    required this.provenances,
    this.postcardValue,
    this.imagePath,
    this.metadataPath,
    required this.postcardValueLoaded,
    this.leaderboard,
    this.isFetchingLeaderboard = false,
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
    String? imagePath,
    String? metadataPath,
    bool? postcardValueLoaded,
    PostcardLeaderboard? leaderboard,
    bool? isFetchingLeaderboard,
  }) {
    return PostcardDetailState(
      assetToken: assetToken ?? this.assetToken,
      provenances: provenances ?? this.provenances,
      postcardValue: postcardValue ?? this.postcardValue,
      imagePath: imagePath ?? this.imagePath,
      metadataPath: metadataPath ?? this.metadataPath,
      postcardValueLoaded: postcardValueLoaded ?? this.postcardValueLoaded,
      leaderboard: leaderboard ?? this.leaderboard,
      isFetchingLeaderboard:
          isFetchingLeaderboard ?? this.isFetchingLeaderboard,
    );
  }
}

extension PostcardDetailStateExtension on PostcardDetailState {
  bool get isLoaded => assetToken != null && postcardValue != null;

  bool get isFinal {
    return isLoaded && postcardValue!.counter == MAX_STAMP_IN_POSTCARD;
  }

  bool get isCompleted {
    final isStamped = postcardValue?.stamped ?? false;
    return isFinal && isStamped;
  }

  bool isSending() {
    final sharedPostcards =
        injector<ConfigurationService>().getSharedPostcard();
    final id = assetToken?.id;
    return sharedPostcards.any((element) {
      return !element.isExpired &&
          element.owner == assetToken?.owner &&
          element.tokenID == id;
    });
  }

  bool isShareExpired() {
    if (assetToken == null) return false;
    final sharedPostcards =
        injector<ConfigurationService>().getSharedPostcard();
    final sharedPostcard = sharedPostcards.firstWhereOrNull((element) {
      return element.owner == assetToken?.owner &&
          element.tokenID == assetToken?.id;
    });
    if (sharedPostcard == null) return false;
    return sharedPostcard.isExpired;
  }

  bool isStamping() {
    final stampingPostcard = injector<PostcardService>().getStampingPostcard();
    final lastOwner = postcardValue?.postman;
    final owner = assetToken?.owner;
    final id = assetToken?.id;
    return stampingPostcard.any((element) {
      final bool = (element.indexId == id &&
          element.address == owner &&
          lastOwner == owner);
      return bool;
    });
  }

  bool get isPostcardUpdating {
    return isStamping();
  }

  bool get isPostcardUpdatingOnBlockchain {
    return postcardValue == null ||
        (isStamping() && postcardValue!.stamped == false);
  }

  bool get isStamped {
    return postcardValue?.stamped ?? false;
  }

  bool get isLastOwner {
    if (postcardValue == null) {
      return true;
    }
    final lastOwner = postcardValue?.postman;
    final owner = assetToken?.owner;
    return lastOwner == owner;
  }

  bool get canDoAction {
    if (postcardValue == null) {
      return postcardValueLoaded;
    }
    final lastOwner = postcardValue?.postman;
    final owner = assetToken?.owner;
    return lastOwner == owner && !isCompleted;
  }

  bool get didSendNext {
    if (assetToken == null) return false;
    final owner = assetToken!.owner;
    final artists = assetToken!.getArtists;
    final artistOwner =
        artists.firstWhereOrNull((element) => element.id == owner);
    if (artistOwner == null) return false;
    return artistOwner != artists.last;
  }
}
