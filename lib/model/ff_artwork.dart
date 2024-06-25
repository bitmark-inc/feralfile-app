//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nft_rendering/nft_rendering.dart';

part 'ff_artwork.g.dart';

@JsonSerializable()
class ArtworkResponse {
  final Artwork result;

  ArtworkResponse(this.result);

  factory ArtworkResponse.fromJson(Map<String, dynamic> json) =>
      _$ArtworkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkResponseToJson(this);
}

@JsonSerializable()
class Artwork {
  final String id;
  final String seriesID;
  final int index;
  final String name;
  final String? category;
  final String? ownerAccountID;
  final bool? virgin;
  final bool? burned;
  final String? blockchainStatus;
  final bool? isExternal;
  final String thumbnailURI;
  final String previewURI;
  final Map<String, dynamic>? metadata;
  final DateTime? mintedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isArchived;
  final FFSeries? series;
  final ArtworkSwap? swap;
  final List<ArtworkAttribute>? artworkAttributes;

  Artwork(
      this.id,
      this.seriesID,
      this.index,
      this.name,
      this.category,
      this.ownerAccountID,
      this.virgin,
      this.burned,
      this.blockchainStatus,
      this.isExternal,
      this.thumbnailURI,
      this.previewURI,
      this.metadata,
      this.mintedAt,
      this.createdAt,
      this.updatedAt,
      this.isArchived,
      this.series,
      this.swap,
      this.artworkAttributes);

  factory Artwork.fromJson(Map<String, dynamic> json) => Artwork(
        json['id'] as String,
        json['seriesID'] as String,
        json['index'] as int,
        json['name'] as String,
        json['category'] as String?,
        json['ownerAccountID'] as String?,
        json['virgin'] as bool?,
        json['burned'] as bool?,
        json['blockchainStatus'] as String?,
        json['isExternal'] as bool?,
        json['thumbnailURI'] as String,
        json['previewURI'] as String,
        json['metadata'] as Map<String, dynamic>?,
        json['mintedAt'] == null || (json['mintedAt'] as String).isEmpty
            ? null
            : DateTime.parse(json['mintedAt'] as String),
        json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
        json['updatedAt'] == null
            ? null
            : DateTime.parse(json['updatedAt'] as String),
        json['isArchived'] as bool?,
        json['series'] == null
            ? null
            : FFSeries.fromJson(json['series'] as Map<String, dynamic>),
        json['swap'] == null
            ? null
            : ArtworkSwap.fromJson(json['swap'] as Map<String, dynamic>),
        json['artworkAttributes'] == null
            ? null
            : (json['artworkAttributes'] as List<dynamic>)
                .map(
                    (e) => ArtworkAttribute.fromJson(e as Map<String, dynamic>))
                .toList(),
      );

  Map<String, dynamic> toJson() => _$ArtworkToJson(this);

  // copyWith method
  Artwork copyWith({
    String? id,
    String? seriesID,
    int? index,
    String? name,
    String? category,
    String? ownerAccountID,
    bool? virgin,
    bool? burned,
    String? blockchainStatus,
    bool? isExternal,
    String? thumbnailURI,
    String? previewURI,
    Map<String, dynamic>? metadata,
    DateTime? mintedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    FFSeries? series,
    ArtworkSwap? swap,
    List<ArtworkAttribute>? artworkAttributes,
  }) =>
      Artwork(
        id ?? this.id,
        seriesID ?? this.seriesID,
        index ?? this.index,
        name ?? this.name,
        category ?? this.category,
        ownerAccountID ?? this.ownerAccountID,
        virgin ?? this.virgin,
        burned ?? this.burned,
        blockchainStatus ?? this.blockchainStatus,
        isExternal ?? this.isExternal,
        thumbnailURI ?? this.thumbnailURI,
        previewURI ?? this.previewURI,
        metadata ?? this.metadata,
        mintedAt ?? this.mintedAt,
        createdAt ?? this.createdAt,
        updatedAt ?? this.updatedAt,
        isArchived ?? this.isArchived,
        series ?? this.series,
        swap ?? this.swap,
        artworkAttributes ?? this.artworkAttributes,
      );

  static Artwork createFake(
          String thumbNailURI, String previewURI, String medium) =>
      Artwork(
        'id',
        'seriesID',
        0,
        'name',
        'category',
        'ownerAccountID',
        false,
        false,
        'blockchainStatus',
        false,
        thumbNailURI,
        previewURI,
        {},
        DateTime.now(),
        DateTime.now(),
        DateTime.now(),
        false,
        FFSeries(
          'id',
          'artistID',
          'assetID',
          'title',
          'slug',
          medium,
          'description',
          'thumbnailURI',
          'exhibitionID',
          {},
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ),
        null,
        null,
      );
}

