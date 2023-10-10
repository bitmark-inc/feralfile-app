import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

class PlayListModel {
  String? id;
  String? name;
  String? thumbnailURL;
  List<String>? tokenIDs;
  PlayControlModel? playControlModel;

  PlayListModel({
    this.id,
    this.name,
    this.thumbnailURL,
    this.tokenIDs,
    this.playControlModel,
  });

  PlayListModel copyWith({
    String? id,
    String? name,
    String? thumbnailURL,
    List<String>? tokenIDs,
    PlayControlModel? playControlModel,
  }) {
    return PlayListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbnailURL: thumbnailURL ?? this.thumbnailURL,
      tokenIDs: tokenIDs ?? this.tokenIDs,
      playControlModel: playControlModel ?? this.playControlModel,
    );
  }

  @override
  String toString() {
    return 'PlayListModel(id: $id, name: $name, thumbnailURL: $thumbnailURL, tokenIDs: $tokenIDs, playControlModel: $playControlModel)';
  }

  @override
  bool operator ==(covariant PlayListModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.thumbnailURL == thumbnailURL &&
        listEquals(other.tokenIDs, tokenIDs) &&
        other.playControlModel == playControlModel;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        thumbnailURL.hashCode ^
        tokenIDs.hashCode ^
        playControlModel.hashCode;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'thumbnailURL': thumbnailURL,
      'tokenIDs': tokenIDs,
      'playControlModel': playControlModel?.toJson(),
    };
  }

  factory PlayListModel.fromJson(Map<String, dynamic> map) {
    return PlayListModel(
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      thumbnailURL:
          map['thumbnailURL'] != null ? map['thumbnailURL'] as String : null,
      tokenIDs: map['tokenIDs'] != null
          ? List<String>.from((map['tokenIDs'] as List<dynamic>))
          : null,
      playControlModel: map['playControlModel'] != null
          ? PlayControlModel.fromJson(
              map['playControlModel'] as Map<String, dynamic>)
          : null,
    );
  }

  String getName() {
    return name ?? tr('untitled');
  }
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
        return "all_nfts";
    }
  }

  String get name {
    switch (this) {
      case DefaultPlaylistModel.allNfts:
        return "all".tr();
    }
  }

  static List<DefaultPlaylistModel> getAll() {
    return [
      DefaultPlaylistModel.allNfts,
    ];
  }
}
