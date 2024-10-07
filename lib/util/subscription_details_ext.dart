import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';

extension ListSubscriptionDetails on List<SubscriptionDetails> {
  List<SubscriptionDetails> get activeSubscriptionDetails {
    final activeSubscriptionDetails = <SubscriptionDetails>[];
    for (final subscriptionDetail in this) {
      activeSubscriptionDetails.add(subscriptionDetail);
    }
    return activeSubscriptionDetails;
  }
}
