import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/service/dp1_playlist_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'playlists_event.dart';
part 'playlists_state.dart';

class PlaylistsBloc extends AuBloc<PlaylistsEvent, PlaylistsState> {
  PlaylistsBloc(this._playlistService) : super(const PlaylistsInitialState()) {
    on<LoadPlaylistsEvent>(_onLoadPlaylists);
    on<LoadMorePlaylistsEvent>(_onLoadMorePlaylists);
    on<RefreshPlaylistsEvent>(_onRefreshPlaylists);
  }

  final Dp1PlaylistService _playlistService;
  static const int _pageSize = 20;

  Future<void> _onLoadPlaylists(
    LoadPlaylistsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    try {
      emit(
        PlaylistsLoadingState(
          playlists: state.playlists,
          hasMore: state.hasMore,
          currentPage: state.currentPage,
        ),
      );

      final playlists = await _playlistService.getAllPlaylistsFromAllChannel(
        page: 0,
        limit: _pageSize,
      );

      emit(
        PlaylistsLoadedState(
          playlists: playlists,
          hasMore: playlists.length == _pageSize,
          currentPage: 0,
        ),
      );
    } catch (error) {
      emit(
        PlaylistsErrorState(
          error: error.toString(),
          playlists: state.playlists,
          hasMore: state.hasMore,
          currentPage: state.currentPage,
        ),
      );
    }
  }

  Future<void> _onLoadMorePlaylists(
    LoadMorePlaylistsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    // Don't load more if already loading, no more data, or in error state
    if (state is PlaylistsLoadingState ||
        state is PlaylistsLoadingMoreState ||
        !state.hasMore) {
      return;
    }

    try {
      emit(
        PlaylistsLoadingMoreState(
          playlists: state.playlists,
          hasMore: state.hasMore,
          currentPage: state.currentPage,
        ),
      );

      final nextPage = state.currentPage + 1;
      final newPlaylists = await _playlistService.getAllPlaylistsFromAllChannel(
        page: nextPage,
        limit: _pageSize,
      );

      final allPlaylists = [...state.playlists, ...newPlaylists];

      emit(
        PlaylistsLoadedState(
          playlists: allPlaylists,
          hasMore: newPlaylists.length == _pageSize,
          currentPage: nextPage,
        ),
      );
    } catch (error) {
      emit(
        PlaylistsErrorState(
          error: error.toString(),
          playlists: state.playlists,
          hasMore: state.hasMore,
          currentPage: state.currentPage,
        ),
      );
    }
  }

  Future<void> _onRefreshPlaylists(
    RefreshPlaylistsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    try {
      // Keep current playlists visible during refresh
      emit(
        PlaylistsLoadingState(
          playlists: state.playlists,
          hasMore: state.hasMore,
          currentPage: state.currentPage,
        ),
      );

      final playlists = await _playlistService.getAllPlaylistsFromAllChannel(
        page: 0,
        limit: _pageSize,
      );

      emit(
        PlaylistsLoadedState(
          playlists: playlists,
          hasMore: playlists.length == _pageSize,
          currentPage: 0,
        ),
      );
    } catch (error) {
      emit(
        PlaylistsErrorState(
          error: error.toString(),
          playlists: state.playlists,
          hasMore: state.hasMore,
          currentPage: state.currentPage,
        ),
      );
    }
  }
}
