//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:nft_collection/models/asset_token.dart';

part 'feed_state.dart';

class FeedBloc extends AuBloc<FeedBlocEvent, FeedState> {
  final FeedService _feedService;
  final ConfigurationService _configurationService;

  FeedBloc(this._feedService, this._configurationService)
      : super(FeedState(
            onBoardingStep:
                _configurationService.isFinishedFeedOnBoarding() ? -1 : 0)) {
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
        onBoardingStep: state.onBoardingStep,
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
      viewingToken ??= insertedAppFeedData.tokens.firstWhereOrNull(
            (element) => element.id == state.viewingFeedEvent?.indexerID);

      emit(state.copyWith(
          appFeedData: insertedAppFeedData,
          viewingToken: viewingToken,
          onBoardingStep: state.onBoardingStep));
    });

    on<MoveToNextFeedEvent>((event, emit) async {
      if (state.onBoardingStep >= 0 && state.onBoardingStep <= 2) {
        if (state.onBoardingStep == 2) {
          _configurationService.setFinishedFeedOnBoarding(true);
        }

        emit(state.copyWith(
          viewingFeedEvent: state.viewingFeedEvent,
          viewingToken: state.viewingToken,
          viewingIndex: state.viewingIndex,
          onBoardingStep:
              state.onBoardingStep < 2 ? state.onBoardingStep + 1 : -1,
        ));
        return;
      }

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
      if (state.onBoardingStep >= 0 && state.onBoardingStep <= 2) {
        emit(state.copyWith(
          viewingFeedEvent: state.viewingFeedEvent,
          viewingToken: state.viewingToken,
          viewingIndex: state.viewingIndex,
          onBoardingStep:
              state.onBoardingStep > 0 ? state.onBoardingStep - 1 : 0,
        ));
        return;
      }

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
