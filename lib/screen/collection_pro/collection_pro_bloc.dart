import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/collection_pro/album.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/database/dao/album_dao.dart';
import 'package:nft_collection/models/album_model.dart';

class CollectionProBloc extends Bloc<CollectionProEvent, CollectionProState> {
  final _ablumDao = injector.get<AlbumDao>();

  CollectionProBloc() : super(CollectionInitState()) {
    on<LoadCollectionEvent>((event, emit) async {
      final List<AlbumModel> listAlbumByMedium = [];
      final listMedium = [
        MediumCategory.image,
        MediumCategory.video,
        MediumCategory.model,
        MediumCategory.webView,
      ];
      for (final medium in listMedium) {
        final albums = await _ablumDao.getAlbumsByMedium(
            title: event.filterStr,
            mimeTypes: MediumCategory.mineTypes(medium));
        if (albums.isNotEmpty && albums.first.total > 0) {
          final album = albums.first;
          album.name = MediumCategoryExt.getName(medium);
          album.id = medium;
          listAlbumByMedium.add(album);
        }
      }
      final albums = await _ablumDao.getAlbumsByMedium(
          title: event.filterStr,
          mimeTypes: MediumCategoryExt.getAllMimeType(),
          isInMimeTypes: false);

      if (albums.isNotEmpty && albums.first.total > 0) {
        final album = albums.first;
        album.name = MediumCategoryExt.getName(MediumCategory.other);
        album.id = MediumCategory.other;
        listAlbumByMedium.add(album);
      }
      final listAlbumByArtist =
          await _ablumDao.getAlbumsByArtist(name: event.filterStr);
      emit(
        CollectionLoadedState(
          listAlbumByMedium: listAlbumByMedium,
          listAlbumByArtist: listAlbumByArtist,
        ),
      );
    });
  }
}
