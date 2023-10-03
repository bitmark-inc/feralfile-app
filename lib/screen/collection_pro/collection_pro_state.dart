// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:nft_collection/models/album_model.dart';
import 'package:nft_collection/models/asset_token.dart';

abstract class CollectionProState {}

abstract class CollectionProEvent {}

class CollectionInitState extends CollectionProState {}

class CollectionLoadedState extends CollectionProState {
  final List<AlbumModel>? listAlbumByMedium;
  final List<AlbumModel>? listAlbumByArtist;
  final List<CompactedAssetToken> works;

  CollectionLoadedState({
    this.listAlbumByMedium,
    this.listAlbumByArtist,
    this.works = const [],
  });

  CollectionLoadedState copyWith({
    List<AlbumModel>? listAlbumByMedium,
    List<AlbumModel>? listAlbumByArtist,
    List<CompactedAssetToken>? works,
  }) {
    return CollectionLoadedState(
      listAlbumByMedium: listAlbumByMedium ?? this.listAlbumByMedium,
      listAlbumByArtist: listAlbumByArtist ?? this.listAlbumByArtist,
      works: works ?? this.works,
    );
  }
}

class CollectionLoadingState extends CollectionProState {}

class LoadCollectionEvent extends CollectionProEvent {
  String filterStr;

  LoadCollectionEvent({this.filterStr = ""});
}
