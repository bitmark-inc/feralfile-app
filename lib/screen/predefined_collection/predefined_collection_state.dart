// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:autonomy_flutter/screen/predefined_collection/predefined_collection_screen.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/nft_collection/widgets/nft_collection_bloc_event.dart';

abstract class PredefinedCollectionState {}

abstract class PredefinedCollectionEvent {}

class PredefinedCollectionInitState extends PredefinedCollectionState {}

class PredefinedCollectionLoadedState extends PredefinedCollectionState {
  final List<CompactedAssetToken>? assetTokens;
  final NftLoadingState nftLoadingState;

  PredefinedCollectionLoadedState({
    required this.nftLoadingState,
    this.assetTokens,
  });

  PredefinedCollectionLoadedState copyWith({
    List<CompactedAssetToken>? assetTokens,
    NftLoadingState? nftLoadingState,
  }) =>
      PredefinedCollectionLoadedState(
        assetTokens: assetTokens ?? this.assetTokens,
        nftLoadingState: nftLoadingState ?? this.nftLoadingState,
      );
}

class LoadPredefinedCollectionEvent extends PredefinedCollectionEvent {
  final String? id;
  final PredefinedCollectionType type;
  final String filterStr;

  LoadPredefinedCollectionEvent({
    required this.type,
    required this.filterStr,
    this.id,
  });
}
