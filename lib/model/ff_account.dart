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
  final String slug;
  final DateTime exhibitionStartAt;
  final DateTime exhibitionEndAt;
  final String? coverURI;
  final String? thumbnailCoverURI;
  final String mintBlockchain;
  final List<FFArtist>? artists;
  final List<FFArtwork>? artworks;
  final List<FFContract>? contracts;
  final FFArtist? partner;

  Exhibition(
    this.id,
    this.title,
    this.slug,
    this.exhibitionStartAt,
    this.exhibitionEndAt,
    this.coverURI,
    this.thumbnailCoverURI,
    this.artists,
    this.artworks,
    this.contracts,
    this.mintBlockchain,
    this.partner,
  );

  factory Exhibition.fromJson(Map<String, dynamic> json) =>
      _$ExhibitionFromJson(json);

  Map<String, dynamic> toJson() => _$ExhibitionToJson(this);

  FFArtist? getArtist(FFArtwork? artwork) {
    final artistId = artwork?.artistID;
    return artists?.firstWhereOrNull((artist) => artist.id == artistId);
  }

  String getThumbnailURL() {
    return "${Environment.feralFileAssetURL}/$thumbnailCoverURI";
  }
}

@JsonSerializable()
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
  final bool? verified;
  final bool? isArtist;
  final String? fullName;
  final String? avatarURI;
  final String? accountNumber;
  final String? type;

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
  final String slug;
  final String medium;
  final String? description;
  final String? thumbnailFileURI;
  final String? galleryThumbnailFileURI;
  final FFArtworkSettings? settings;
  final FFArtist? artist;
  final Exhibition? exhibition;
  final AirdropInfo? airdropInfo;
  final DateTime? createdAt;

  FFArtwork(
    this.id,
    this.artistID,
    this.title,
    this.slug,
    this.medium,
    this.description,
    this.thumbnailFileURI,
    this.galleryThumbnailFileURI,
    this.settings,
    this.artist,
    this.exhibition,
    this.airdropInfo,
    this.createdAt,
  );

  int get maxEdition {
    return settings?.maxEdition ?? -1;
  }

  FFContract? get contract {
    return exhibition?.contracts?.firstWhereOrNull((e) {
      return e.address == airdropInfo?.contractAddress;
    });
  }

  String getThumbnailURL() {
    return "${Environment.feralFileAssetURL}/${galleryThumbnailFileURI ?? thumbnailFileURI}";
  }

  bool get isAirdropArtwork {
    return settings?.isAirdrop == true;
  }

  factory FFArtwork.fromJson(Map<String, dynamic> json) =>
      _$FFArtworkFromJson(json);

  Map<String, dynamic> toJson() => _$FFArtworkToJson(this);
}

@JsonSerializable()
class FFArtworkResponse {
  final FFArtwork result;

  FFArtworkResponse(
    this.result,
  );

  factory FFArtworkResponse.fromJson(Map<String, dynamic> json) =>
      _$FFArtworkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FFArtworkResponseToJson(this);
}

@JsonSerializable()
class FFArtworkSettings {
  final int maxEdition;
  final String? saleModel;

  FFArtworkSettings(this.saleModel, this.maxEdition);

  factory FFArtworkSettings.fromJson(Map<String, dynamic> json) =>
      _$FFArtworkSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$FFArtworkSettingsToJson(this);

  bool get isAirdrop {
    return ["airdrop", "shopping_airdrop"].contains(saleModel?.toLowerCase());
  }
}

@JsonSerializable()
class FFContract {
  final String name;
  final String blockchainType;
  final String address;

  FFContract(
    this.name,
    this.blockchainType,
    this.address,
  );

  factory FFContract.fromJson(Map<String, dynamic> json) =>
      _$FFContractFromJson(json);

  Map<String, dynamic> toJson() => _$FFContractToJson(this);
}

@JsonSerializable()
class AirdropInfo {
  final String contractAddress;
  final String blockchain;
  final int remainAmount;
  final String? artworkId; // TODO: rename?
  final String? artworkTitle;
  final String? artist;
  final String? gifter;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? twitterCaption;

  AirdropInfo(
    this.contractAddress,
    this.blockchain,
    this.remainAmount,
    this.artworkId,
    this.artworkTitle,
    this.artist,
    this.gifter,
    this.startedAt,
    this.endedAt,
    this.twitterCaption,
  );

  factory AirdropInfo.fromJson(Map<String, dynamic> json) =>
      _$AirdropInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AirdropInfoToJson(this);

  bool get isAirdropStarted {
    return startedAt?.isBefore(DateTime.now()) == true;
  }
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

  @override
  String toString() {
    return 'FeralfileError{code: $code, message: $message}';
  }
}

@JsonSerializable()
class ResaleResponse {
  final FeralFileResaleInfo result;

  ResaleResponse(this.result);

  factory ResaleResponse.fromJson(Map<String, dynamic> json) =>
      _$ResaleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ResaleResponseToJson(this);
}

@JsonSerializable()
class FeralFileResaleInfo {
  final String exhibitionID;
  final String saleType;
  final double platform;
  final double artist;
  final double seller;
  final double curator;
  final double partner;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeralFileResaleInfo(
      this.exhibitionID,
      this.saleType,
      this.platform,
      this.artist,
      this.seller,
      this.curator,
      this.partner,
      this.createdAt,
      this.updatedAt);

  factory FeralFileResaleInfo.fromJson(Map<String, dynamic> json) =>
      _$FeralFileResaleInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FeralFileResaleInfoToJson(this);
}

@JsonSerializable()
class ArtworkEditionResponse {
  final ArtworkEdition result;

  ArtworkEditionResponse(this.result);

  factory ArtworkEditionResponse.fromJson(Map<String, dynamic> json) =>
      _$ArtworkEditionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkEditionResponseToJson(this);
}

@JsonSerializable()
class ArtworkEdition {
  final String id;
  final String artworkID;
  final int index;
  final String name;
  final String category;
  final String ownerAccountID;
  final bool virgin;
  final bool burned;
  final String blockchainStatus;
  final bool isExternal;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isArchived;
  final FFArtwork? artwork;

  ArtworkEdition(
      this.id,
      this.artworkID,
      this.index,
      this.name,
      this.category,
      this.ownerAccountID,
      this.virgin,
      this.burned,
      this.blockchainStatus,
      this.isExternal,
      this.issuedAt,
      this.createdAt,
      this.updatedAt,
      this.isArchived,
      this.artwork);

  factory ArtworkEdition.fromJson(Map<String, dynamic> json) =>
      _$ArtworkEditionFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkEditionToJson(this);
}
