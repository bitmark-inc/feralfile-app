import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/medium_category_ext.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/database/dao/predefined_collection_dao.dart';
import 'package:nft_collection/models/album_model.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/utils/medium_category.dart';

class CollectionProBloc extends Bloc<CollectionProEvent, CollectionProState> {
  final _predefinedCollectionDao = injector.get<PredefinedCollectionDao>();
  final _configurationService = injector.get<ConfigurationService>();
  final _assetTokenDao = injector.get<AssetTokenDao>();

  CollectionProBloc() : super(CollectionInitState()) {
    on<LoadCollectionEvent>((event, emit) async {
      final List<AlbumModel> listAlbumByMedium =
          await _getAllAlbumByMedium(filterStr: event.filterStr);
      final listAlbumByArtist =
          await _predefinedCollectionDao.getAlbumsByArtist();

      final hiddenTokenIDs = _configurationService.getHiddenOrSentTokenIDs();
      final hiddenTokens =
          await _assetTokenDao.findAllAssetTokensByTokenIDs(hiddenTokenIDs);
      for (final album in listAlbumByMedium) {
        final ignoreTokens = hiddenTokens.where((element) {
          if (album.id == MediumCategory.other) {
            return !MediumCategoryExt.getAllMimeType()
                .contains(element.mimeType);
          }
          return MediumCategory.mineTypes(album.id).contains(element.mimeType);
        }).toList();
        album.total = album.total - ignoreTokens.length;
      }
      for (final album in listAlbumByArtist) {
        final ignoreTokens = hiddenTokens
            .where((element) => element.artistID == album.id)
            .toList();
        album.total = album.total - ignoreTokens.length;
      }
      listAlbumByArtist.removeWhere((element) => element.total <= 0);
      listAlbumByMedium.removeWhere((element) => element.total <= 0);
      List<CompactedAssetToken> works =
          await _getAllTokenFilterByTitleOrArtist(filterStr: event.filterStr);
      emit(
        CollectionLoadedState(
          listAlbumByMedium: listAlbumByMedium,
          listAlbumByArtist: listAlbumByArtist,
          works: works,
        ),
      );
    });
  }

  Future<List<AlbumModel>> _getAllAlbumByMedium({String filterStr = ""}) async {
    final List<AlbumModel> listAlbumByMedium = [];
    final listMedium = MediumCategoryExt.getAllCategories();
    for (final mediumCatelog in listMedium) {
      final albums = await _predefinedCollectionDao.getAlbumsByMedium(
        title: filterStr,
        mimeTypes: MediumCategory.mineTypes(mediumCatelog),
        mediums: MediumCategoryExt.mediums(mediumCatelog),
      );
      if (albums.isNotEmpty && albums.first.total > 0) {
        final album = albums.first;
        album.name = MediumCategoryExt.getName(mediumCatelog);
        album.id = mediumCatelog;
        listAlbumByMedium.add(album);
      }
    }
    final albums = await _predefinedCollectionDao.getAlbumsByMedium(
        title: filterStr,
        mimeTypes: MediumCategoryExt.getAllMimeType(),
        mediums: MediumCategoryExt.getAllMediums(),
        isInMimeTypes: false);

    if (albums.isNotEmpty && albums.first.total > 0) {
      final album = albums.first;
      album.name = MediumCategoryExt.getName(MediumCategory.other);
      album.id = MediumCategory.other;
      listAlbumByMedium.add(album);
    }
    return listAlbumByMedium;
  }

  Future<List<CompactedAssetToken>> _getAllTokenFilterByTitleOrArtist(
      {String filterStr = ""}) async {
    List<CompactedAssetToken> works = [];
    final hiddenTokenIDs = _configurationService.getHiddenOrSentTokenIDs();
    if (filterStr.isNotEmpty) {
      final assetTokens =
          await _assetTokenDao.findAllAssetTokensByFilter(filter: filterStr);
      assetTokens.removeWhere((element) =>
          hiddenTokenIDs.contains(element.id) || (element.balance ?? 0) <= 0);
      works = assetTokens
          .map((e) => CompactedAssetToken.fromAssetToken(e))
          .toList();
    }
    return works;
  }
}
