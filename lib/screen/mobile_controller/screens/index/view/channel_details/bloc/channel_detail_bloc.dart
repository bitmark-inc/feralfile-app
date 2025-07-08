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
  }

  final Dp1PlaylistService _dp1playlistService;

  Future<void> _onLoadChannelPlaylists(
    LoadChannelPlaylistsEvent event,
    Emitter<ChannelDetailState> emit,
  ) async {
    emit(const ChannelDetailLoadingState());
    final playlists =
        await _dp1playlistService.getPlaylistsByChannel(event.channel);
    emit(ChannelDetailLoadedState(playlists: playlists));
  }
}
