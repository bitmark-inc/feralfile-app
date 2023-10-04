import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/album/album_screen.dart';
import 'package:autonomy_flutter/screen/album/album_state.dart';
import 'package:autonomy_flutter/screen/collection_pro/album.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/database/dao/album_dao.dart';
import 'package:nft_collection/database/dao/dao.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/nft_collection.dart';

class AlbumBloc extends Bloc<AlbumEvent, AlbumState> {
  final _assetTokenDao = injector.get<AssetTokenDao>();
  final _configurationService = injector.get<ConfigurationService>();

  AlbumBloc() : super(AlbumInitState()) {
    on<LoadAlbumEvent>((event, emit) async {
      emit(
        AlbumLoadedState(
          assetTokens: [],
          nftLoadingState: NftLoadingState.loading,
        ),
      );
      List<AssetToken> assetTokens = [];
      if (event.type == AlbumType.artist) {
        assetTokens = await _assetTokenDao.findAllAssetTokensByArtistID(
          artistID: event.id ?? '',
        );
      }
      if (event.type == AlbumType.medium) {
        final isOther = event.id == MediumCategory.other;
        final mimeTypes = isOther
            ? MediumCategoryExt.getAllMimeType()
            : MediumCategory.mineTypes(event.id ?? '');
        assetTokens = await _assetTokenDao.findAllAssetTokensByMimeTypes(
          mimeTypes: mimeTypes,
          isInMimeTypes: !isOther,
        );
      }
      final hiddenTokenIDs = _configurationService.getHiddenOrSentTokenIDs();
      assetTokens.removeWhere((element) => hiddenTokenIDs.contains(element.id));
      final isFilterByTokenTitle = event.type == AlbumType.medium;
      final tokens = assetTokens
          .map((e) => CompactedAssetToken.fromAssetToken(e))
          .toList()
          .where(
            (element) =>
                !isFilterByTokenTitle ||
                (element.title
                        ?.toLowerCase()
                        .contains(event.filterStr.toLowerCase()) ??
                    false),
          )
          .toList();
      emit(
        AlbumLoadedState(
          assetTokens: tokens,
          nftLoadingState: NftLoadingState.done,
        ),
      );
      return;
    });
  }
}
