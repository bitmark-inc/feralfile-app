import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/services/channels_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'channels_event.dart';
part 'channels_state.dart';

class ChannelsBloc extends AuBloc<ChannelsEvent, ChannelsState> {
  ChannelsBloc(this._channelsService) : super(const ChannelsInitialState()) {
    on<LoadChannelsEvent>(_onLoadChannels);
    on<LoadMoreChannelsEvent>(_onLoadMoreChannels);
    on<RefreshChannelsEvent>(_onRefreshChannels);
  }
  final ChannelsService _channelsService;
  static const int _pageSize = 10;

  Future<void> _onLoadChannels(
    LoadChannelsEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    try {
      emit(
        ChannelsLoadingState(
          channels: state.channels,
          hasMore: state.hasMore,
          cursor: state.cursor,
        ),
      );

      final channelsResponse = await _channelsService.getChannels(
        cursor: state.cursor,
        limit: _pageSize,
      );

      emit(
        ChannelsLoadedState(
          channels: channelsResponse.items,
          hasMore: channelsResponse.hasMore,
          cursor: channelsResponse.cursor,
        ),
      );
    } catch (error) {
      emit(ChannelsErrorState(
        error: error.toString(),
        channels: state.channels,
        hasMore: state.hasMore,
        cursor: state.cursor,
      ));
    }
  }

  Future<void> _onLoadMoreChannels(
    LoadMoreChannelsEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    // Don't load more if already loading, no more data, or in error state
    if (state is ChannelsLoadingState ||
        state is ChannelsLoadingMoreState ||
        !state.hasMore) {
      return;
    }

    try {
      emit(ChannelsLoadingMoreState(
        channels: state.channels,
        hasMore: state.hasMore,
        cursor: state.cursor,
      ));

      final newChannelsResponse = await _channelsService.getChannels(
        cursor: state.cursor,
        limit: _pageSize,
      );

      final allChannels = [...state.channels, ...newChannelsResponse.items];

      emit(
        ChannelsLoadedState(
          channels: allChannels,
          hasMore: newChannelsResponse.hasMore,
          cursor: newChannelsResponse.cursor,
        ),
      );
    } catch (error) {
      emit(ChannelsErrorState(
        error: error.toString(),
        channels: state.channels,
        hasMore: state.hasMore,
        cursor: state.cursor,
      ));
    }
  }

  Future<void> _onRefreshChannels(
    RefreshChannelsEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    try {
      // Keep current channels visible during refresh
      emit(
        ChannelsLoadingState(
          channels: state.channels,
          hasMore: state.hasMore,
          cursor: state.cursor,
        ),
      );

      final channelsResponse = await _channelsService.getChannels(
        cursor: state.cursor,
        limit: _pageSize,
      );

      emit(
        ChannelsLoadedState(
          channels: channelsResponse.items,
          hasMore: channelsResponse.hasMore,
          cursor: channelsResponse.cursor,
        ),
      );
    } catch (error) {
      emit(
        ChannelsErrorState(
          error: error.toString(),
          channels: state.channels,
          hasMore: state.hasMore,
          cursor: state.cursor,
        ),
      );
    }
  }
}
