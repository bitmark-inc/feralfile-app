import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/service/dp1_playlist_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'playlists_event.dart';
part 'playlists_state.dart';

class PlaylistsBloc extends Bloc<PlaylistsEvent, PlaylistsState> {
  PlaylistsBloc({
    required Dp1PlaylistService playlistService,
  })  : _playlistService = playlistService,
        super(const PlaylistsState()) {
    on<LoadPlaylistsEvent>(_onLoadPlaylists);
    on<LoadMorePlaylistsEvent>(_onLoadMorePlaylists);
    on<RefreshPlaylistsEvent>(_onRefreshPlaylists);
  }

  static const int _pageSize = 20;

  final Dp1PlaylistService _playlistService;

  Future<void> _onLoadPlaylists(
    LoadPlaylistsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    await _loadPlaylists(
      emit: emit,
      cursor: null,
    );
  }

  Future<void> _onLoadMorePlaylists(
    LoadMorePlaylistsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    // Prevent multiple simultaneous load more requests
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    await _loadPlaylists(
      emit: emit,
      cursor: state.cursor,
      isLoadMore: true,
    );
  }

  Future<void> _onRefreshPlaylists(
    RefreshPlaylistsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    await _loadPlaylists(
      emit: emit,
      cursor: null,
      isRefresh: true,
    );
  }

  Future<void> _loadPlaylists({
    required Emitter<PlaylistsState> emit,
    required String? cursor,
    bool isLoadMore = false,
    bool isRefresh = false,
  }) async {
    try {
      // Emit appropriate loading state
      if (isLoadMore) {
        emit(state.copyWith(status: PlaylistsStatus.loadingMore));
      } else {
        emit(state.copyWith(status: PlaylistsStatus.loading));
      }

      final playlistsResponse = await _playlistService.getPlaylistsFromChannels(
        cursor: cursor,
        limit: _pageSize,
      );

      final List<DP1Call> newPlaylists;
      if (isLoadMore) {
        newPlaylists = [...state.playlists, ...playlistsResponse.items];
      } else {
        newPlaylists = playlistsResponse.items;
      }

      emit(
        state.copyWith(
          status: PlaylistsStatus.loaded,
          playlists: newPlaylists,
          hasMore: playlistsResponse.hasMore,
          cursor: playlistsResponse.cursor,
          error: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PlaylistsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }
}