class ArtworkSwap {
  final String id;
  final String artworkID;
  final String seriesID;
  final String? paymentID;
  final double? fee;
  final String currency;
  final int artworkIndex;
  final String ownerAccount;
  final String status;
  final String contractName;
  final String contractAddress;
  final String recipientAddress;
  final String? ipfsCid;
  final String? token;
  final String blockchainType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiredAt;

  // Constructor
  ArtworkSwap({
    required this.id,
    required this.artworkID,
    required this.seriesID,
    required this.currency,
    required this.artworkIndex,
    required this.ownerAccount,
    required this.status,
    required this.contractName,
    required this.contractAddress,
    required this.recipientAddress,
    required this.blockchainType,
    required this.createdAt,
    required this.updatedAt,
    required this.expiredAt,
    this.ipfsCid,
    this.token,
    this.paymentID,
    this.fee,
  });

  // Factory method to create an ArtworkSwap instance from JSON
  factory ArtworkSwap.fromJson(Map<String, dynamic> json) => ArtworkSwap(
        id: json['id'],
        artworkID: json['artworkID'],
        seriesID: json['seriesID'],
        paymentID: json['paymentID'],
        fee: json['fee']?.toDouble(),
        currency: json['currency'],
        artworkIndex: json['artworkIndex'],
        ownerAccount: json['ownerAccount'],
        status: json['status'],
        contractName: json['contractName'],
        contractAddress: json['contractAddress'],
        recipientAddress: json['recipientAddress'],
        ipfsCid: json['ipfsCid'],
        token: json['token'],
        blockchainType: json['blockchainType'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        expiredAt: DateTime.parse(json['expiredAt']),
      );

  // Method to convert ArtworkSwap instance to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'artworkID': artworkID,
        'seriesID': seriesID,
        'paymentID': paymentID,
        'fee': fee,
        'currency': currency,
        'artworkIndex': artworkIndex,
        'ownerAccount': ownerAccount,
        'status': status,
        'contractName': contractName,
        'contractAddress': contractAddress,
        'recipientAddress': recipientAddress,
        'ipfsCid': ipfsCid,
        'token': token,
        'blockchainType': blockchainType,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'expiredAt': expiredAt.toIso8601String(),
      };
}

@JsonSerializable()
class ArtworkAttribute {
  final String id;
  final String artworkID;
  final String seriesID;
  final int index;
  final double percentage;
  final String traitType;
  final String value;

  ArtworkAttribute({
    required this.id,
    required this.artworkID,
    required this.seriesID,
    required this.index,
    required this.percentage,
    required this.traitType,
    required this.value,
  });

  factory ArtworkAttribute.fromJson(Map<String, dynamic> json) =>
      _$ArtworkAttributeFromJson(json);
}

enum FeralfileMediumTypes {
  unknown,
  image,
  video,
  software,
  pdf,
  audio,
  model,
  animatedGif,
  txt,
  ;

  static FeralfileMediumTypes fromString(String type) {
    switch (type) {
      case 'image':
        return FeralfileMediumTypes.image;
      case 'video':
        return FeralfileMediumTypes.video;
      case 'software':
        return FeralfileMediumTypes.software;
      case 'pdf':
        return FeralfileMediumTypes.pdf;
      case 'audio':
        return FeralfileMediumTypes.audio;
      case '3d':
        return FeralfileMediumTypes.model;
      case 'animated gif':
        return FeralfileMediumTypes.animatedGif;
      case 'txt':
        return FeralfileMediumTypes.txt;
      default:
        return FeralfileMediumTypes.unknown;
    }
  }

  String get toRenderingType {
    switch (this) {
      case FeralfileMediumTypes.image:
        return RenderingType.image;
      case FeralfileMediumTypes.video:
        return RenderingType.video;
      case FeralfileMediumTypes.software:
        return RenderingType.webview;
      case FeralfileMediumTypes.pdf:
        return RenderingType.pdf;
      case FeralfileMediumTypes.audio:
        return RenderingType.audio;
      case FeralfileMediumTypes.model:
        return RenderingType.modelViewer;
      case FeralfileMediumTypes.animatedGif:
        return RenderingType.gif;
      case FeralfileMediumTypes.txt:
        return RenderingType.webview;
      default:
        return RenderingType.webview;
    }
  }
}

// Support for John Gerrard show
class BeforeMintingArtworkInfo {
  final int index;
  final String viewableAt;
  final String artworkTitle;

  BeforeMintingArtworkInfo({
    required this.index,
    required this.viewableAt,
    required this.artworkTitle,
  });

  factory BeforeMintingArtworkInfo.fromJson(Map<String, dynamic> json) =>
      BeforeMintingArtworkInfo(
        index: json['index'],
        viewableAt: json['viewableAt'],
        artworkTitle: json['artworkTitle'],
      );
}
