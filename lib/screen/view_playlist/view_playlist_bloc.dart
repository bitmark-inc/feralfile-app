import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/view_playlist/view_playlist_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewPlaylistBloc extends Bloc<ViewPlaylistEvent, ViewPlaylistState> {
  ViewPlaylistBloc() : super(ViewPlaylistState()) {
    on<GetPlayList>((event, emit) {
      emit(
        ViewPlaylistState(
          playListModel:
              PlayListModel(tokenIDs: [], thumbnailURL: '', name: ''),
        ),
      );
    });
  }
}
