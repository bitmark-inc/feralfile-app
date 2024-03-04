import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:collection/collection.dart';

class FFSeries {
  final String id;
  final String artistID;
  final String? assetID;
  final String title;
  final String slug;
  final String medium;
  final String? description;
  final String? thumbnailURI;
  final String exhibitionID;
  final Map<String, dynamic>? metadata;
  final int? displayIndex;
  final int? featuringIndex;
  final FFSeriesSettings? settings;
  final FFArtist? artist;
  final Exhibition? exhibition;
  final AirdropInfo? airdropInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final FileInfo? originalFile;
  final FileInfo? previewFile;
  final Artwork? artwork;
  final String? externalSource;
  final String? uniqueThumbnailPath;
  final String? uniquePreviewPath;
  final String? onchainID;

  FFSeries(
    this.id,
    this.artistID,
    this.assetID,
    this.title,
    this.slug,
    this.medium,
    this.description,
    this.thumbnailURI,
    this.exhibitionID,
    this.metadata,
    this.settings,
    this.artist,
    this.exhibition,
    this.airdropInfo,
    this.createdAt,
    this.displayIndex,
    this.featuringIndex,
    this.updatedAt,
    this.originalFile,
    this.previewFile,
    this.artwork,
    this.externalSource,
    this.uniqueThumbnailPath,
    this.uniquePreviewPath,
    this.onchainID,
  );

  int get maxEdition => settings?.maxArtwork ?? -1;

  FFContract? get contract => exhibition?.contracts
      ?.firstWhereOrNull((e) => e.address == airdropInfo?.contractAddress);

  String getThumbnailURL() => '${Environment.feralFileAssetURL}/$thumbnailURI';

  bool get isAirdropSeries => settings?.isAirdrop == true;

  factory FFSeries.fromJson(Map<String, dynamic> json) => FFSeries(
        json['id'] as String,
        json['artistID'] as String,
        json['assetID'] as String?,
        json['title'] as String,
        json['slug'] as String,
        json['medium'] as String,
        json['description'] as String?,
        json['thumbnailURI'] as String?,
        json['exhibitionID'] as String,
        json['metadata'] as Map<String, dynamic>?,
        json['settings'] == null
            ? null
            : FFSeriesSettings.fromJson(
                json['settings'] as Map<String, dynamic>),
        json['artist'] == null
            ? null
            : FFArtist.fromJson(json['artist'] as Map<String, dynamic>),
        json['exhibition'] == null
            ? null
            : Exhibition.fromJson(json['exhibition'] as Map<String, dynamic>),
        json['airdropInfo'] == null
            ? null
            : AirdropInfo.fromJson(json['airdropInfo'] as Map<String, dynamic>),
        json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
        json['displayIndex'] as int?,
        json['featuringIndex'] as int?,
        json['updatedAt'] == null
            ? null
            : DateTime.parse(json['updatedAt'] as String),
        json['originalFile'] == null
            ? null
            : FileInfo.fromJson(json['originalFile'] as Map<String, dynamic>),
        json['previewFile'] == null
            ? null
            : FileInfo.fromJson(json['previewFile'] as Map<String, dynamic>),
        json['artwork'] == null
            ? null
            : Artwork.fromJson(json['artwork'] as Map<String, dynamic>),
        json['externalSource'] as String?,
        json['uniqueThumbnailPath'] as String?,
        json['uniquePreviewPath'] as String?,
        json['onchainID'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'artistID': artistID,
        'assetID': assetID,
        'title': title,
        'slug': slug,
        'medium': medium,
        'description': description,
        'thumbnailURI': thumbnailURI,
        'exhibitionID': exhibitionID,
        'metadata': metadata,
        'displayIndex': displayIndex,
        'featuringIndex': featuringIndex,
        'settings': settings,
        'artist': artist,
        'exhibition': exhibition,
        'airdropInfo': airdropInfo,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'originalFile': originalFile?.toJson(),
        'previewFile': previewFile?.toJson(),
        'artwork': artwork?.toJson(),
        'externalSource': externalSource,
        'uniqueThumbnailPath': uniqueThumbnailPath,
        'uniquePreviewPath': uniquePreviewPath,
        'onchainID': onchainID,
      };
}

class FFSeriesResponse {
  final FFSeries result;

  FFSeriesResponse(
    this.result,
  );

  factory FFSeriesResponse.fromJson(Map<String, dynamic> json) =>
      FFSeriesResponse(
        FFSeries.fromJson(json['result'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'result': result,
      };
}

class FFSeriesSettings {
  final int maxArtwork;
  final String? saleModel;
  ArtworkModel? artworkModel;

  FFSeriesSettings(this.saleModel, this.maxArtwork, {this.artworkModel});

  factory FFSeriesSettings.fromJson(Map<String, dynamic> json) =>
      FFSeriesSettings(
        json['saleModel'] as String?,
        json['maxArtwork'] as int,
        artworkModel: json['artworkModel'] == null
            ? null
            : ArtworkModel.fromString(json['artworkModel'] as String),
      );

  Map<String, dynamic> toJson() => {
        'maxArtwork': maxArtwork,
        'saleModel': saleModel,
        'artworkModel': artworkModel?.value,
      };

  bool get isAirdrop =>
      ['airdrop', 'shopping_airdrop'].contains(saleModel?.toLowerCase());
}
