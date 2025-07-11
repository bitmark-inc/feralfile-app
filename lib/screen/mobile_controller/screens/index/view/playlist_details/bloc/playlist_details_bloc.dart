import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_tokens.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/services/indexer_service.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlist_details/bloc/playlist_details_event.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlist_details/bloc/playlist_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry/sentry.dart';

class PlaylistDetailsBloc
    extends AuBloc<PlaylistDetailsEvent, PlaylistDetailsState> {
  final IndexerService _indexerService;
  final DP1Call playlist;
  static const int _pageSize = 10;

  PlaylistDetailsBloc(this._indexerService, this.playlist)
      : super(const PlaylistDetailsInitialState()) {
    on<GetPlaylistDetailsEvent>(_onGetPlaylistDetails);
    on<LoadMorePlaylistDetailsEvent>(_onLoadMorePlaylistDetails);
  }

  Future<void> _onGetPlaylistDetails(
    GetPlaylistDetailsEvent event,
    Emitter<PlaylistDetailsState> emit,
  ) async {
    emit(
      PlaylistDetailsLoadingState(
        assetTokens: state.assetTokens,
        hasMore: state.hasMore,
        currentPage: state.currentPage,
      ),
    );
    try {
      final items = playlist.items;
      final indexIds =
          items.map((item) => item.indexId).whereType<String>().toList();
      final pageIndexIds = indexIds.take(_pageSize).toList();
      final asseTtokens = (await _indexerService.getNftTokens(
        QueryListTokensRequest(ids: pageIndexIds),
      ));
      final tokens = List<AssetToken>.from(asseTtokens).toList();
      if (tokens.length != pageIndexIds.length) {
        final missingTokens =
            pageIndexIds.where((id) => !tokens.any((t) => t.id == id)).toList();
        unawaited(Sentry.captureException(Exception(
            'Can not get all tokens. Missing tokens:  ${missingTokens.join(', ')}')));
      }

      emit(
        PlaylistDetailsLoadedState(
          assetTokens: tokens,
          hasMore: indexIds.length > _pageSize,
          currentPage: 0,
        ),
      );
    } catch (e) {
      emit(
        PlaylistDetailsErrorState(
          error: e.toString(),
          assetTokens: state.assetTokens,
          hasMore: state.hasMore,
          currentPage: state.currentPage,
        ),
      );
    }
  }

  Future<void> _onLoadMorePlaylistDetails(
    LoadMorePlaylistDetailsEvent event,
    Emitter<PlaylistDetailsState> emit,
  ) async {
    if (!state.hasMore) return;
    emit(
      PlaylistDetailsLoadingMoreState(
        assetTokens: state.assetTokens,
        hasMore: state.hasMore,
        currentPage: state.currentPage,
      ),
    );
    try {
      final items = playlist.items;
      final indexIds =
          items.map((item) => item.indexId).whereType<String>().toList();
      final nextPage = state.currentPage + 1;
      final start = nextPage * _pageSize;
      final end = start + _pageSize;
      if (start >= indexIds.length) {
        emit(state.copyWith(hasMore: false));
        return;
      }
      final pageIndexIds = indexIds.sublist(
        start,
        end > indexIds.length ? indexIds.length : end,
      );
      final tokens = await _indexerService.getNftTokens(
        QueryListTokensRequest(ids: pageIndexIds),
      );
      emit(
        PlaylistDetailsLoadedState(
          assetTokens: [...state.assetTokens, ...tokens],
          hasMore: end < indexIds.length,
          currentPage: nextPage,
        ),
      );
    } catch (e) {
      emit(
        PlaylistDetailsErrorState(
          error: e.toString(),
          assetTokens: state.assetTokens,
          hasMore: state.hasMore,
          currentPage: state.currentPage,
        ),
      );
    }
  }
}
