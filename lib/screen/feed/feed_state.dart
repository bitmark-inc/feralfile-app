//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'feed_bloc.dart';

abstract class FeedBlocEvent {}

class GetFeedsEvent extends FeedBlocEvent {}

class ChangePageEvent extends FeedBlocEvent {
  final int index;
  ChangePageEvent({required this.index});
}

class ChangeOnBoardingEvent extends FeedBlocEvent {
  final int index;
  ChangeOnBoardingEvent({required this.index});
}

class RetryMissingTokenInFeedsEvent extends FeedBlocEvent {}

class MoveToNextFeedEvent extends FeedBlocEvent {}

class MoveToPreviousFeedEvent extends FeedBlocEvent {}

class FeedState {
  AppFeedData? appFeedData;
  List<AssetToken?>? feedTokens;
  List<FeedEvent>? feedEvents;
  int? viewingIndex;
  int onBoardingStep = -1;

  FeedState({
    this.appFeedData,
    this.viewingIndex,
    this.onBoardingStep = -1,
    this.feedTokens,
    this.feedEvents,
  });

  FeedState copyWith({
    AppFeedData? appFeedData,
    int? viewingIndex,
    int onBoardingStep = -1,
    List<AssetToken?>? feedTokens,
    List<FeedEvent>? feedEvents,
  }) {
    return FeedState(
      appFeedData: appFeedData ?? this.appFeedData,
      viewingIndex: viewingIndex ?? this.viewingIndex,
      onBoardingStep: onBoardingStep,
      feedTokens: feedTokens ?? this.feedTokens,
      feedEvents: feedEvents ?? this.feedEvents,
    );
  }

  bool isFinishedOnBoarding() => onBoardingStep == -1;
}
