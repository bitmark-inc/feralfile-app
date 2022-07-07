//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';

part 'feed_state.dart';

class FeedBloc extends Bloc<FeedBlocEvent, FeedState> {
  FeedService _feedService;

  FeedBloc(this._feedService) : super(FeedState()) {
    on<GetFeedsEvent>((event, emit) async {
      log.info('[FeedBloc][Start] GetFeedsEvent');
      if (state.appFeedData != null && state.appFeedData?.next == null) {
        log.info('[FeedBloc] break; no more feeds');
        return;
      }

      final newAppFeedData =
          await _feedService.fetchFeeds(state.appFeedData?.next);

      FeedEvent? feedEvent =
          state.viewingFeedEvent ?? newAppFeedData.events.firstOrNull;
      AssetToken? token;

      if (feedEvent != null) {
        token = newAppFeedData.findTokenRelatedTo(feedEvent);
      }

      emit(state.copyWith(
        appFeedData:
            state.appFeedData?.insert(newAppFeedData) ?? newAppFeedData,
        viewingFeedEvent: feedEvent,
        viewingToken: token,
        viewingIndex: state.viewingIndex ?? (feedEvent == null ? null : 0),
      ));
    });

    on<RetryMissingTokenInFeedsEvent>((event, emit) async {
      log.info('[FeedBloc][Start] RetryMissingTokenInFeedsEvent');

      final missingTokenIDs = state.appFeedData?.missingTokenIDs;
      if (missingTokenIDs == null || missingTokenIDs.isEmpty) {
        log.info(
            '[FeedBloc][Start] RetryMissingTokenInFeedsEvent: noMissingTokenIDs');
        return;
      }

      final tokens = await _feedService.fetchTokensByIndexerID(missingTokenIDs);
      log.info(
          '[FeedBloc][Start] RetryMissingTokenInFeedsEvent: has ${tokens.length} tokens ${tokens.map((e) => e.id)}');
      final insertedAppFeedData = state.appFeedData!.insertTokens(tokens);

      // Reload viewingToken if empty
      var viewingToken = state.viewingToken;
      if (viewingToken == null) {
        viewingToken = insertedAppFeedData.tokens.firstWhereOrNull(
            (element) => element.id == state.viewingFeedEvent?.indexerID);
      }

      emit(state.copyWith(
        appFeedData: insertedAppFeedData,
        viewingToken: viewingToken,
      ));
    });

    on<MoveToNextFeedEvent>((event, emit) async {
      final appFeedData = state.appFeedData;
      if (appFeedData == null) return;
      final newIndex = (state.viewingIndex ?? -1) + 1;

      if (newIndex >= appFeedData.events.length) return;

      log.info('[FeedBloc][Start] MoveToNextFeedEvent $newIndex');

      final feedEvent = appFeedData.events[newIndex];
      AssetToken? token = appFeedData.findTokenRelatedTo(feedEvent);

      final newState = state.copyWith(
          viewingFeedEvent: feedEvent,
          viewingToken: token,
          viewingIndex: newIndex);
      newState.viewingToken = token;

      emit(newState);

      if (newIndex >= appFeedData.events.length - 3) {
        add(GetFeedsEvent());
      }
    });

    on<MoveToPreviousFeedEvent>((event, emit) async {
      final appFeedData = state.appFeedData;
      if (appFeedData == null || state.viewingIndex == null) return;
      final newIndex = state.viewingIndex! - 1;

      if (newIndex < 0) return;

      log.info('[FeedBloc][Start] MoveToPreviousFeedEvent $newIndex');

      final feedEvent = appFeedData.events[newIndex];
      AssetToken? token = appFeedData.findTokenRelatedTo(feedEvent);

      final newState = state.copyWith(
          viewingFeedEvent: feedEvent,
          viewingToken: token,
          viewingIndex: newIndex);
      newState.viewingToken = token;

      emit(newState);
    });
  }
}
