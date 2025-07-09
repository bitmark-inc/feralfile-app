import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/service/dp1_playlist_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'channel_detail_event.dart';
part 'channel_detail_state.dart';

class ChannelDetailBloc extends Bloc<ChannelDetailEvent, ChannelDetailState> {
  ChannelDetailBloc(this._dp1playlistService)
      : super(const ChannelDetailInitialState()) {
    on<LoadChannelPlaylistsEvent>(_onLoadChannelPlaylists);
    on<LoadMoreChannelPlaylistsEvent>(_onLoadMoreChannelPlaylists);
    on<RefreshChannelPlaylistsEvent>(_onRefreshChannelPlaylists);
  }

  static const int _pageSize = 10;

  final Dp1PlaylistService _dp1playlistService;

  Future<void> _onLoadChannelPlaylists(
    LoadChannelPlaylistsEvent event,
    Emitter<ChannelDetailState> emit,
  ) async {
    try {
      emit(
        ChannelDetailLoadingState(
          playlists: state.playlists,
          hasMore: state.hasMore,
          cursor: state.cursor,
        ),
      );

      final playlistsResponse = await _dp1playlistService.getPlaylists(
        channelId: event.channel.id,
        limit: _pageSize,
        cursor: state.cursor,
      );

      emit(
        ChannelDetailLoadedState(
          playlists: playlistsResponse.items,
          hasMore: playlistsResponse.hasMore,
          cursor: playlistsResponse.cursor,
        ),
      );
    } catch (e) {
      emit(ChannelDetailErrorState(
        error: e.toString(),
        playlists: state.playlists,
        hasMore: state.hasMore,
        cursor: state.cursor,
      ));
    }
  }

  Future<void> _onLoadMoreChannelPlaylists(
    LoadMoreChannelPlaylistsEvent event,
    Emitter<ChannelDetailState> emit,
  ) async {
    if (state is ChannelDetailLoadingState ||
        state is ChannelDetailLoadingMoreState ||
        !state.hasMore) {
      return;
    }
    try {
      emit(
        ChannelDetailLoadingMoreState(
          playlists: state.playlists,
          hasMore: state.hasMore,
          cursor: state.cursor,
        ),
      );

      final newPlaylistsResponse = await _dp1playlistService.getPlaylists(
        channelId: event.channel.id,
        limit: _pageSize,
        cursor: state.cursor,
      );

      final allPlaylists = [...state.playlists, ...newPlaylistsResponse.items];

      emit(
        ChannelDetailLoadedState(
          playlists: allPlaylists,
          hasMore: newPlaylistsResponse.hasMore,
          cursor: newPlaylistsResponse.cursor,
        ),
      );
    } catch (e) {
      emit(ChannelDetailErrorState(
        error: e.toString(),
        playlists: state.playlists,
        hasMore: state.hasMore,
        cursor: state.cursor,
      ));
    }
  }

  Future<void> _onRefreshChannelPlaylists(
    RefreshChannelPlaylistsEvent event,
    Emitter<ChannelDetailState> emit,
  ) async {
    try {
      emit(
        ChannelDetailLoadingState(
          playlists: state.playlists,
          hasMore: state.hasMore,
          cursor: state.cursor,
        ),
      );
      final playlistsResponse = await _dp1playlistService.getPlaylists(
        channelId: event.channel.id,
        limit: _pageSize,
        cursor: state.cursor,
      );

      emit(
        ChannelDetailLoadedState(
          playlists: playlistsResponse.items,
          hasMore: playlistsResponse.hasMore,
          cursor: playlistsResponse.cursor,
        ),
      );
    } catch (e) {
      emit(ChannelDetailErrorState(
        error: e.toString(),
        playlists: state.playlists,
        hasMore: state.hasMore,
        cursor: state.cursor,
      ));
    }
  }
}
