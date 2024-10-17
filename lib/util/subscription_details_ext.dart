import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';

extension ListSubscriptionDetails on List<SubscriptionDetails> {
  List<SubscriptionDetails> get activeSubscriptionDetails {
    final activeSubscriptionDetails = <SubscriptionDetails>[];
    for (final subscriptionDetail in this) {
      if (subscriptionDetail.status == IAPProductStatus.completed) {
        activeSubscriptionDetails.add(subscriptionDetail);
      }
    }
    return activeSubscriptionDetails;
  }
}
