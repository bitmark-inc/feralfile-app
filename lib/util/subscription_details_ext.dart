import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:collection/collection.dart';

extension ListSubscriptionDetails on List<SubscriptionDetails> {
  List<SubscriptionDetails> get activeSubscriptionDetails {
    final activeSubscriptionDetails = <SubscriptionDetails>[];
    for (final subscriptionDetail in this) {
      activeSubscriptionDetails.add(subscriptionDetail);
    }
    return activeSubscriptionDetails;
  }

  SubscriptionDetails? get subscribedSubscriptionDetail {
    final listSubscriptionDetails = activeSubscriptionDetails;
    return listSubscriptionDetails.firstWhereOrNull(
        (element) => element.status == IAPProductStatus.completed);
  }
}
