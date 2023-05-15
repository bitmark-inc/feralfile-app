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
  Object? error;

  FeedState({
    this.appFeedData,
    this.feedTokenEventsMap,
    this.error,
  });

  FeedState copyWith({
    AppFeedData? appFeedData,
    Map<AssetToken, List<FeedEvent>>? feedTokenEventsMap,
    Object? error,
  }) {
    return FeedState(
      appFeedData: appFeedData ?? this.appFeedData,
      feedTokenEventsMap: feedTokenEventsMap ?? this.feedTokenEventsMap,
      error: error ?? this.error,
    );
  }
}
