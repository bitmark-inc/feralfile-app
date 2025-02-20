// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/models/predefined_collection_model.dart';

abstract class CollectionProEvent {}

class CollectionLoadedState {
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
    final newState = CollectionLoadedState(
      listPredefinedCollectionByMedium: listPredefinedCollectionByMedium ??
          this.listPredefinedCollectionByMedium,
      listPredefinedCollectionByArtist: listPredefinedCollectionByArtist ??
          this.listPredefinedCollectionByArtist,
      works: works ?? this.works,
    );
    return newState;
  }
}

class LoadCollectionEvent extends CollectionProEvent {
  String filterStr;

  LoadCollectionEvent({this.filterStr = ''});
}
