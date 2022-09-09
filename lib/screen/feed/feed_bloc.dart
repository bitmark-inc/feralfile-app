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
              _configurationService.isFinishedFeedOnBoarding() ? -1 : 0,
        )) {
    on<GetFeedsEvent>(
      (event, emit) async {
        if (state.appFeedData != null && state.appFeedData?.next == null) {
          log.info('[FeedBloc] break; no more feeds');
          return;
        }

        final newAppFeedData =
            await _feedService.fetchFeeds(state.appFeedData?.next);

        final appFeedData =
            state.appFeedData?.insert(newAppFeedData) ?? newAppFeedData;

        final List<AssetToken?> feedTokens = appFeedData.events
            .map((e) => appFeedData.findTokenRelatedTo(e))
            .toList();

        emit(
          state.copyWith(
            appFeedData: appFeedData,
            feedTokens: feedTokens,
            viewingIndex: state.viewingIndex ?? 0,
            feedEvents: appFeedData.events,
          ),
        );
      },
    );

    on<ChangePageEvent>((event, emit) async {
      emit(state.copyWith(viewingIndex: event.index));
      if (event.index + 2 == state.feedEvents?.length) {
        add(GetFeedsEvent());
      }
    });

    on<ChangeOnBoardingEvent>((event, emit) async {
      if (event.index >= 0 && event.index < 2) {
        emit(state.copyWith(onBoardingStep: event.index));
        return;
      }
      if (event.index == 2) {
        _configurationService.setFinishedFeedOnBoarding(true);
        return;
      }
      emit(state.copyWith(onBoardingStep: -1));
      add(GetFeedsEvent());
      return;
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
      final currentIndex = state.viewingIndex ?? 0;
      var viewingToken = state.feedTokens?[currentIndex];
      viewingToken ??= insertedAppFeedData.tokens.firstWhereOrNull(
          (element) => element.id == state.feedEvents?[currentIndex].indexerID);

      emit(
        state.copyWith(
          appFeedData: insertedAppFeedData,
          onBoardingStep: state.onBoardingStep,
        ),
      );
    });
  }
}
