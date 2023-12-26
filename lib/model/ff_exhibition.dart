import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:collection/collection.dart';

class Exhibition {
  final String id;
  final String title;
  final String slug;
  final DateTime exhibitionStartAt;

  // final DateTime? exhibitionEndAt;
  final String? coverURI;
  final String? thumbnailCoverURI;
  final String mintBlockchain;
  final FFCurator? curator;
  final List<FFArtist>? artists;
  final List<FFSeries>? series;
  final List<FFContract>? contracts;
  final FFArtist? partner;
  final String type;

  Exhibition({
    required this.id,
    required this.title,
    required this.slug,
    required this.exhibitionStartAt,
    required this.mintBlockchain,
    required this.type, // this.exhibitionEndAt,
    this.coverURI,
    this.thumbnailCoverURI,
    this.artists,
    this.series,
    this.contracts,
    this.partner,
    this.curator,
  });

  factory Exhibition.fromJson(Map<String, dynamic> json) => Exhibition(
        id: json['id'] as String,
        title: json['title'] as String,
        slug: json['slug'] as String,
        exhibitionStartAt: DateTime.parse(json['exhibitionStartAt'] as String),
        coverURI: json['coverURI'] as String?,
        thumbnailCoverURI: json['thumbnailCoverURI'] as String?,
        artists: (json['artists'] as List<dynamic>?)
            ?.map((e) => FFArtist.fromJson(e as Map<String, dynamic>))
            .toList(),
        series: (json['series'] as List<dynamic>?)
            ?.map((e) => FFSeries.fromJson(e as Map<String, dynamic>))
            .toList(),
        contracts: (json['contracts'] as List<dynamic>?)
            ?.map((e) => FFContract.fromJson(e as Map<String, dynamic>))
            .toList(),
        mintBlockchain: json['mintBlockchain'] as String,
        partner: json['partner'] == null
            ? null
            : FFArtist.fromJson(json['partner'] as Map<String, dynamic>),
        type: json['type'] as String,
        curator: json['curator'] == null
            ? null
            : FFCurator.fromJson(json['curator'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'exhibitionStartAt': exhibitionStartAt.toIso8601String(),
        'coverURI': coverURI,
        'thumbnailCoverURI': thumbnailCoverURI,
        'artists': artists?.map((e) => e.toJson()).toList(),
        'series': series?.map((e) => e.toJson()).toList(),
        'contracts': contracts?.map((e) => e.toJson()).toList(),
        'mintBlockchain': mintBlockchain,
        'partner': partner?.toJson(),
        'type': type,
        'curator': curator?.toJson(),
        // 'exhibitionEndAt': exhibitionEndAt?.toIso8601String(),
      };

  FFArtist? getArtist(FFSeries? series) {
    final artistId = series?.artistID;
    return artists?.firstWhereOrNull((artist) => artist.id == artistId);
  }

  String getThumbnailURL() =>
      '${Environment.feralFileAssetURL}/$thumbnailCoverURI';
}

class ExhibitionResponse {
  final Exhibition result;

  ExhibitionResponse(this.result);

  factory ExhibitionResponse.fromJson(Map<String, dynamic> json) =>
      ExhibitionResponse(
        Exhibition.fromJson(json['result'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'result': result,
      };
}

class ListExhibitionResponse {
  final List<Exhibition> result;

  ListExhibitionResponse(this.result);

  factory ListExhibitionResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['result'];
    return ListExhibitionResponse(
        list.map((e) => Exhibition.fromJson(e)).toList());
  }
}

class ExhibitionDetail {
  final Exhibition exhibition;
  List<Artwork>? artworks;

  ExhibitionDetail({required this.exhibition, this.artworks});
}
