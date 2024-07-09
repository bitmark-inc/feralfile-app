class SubscriptionEvent {}

class GetSubscriptionEvent extends SubscriptionEvent {}

class SubscriptionState {
  SubscriptionState({
    this.isSubscribed = false,
  });

  final bool isSubscribed;

  SubscriptionState copyWith({
    bool? isSubscribed,
  }) =>
      SubscriptionState(
        isSubscribed: isSubscribed ?? this.isSubscribed,
      );
}
