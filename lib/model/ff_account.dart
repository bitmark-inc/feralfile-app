//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ff_account.g.dart';

@JsonSerializable()
class FFAccount {
  @JsonKey(name: "ID", defaultValue: '')
  String id;
  String alias;
  String location;
  WyreWallet? wyreWallet;
  Map<String, String>? vaultAddresses;

  FFAccount(
      {required this.id,
      required this.alias,
      required this.location,
      required this.wyreWallet,
      required this.vaultAddresses});

  factory FFAccount.fromJson(Map<String, dynamic> json) =>
      _$FFAccountFromJson(json);

  Map<String, dynamic> toJson() => _$FFAccountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

  String? get ethereumAddress {
    return vaultAddresses?['ethereum'];
  }

  String? get tezosAddress {
    return vaultAddresses?['tezos'];
  }
}

@JsonSerializable()
class WyreWallet {
  Map<String, double> availableBalances;

  WyreWallet({
    required this.availableBalances,
  });

  factory WyreWallet.fromJson(Map<String, dynamic> json) =>
      _$WyreWalletFromJson(json);

  Map<String, dynamic> toJson() => _$WyreWalletToJson(this);
}

@JsonSerializable()
class Exhibition {
  final String id;
  final String title;
  final String coverURI;
  final String thumbnailCoverURI;
  final String saleModel;
  final String mintBlockchain;
  final List<FFArtist> artists;
  final List<FFArtwork> artworks;
  final AirdropInfo? airdropInfo;

  Exhibition(
    this.id,
    this.airdropInfo,
    this.title,
    this.coverURI,
    this.thumbnailCoverURI,
    this.artists,
    this.artworks,
    this.saleModel,
    this.mintBlockchain,
  );

  factory Exhibition.fromJson(Map<String, dynamic> json) =>
      _$ExhibitionFromJson(json);

  Map<String, dynamic> toJson() => _$ExhibitionToJson(this);

  FFArtist? getArtist(FFArtwork? artwork) {
    final artistId = artwork?.artistID;
    return artists.firstWhereOrNull((artist) => artist.id == artistId);
  }

  String getThumbnailURL() {
    return "${Environment.feralFileAssetURL}/$thumbnailCoverURI";
  }
}

@JsonSerializable()
class ExhibitionResponse {
  final Exhibition result;

  ExhibitionResponse(this.result);

  factory ExhibitionResponse.fromJson(Map<String, dynamic> json) =>
      _$ExhibitionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExhibitionResponseToJson(this);
}

@JsonSerializable()
class FFArtist {
  @JsonKey(name: "ID")
  final String id;
  final String alias;
  final String slug;
  final bool verified;
  final bool isArtist;
  final String fullName;
  final String avatarURI;
  final String accountNumber;
  final String type;

  FFArtist(
    this.id,
    this.alias,
    this.slug,
    this.verified,
    this.isArtist,
    this.fullName,
    this.avatarURI,
    this.accountNumber,
    this.type,
  );

  factory FFArtist.fromJson(Map<String, dynamic> json) =>
      _$FFArtistFromJson(json);

  Map<String, dynamic> toJson() => _$FFArtistToJson(this);
}

@JsonSerializable()
class FFArtwork {
  final String id;
  final String artistID;
  final String title;
  final String medium;
  final String description;
  final String? thumbnailFileURI;
  final String? galleryThumbnailFileURI;

  FFArtwork(
    this.id,
    this.artistID,
    this.title,
    this.medium,
    this.description,
    this.thumbnailFileURI,
    this.galleryThumbnailFileURI,
  );

  String getThumbnailURL() {
    return "${Environment.feralFileAssetURL}/$galleryThumbnailFileURI";
  }

  factory FFArtwork.fromJson(Map<String, dynamic> json) =>
      _$FFArtworkFromJson(json);

  Map<String, dynamic> toJson() => _$FFArtworkToJson(this);
}

@JsonSerializable()
class AirdropInfo {
  final String contractAddress;
  final String blockchain;
  final int remainAmount;
  final String? artworkTitle;
  final String? artist;
  final DateTime? endedAt;

  AirdropInfo(
    this.contractAddress,
    this.blockchain,
    this.remainAmount,
    this.artworkTitle,
    this.artist,
    this.endedAt,
  );

  factory AirdropInfo.fromJson(Map<String, dynamic> json) =>
      _$AirdropInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AirdropInfoToJson(this);
}

@JsonSerializable()
class TokenClaimResponse {
  final TokenClaimResult result;

  TokenClaimResponse(this.result);

  factory TokenClaimResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenClaimResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenClaimResponseToJson(this);

  @override
  String toString() {
    return 'TokenClaimResponse{result: $result}';
  }
}

@JsonSerializable()
class TokenClaimResult {
  final String id;
  final String claimerID;
  final String exhibitionID;
  final String editionID;
  final String txID;

  TokenClaimResult(
    this.id,
    this.claimerID,
    this.exhibitionID,
    this.editionID,
    this.txID,
  );

  factory TokenClaimResult.fromJson(Map<String, dynamic> json) =>
      _$TokenClaimResultFromJson(json);

  Map<String, dynamic> toJson() => _$TokenClaimResultToJson(this);

  @override
  String toString() {
    return 'TokenClaimResult{id: $id, claimerID: $claimerID, exhibitionID: $exhibitionID, editionID: $editionID, txID: $txID}';
  }
}

@JsonSerializable()
class FeralfileError {
  final int code;
  final String message;

  FeralfileError(
    this.code,
    this.message,
  );

  factory FeralfileError.fromJson(Map<String, dynamic> json) =>
      _$FeralfileErrorFromJson(json);

  Map<String, dynamic> toJson() => _$FeralfileErrorToJson(this);
}