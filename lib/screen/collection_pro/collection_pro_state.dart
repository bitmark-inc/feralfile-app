// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/predefined_collection_model.dart';

abstract class CollectionProState {}

abstract class CollectionProEvent {}

class CollectionInitState extends CollectionProState {}

class CollectionLoadedState extends CollectionProState {
  final List<PredefinedCollectionModel>? listPredefinedCollectionByMedium;
  final List<PredefinedCollectionModel>? listPredefinedCollectionByArtist;
  final List<CompactedAssetToken> works;

  CollectionLoadedState({
    this.listPredefinedCollectionByMedium,
    this.listPredefinedCollectionByArtist,
    this.works = const [],
  });

  CollectionLoadedState copyWith({
    List<PredefinedCollectionModel>? listPredefinedCollectionByMedium,
    List<PredefinedCollectionModel>? listPredefinedCollectionByArtist,
    List<CompactedAssetToken>? works,
  }) {
    return CollectionLoadedState(
      listPredefinedCollectionByMedium:
          listPredefinedCollectionByMedium ?? listPredefinedCollectionByMedium,
      listPredefinedCollectionByArtist:
          listPredefinedCollectionByArtist ?? listPredefinedCollectionByArtist,
      works: works ?? this.works,
    );
  }
}

class CollectionLoadingState extends CollectionProState {}

class LoadCollectionEvent extends CollectionProEvent {
  String filterStr;

  LoadCollectionEvent({this.filterStr = ""});
}
