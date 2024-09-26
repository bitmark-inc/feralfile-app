import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

class PlayListModel {
  String? id;
  String? name;
  String? thumbnailURL;
  List<String>? tokenIDs;

  PlayListModel({
    this.id,
    this.name,
    this.thumbnailURL,
    this.tokenIDs,
  });

  PlayListModel copyWith({
    String? id,
    String? name,
    String? thumbnailURL,
    List<String>? tokenIDs,
  }) =>
      PlayListModel(
        id: id ?? this.id,
        name: name ?? this.name,
        thumbnailURL: thumbnailURL ?? this.thumbnailURL,
        tokenIDs: tokenIDs ?? this.tokenIDs,
      );

  @override
  String toString() =>
      'PlayListModel(id: $id, name: $name, thumbnailURL: $thumbnailURL, '
      'tokenIDs: $tokenIDs)';

  @override
  bool operator ==(covariant PlayListModel other) {
    if (identical(this, other)) {
      return true;
    }

    return other.id == id &&
        other.name == name &&
        other.thumbnailURL == thumbnailURL &&
        listEquals(other.tokenIDs, tokenIDs);
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ thumbnailURL.hashCode ^ tokenIDs.hashCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'thumbnailURL': thumbnailURL,
        'tokenIDs': tokenIDs
      };

  factory PlayListModel.fromJson(Map<String, dynamic> map) => PlayListModel(
        id: map['id'] != null ? map['id'] as String : null,
        name: map['name'] != null ? map['name'] as String : null,
        thumbnailURL:
            map['thumbnailURL'] != null ? map['thumbnailURL'] as String : null,
        tokenIDs: map['tokenIDs'] != null
            ? List<String>.from(map['tokenIDs'] as List<dynamic>)
            : null,
      );

  String getName() => name ?? tr('untitled');
}

extension PlayListModelExtension on PlayListModel {
  bool get isDefault {
    final defaultPlaylists = DefaultPlaylistModel.getAll();
    return defaultPlaylists.any((element) => element.id == id);
  }
}

enum DefaultPlaylistModel {
  allNfts;

  String get id {
    switch (this) {
      case DefaultPlaylistModel.allNfts:
        return 'all_nfts';
    }
  }

  String get name {
    switch (this) {
      case DefaultPlaylistModel.allNfts:
        return 'all'.tr();
    }
  }

  static List<DefaultPlaylistModel> getAll() => [
        DefaultPlaylistModel.allNfts,
      ];
}
