import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/database/dao/album_dao.dart';

class CollectionProBloc extends Bloc<CollectionProEvent, CollectionProState> {
  final _ablumDao = injector.get<AlbumDao>();

  CollectionProBloc() : super(CollectionInitState()) {
    on<LoadCollectionEvent>((event, emit) async {
      final listAlbumByMedium =
          await _ablumDao.getAlbumsByMedium(title: event.filterStr);
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
