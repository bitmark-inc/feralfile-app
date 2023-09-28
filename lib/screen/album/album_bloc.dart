import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/album/album_screen.dart';
import 'package:autonomy_flutter/screen/album/album_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/database/dao/dao.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/nft_collection.dart';

class AlbumBloc extends Bloc<AlbumEvent, AlbumState> {
  final _assetTokenDao = injector.get<AssetTokenDao>();

  AlbumBloc() : super(AlbumInitState()) {
    on<LoadAlbumEvent>((event, emit) async {
      emit(
        AlbumLoadedState(
          assetTokens: [],
          nftLoadingState: NftLoadingState.loading,
        ),
      );
      if (event.type == AlbumType.artist) {
        final assetTokens = await _assetTokenDao.findAllAssetTokensByArtistID(
          event.id ?? '',
        );
        final tokens = assetTokens
            .map((e) => CompactedAssetToken.fromAssetToken(e))
            .toList();
        emit(
          AlbumLoadedState(
            assetTokens: tokens,
            nftLoadingState: NftLoadingState.done,
          ),
        );
        return;
      }
      if (event.type == AlbumType.medium) {
        final assetTokens = await _assetTokenDao.findAllAssetTokensByMedium(
          event.id ?? '',
        );
        final tokens = assetTokens
            .map((e) => CompactedAssetToken.fromAssetToken(e))
            .toList()
            .where((element) =>
                element.title
                    ?.toLowerCase()
                    .contains(event.filterStr.toLowerCase()) ??
                false)
            .toList();
        emit(
          AlbumLoadedState(
            assetTokens: tokens,
            nftLoadingState: NftLoadingState.done,
          ),
        );
        return;
      }
    });
  }
}
