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

  final String noteTitle;
  final String noteBrief;
  final String note;

  final String? coverURI;
  final String? thumbnailCoverURI;
  final String mintBlockchain;
  final FFCurator? curator;
  final List<FFArtist>? artists;
  final List<FFSeries>? series;
  final List<FFContract>? contracts;
  final FFArtist? partner;
  final String type;
  final List<ExhibitionEvent>? resources;
  final int status;

  Exhibition({
    required this.id,
    required this.title,
    required this.slug,
    required this.exhibitionStartAt,
    required this.noteTitle,
    required this.noteBrief,
    required this.note,
    required this.mintBlockchain,
    required this.type,
    required this.status,
    this.coverURI,
    this.thumbnailCoverURI,
    this.artists,
    this.series,
    this.contracts,
    this.partner,
    this.curator,
    this.resources,
  });

  factory Exhibition.fromJson(Map<String, dynamic> json) => Exhibition(
        id: json['id'] as String,
        title: json['title'] as String,
        slug: json['slug'] as String,
        exhibitionStartAt: DateTime.parse(json['exhibitionStartAt'] as String),
        noteTitle: json['noteTitle'] as String,
        noteBrief: json['noteBrief'] as String,
        note: json['note'] as String,
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
        resources: (json['posts'] as List<dynamic>?)
            ?.map((e) => ExhibitionEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: json['status'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'exhibitionStartAt': exhibitionStartAt.toIso8601String(),
        'noteTitle': noteTitle,
        'noteBrief': noteBrief,
        'note': note,
        'coverURI': coverURI,
        'thumbnailCoverURI': thumbnailCoverURI,
        'artists': artists?.map((e) => e.toJson()).toList(),
        'series': series?.map((e) => e.toJson()).toList(),
        'contracts': contracts?.map((e) => e.toJson()).toList(),
        'mintBlockchain': mintBlockchain,
        'partner': partner?.toJson(),
        'type': type,
        'curator': curator?.toJson(),
        'posts': resources?.map((e) => e.toJson()).toList(),
        'status': status,
      };

  FFArtist? getArtist(FFSeries? series) {
    final artistId = series?.artistID;
    return artists?.firstWhereOrNull((artist) => artist.id == artistId);
  }

  String getThumbnailURL() =>
      '${Environment.feralFileAssetURL}/$thumbnailCoverURI';

  Exhibition copyWith({
    String? id,
    String? title,
    String? slug,
    DateTime? exhibitionStartAt,
    String? noteTitle,
    String? noteBrief,
    String? note,
    String? coverURI,
    String? thumbnailCoverURI,
    String? mintBlockchain,
    FFCurator? curator,
    List<FFArtist>? artists,
    List<FFSeries>? series,
    List<FFContract>? contracts,
    FFArtist? partner,
    String? type,
    List<ExhibitionEvent>? resources,
    int? status,
  }) =>
      Exhibition(
        id: id ?? this.id,
        title: title ?? this.title,
        slug: slug ?? this.slug,
        exhibitionStartAt: exhibitionStartAt ?? this.exhibitionStartAt,
        noteTitle: noteTitle ?? this.noteTitle,
        noteBrief: noteBrief ?? this.noteBrief,
        note: note ?? this.note,
        coverURI: coverURI ?? this.coverURI,
        thumbnailCoverURI: thumbnailCoverURI ?? this.thumbnailCoverURI,
        mintBlockchain: mintBlockchain ?? this.mintBlockchain,
        curator: curator ?? this.curator,
        artists: artists ?? this.artists,
        series: series ?? this.series,
        contracts: contracts ?? this.contracts,
        partner: partner ?? this.partner,
        type: type ?? this.type,
        resources: resources ?? this.resources,
        status: status ?? this.status,
      );
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

  ExhibitionDetail copyWith({
    Exhibition? exhibition,
    List<Artwork>? artworks,
  }) =>
      ExhibitionDetail(
        exhibition: exhibition ?? this.exhibition,
        artworks: artworks ?? this.artworks,
      );
}

class ExhibitionEvent {
  final String id;
  final String exhibitionID;
  final String type;
  final String title;
  final DateTime? dateTime;
  final String? description;
  final Map<String, String>? links;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MediaUri? mediaUri;

  ExhibitionEvent({
    required this.id,
    required this.exhibitionID,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.dateTime,
    this.description,
    this.links,
    this.mediaUri,
  });

  factory ExhibitionEvent.fromJson(Map<String, dynamic> json) =>
      ExhibitionEvent(
        id: json['id'],
        exhibitionID: json['exhibitionID'],
        type: json['type'],
        title: json['title'],
        dateTime: DateTime.tryParse(json['dateTime'] ?? ''),
        description: json['description'],
        links: Map<String, String>.from(json['links'] ?? {}),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        mediaUri: json['mediaUri'] == null
            ? null
            : MediaUri.fromJson(json['mediaUri'] as Map<String, dynamic>),
      );

  // toJson
  Map<String, dynamic> toJson() => {
        'id': id,
        'exhibitionID': exhibitionID,
        'type': type,
        'title': title,
        'dateTime': dateTime?.toIso8601String(),
        'description': description,
        'links': links,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'mediaUri': mediaUri?.toJson(),
      };
}

class MediaUri {
  final String url;
  final String type;
  final String? title;

  MediaUri({
    required this.url,
    required this.type,
    this.title,
  });

  factory MediaUri.fromJson(Map<String, dynamic> json) => MediaUri(
        url: json['url'],
        type: json['type'],
        title: json['title'],
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type,
        'title': title,
      };
}
