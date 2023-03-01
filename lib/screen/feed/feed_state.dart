//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'feed_bloc.dart';

abstract class FeedBlocEvent {}

class GetFeedsEvent extends FeedBlocEvent {}

class OpenFeedEvent extends FeedBlocEvent {}

class RetryMissingTokenInFeedsEvent extends FeedBlocEvent {}

class MoveToNextFeedEvent extends FeedBlocEvent {}

class MoveToPreviousFeedEvent extends FeedBlocEvent {}

class FeedState {
  AppFeedData? appFeedData;
  Map<AssetToken, List<FeedEvent>>? feedTokenEventsMap;
  int onBoardingStep = -1;

  FeedState({
    this.appFeedData,
    this.onBoardingStep = -1,
    this.feedTokenEventsMap,
  });

  FeedState copyWith({
    AppFeedData? appFeedData,
    int? viewingIndex,
    int onBoardingStep = -1,
    Map<AssetToken, List<FeedEvent>>? feedTokenEventsMap,
  }) {
    return FeedState(
      appFeedData: appFeedData ?? this.appFeedData,
      onBoardingStep: onBoardingStep,
      feedTokenEventsMap: feedTokenEventsMap ?? this.feedTokenEventsMap,
    );
  }

  bool isFinishedOnBoarding() => onBoardingStep == -1;
}
