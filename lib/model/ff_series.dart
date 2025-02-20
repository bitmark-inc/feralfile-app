import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/nft_collection/models/user_collection.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class SecondaryMarket {
  SecondaryMarket(this.name, this.url);

  factory SecondaryMarket.fromJson(Map<String, dynamic> json) =>
      SecondaryMarket(
        json['name'] as String,
        json['url'] as String,
      );
  final String name;
  final String url;

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
      };
}

class FFSeries extends ArtistCollection {
  FFSeries(
    this.id,
    this.artistAlumniAccountID,
    this.assetID,
    this.title,
    this.slug,
    this.medium,
    this.description,
    this.thumbnailURI,
    this.thumbnailDisplay,
    this.exhibitionID,
    this.metadata,
    this.settings,
    this.artistAlumni,
    this.exhibition,
    this.createdAt,
    this.mintedAt,
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
    this.artworks,
  );

  factory FFSeries.fromJson(Map<String, dynamic> json) => FFSeries(
        json['id'] as String,
        json['artistAlumniAccountID'] as String,
        json['assetID'] as String?,
        json['title'] as String,
        json['slug'] as String?,
        json['medium'] as String,
        json['description'] as String?,
        json['thumbnailURI'] as String,
        json['thumbnailDisplay'] as String?,
        json['exhibitionID'] as String,
        json['metadata'] as Map<String, dynamic>?,
        json['settings'] == null
            ? null
            : FFSeriesSettings.fromJson(
                json['settings'] as Map<String, dynamic>,
              ),
        json['artistAlumni'] == null
            ? null
            : AlumniAccount.fromJson(
                json['artistAlumni'] as Map<String, dynamic>,
              ),
        json['exhibition'] == null
            ? null
            : Exhibition.fromJson(json['exhibition'] as Map<String, dynamic>),
        json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
        json['mintedAt'] == null
            ? null
            : DateTime.parse(json['mintedAt'] as String),
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
        json['artworks'] == null
            ? null
            : (json['artworks'] as List)
                .map((e) => Artwork.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
  final String id;
  final String artistAlumniAccountID;
  final String? assetID;
  final String title;
  final String? slug;
  final String medium;
  final String? description;
  final String thumbnailURI;
  final String? thumbnailDisplay;
  final String exhibitionID;
  final Map<String, dynamic>? metadata;
  final int? displayIndex;
  final int? featuringIndex;
  final FFSeriesSettings? settings;
  final AlumniAccount? artistAlumni;
  final Exhibition? exhibition;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? mintedAt;
  final FileInfo? originalFile;
  final FileInfo? previewFile;
  final Artwork? artwork;
  final String? externalSource;
  final String? uniqueThumbnailPath;
  final String? uniquePreviewPath;
  final String? onchainID;
  final List<Artwork>? artworks;

  int get maxEdition => settings?.maxArtwork ?? -1;

  bool get isAirdropSeries => settings?.isAirdrop == true;

  Map<String, dynamic> toJson() => {
        'id': id,
        'artistAlumniAccountID': artistAlumniAccountID,
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
        'artistAlumni': artistAlumni,
        'exhibition': exhibition,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'mintedAt': mintedAt?.toIso8601String(),
        'originalFile': originalFile?.toJson(),
        'previewFile': previewFile?.toJson(),
        'artwork': artwork?.toJson(),
        'externalSource': externalSource,
        'uniqueThumbnailPath': uniqueThumbnailPath,
        'uniquePreviewPath': uniquePreviewPath,
        'onchainID': onchainID,
      };

  FFSeries copyWith({
    String? id,
    String? artistAlumniAccountID,
    String? assetID,
    String? title,
    String? slug,
    String? medium,
    String? description,
    String? thumbnailURI,
    String? thumbnailDisplay,
    String? exhibitionID,
    Map<String, dynamic>? metadata,
    int? displayIndex,
    int? featuringIndex,
    FFSeriesSettings? settings,
    AlumniAccount? artistAlumni,
    Exhibition? exhibition,
    DateTime? createdAt,
    DateTime? mintedAt,
    DateTime? updatedAt,
    FileInfo? originalFile,
    FileInfo? previewFile,
    Artwork? artwork,
    String? externalSource,
    String? uniqueThumbnailPath,
    String? uniquePreviewPath,
    String? onchainID,
    List<Artwork>? artworks,
  }) =>
      FFSeries(
        id ?? this.id,
        artistAlumniAccountID ?? this.artistAlumniAccountID,
        assetID ?? this.assetID,
        title ?? this.title,
        slug ?? this.slug,
        medium ?? this.medium,
        description ?? this.description,
        thumbnailURI ?? this.thumbnailURI,
        thumbnailDisplay ?? this.thumbnailDisplay,
        exhibitionID ?? this.exhibitionID,
        metadata ?? this.metadata,
        settings ?? this.settings,
        artistAlumni ?? this.artistAlumni,
        exhibition ?? this.exhibition,
        createdAt ?? this.createdAt,
        mintedAt ?? this.mintedAt,
        displayIndex ?? this.displayIndex,
        featuringIndex ?? this.featuringIndex,
        updatedAt ?? this.updatedAt,
        originalFile ?? this.originalFile,
        previewFile ?? this.previewFile,
        artwork ?? this.artwork,
        externalSource ?? this.externalSource,
        uniqueThumbnailPath ?? this.uniqueThumbnailPath,
        uniquePreviewPath ?? this.uniquePreviewPath,
        onchainID ?? this.onchainID,
        artworks ?? this.artworks,
      );
}

class FFSeriesResponse {
  FFSeriesResponse(
    this.result,
  );

  factory FFSeriesResponse.fromJson(Map<String, dynamic> json) =>
      FFSeriesResponse(
        FFSeries.fromJson(json['result'] as Map<String, dynamic>),
      );
  final FFSeries result;

  Map<String, dynamic> toJson() => {
        'result': result,
      };
}

class FFSeriesSettings {
  FFSeriesSettings(
    this.saleModel,
    this.maxArtwork, {
    this.artworkModel,
    this.artistReservation = 0,
    this.publisherProof = 0,
    this.promotionalReservation = 0,
    this.tradeSeries = false,
    this.transferToCurator = false,
  });

  factory FFSeriesSettings.fromJson(Map<String, dynamic> json) =>
      FFSeriesSettings(
        json['saleModel'] as String?,
        json['maxArtwork'] as int,
        artworkModel: json['artworkModel'] == null
            ? null
            : ArtworkModel.fromString(json['artworkModel'] as String),
        artistReservation: json['artistReservation'] as int? ?? 0,
        publisherProof: json['publisherProof'] as int? ?? 0,
        promotionalReservation: json['promotionalReservation'] as int? ?? 0,
        tradeSeries: json['tradeSeries'] as bool?,
        transferToCurator: json['transferToCurator'] as bool?,
      );
  final int maxArtwork;
  final String? saleModel;
  ArtworkModel? artworkModel;
  int artistReservation;
  int publisherProof;
  int promotionalReservation;
  bool? tradeSeries;
  bool? transferToCurator;

  Map<String, dynamic> toJson() => {
        'maxArtwork': maxArtwork,
        'saleModel': saleModel,
        'artworkModel': artworkModel?.value,
      };

  bool get isAirdrop =>
      ['airdrop', 'shopping_airdrop'].contains(saleModel?.toLowerCase());
}
