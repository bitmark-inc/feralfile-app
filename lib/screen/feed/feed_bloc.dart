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
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/models/asset_token.dart';

part 'feed_state.dart';

class FeedBloc extends AuBloc<FeedBlocEvent, FeedState> {
  final FeedService _feedService;
  final ConfigurationService _configurationService;
  final AssetTokenDao _assetTokenDao;

  FeedBloc(this._feedService, this._configurationService, this._assetTokenDao)
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

        final ownedTokenIds = await _assetTokenDao.findAllAssetTokenIDs();
        final newAppFeedData = await _feedService.fetchFeeds(
          state.appFeedData?.next,
          ignoredTokenIds: ownedTokenIds,
        );

        final appFeedData =
            state.appFeedData?.insert(newAppFeedData) ?? newAppFeedData;

        final Map<AssetToken, List<FeedEvent>> tokenEventMap = {};
        for (FeedEvent event in appFeedData.events) {
          final token = appFeedData.findTokenRelatedTo(event);
          if (token == null) continue;

          if (tokenEventMap[token] != null) {
            tokenEventMap[token]!.add(event);
          } else {
            tokenEventMap[token] = [event];
          }
        }

        emit(
          state.copyWith(
            appFeedData: appFeedData,
            feedTokenEventsMap: tokenEventMap,
          ),
        );
      },
    );

    on<OpenFeedEvent>((event, emit) {
      _configurationService
          .setLastTimeOpenFeed(DateTime.now().millisecondsSinceEpoch);
      _feedService.unviewedCount.value = 0;
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

      emit(
        state.copyWith(
          appFeedData: insertedAppFeedData,
          onBoardingStep: state.onBoardingStep,
        ),
      );
    });
  }
}
