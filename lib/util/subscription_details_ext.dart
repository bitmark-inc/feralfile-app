import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';

extension ListSubscriptionDetails on List<SubscriptionDetails> {
  List<SubscriptionDetails> get activeSubscriptionDetails {
    final activeSubscriptionDetails = <SubscriptionDetails>[];
    for (final subscriptionDetail in this) {
      final shouldIgnoreOnUI =
          inactiveIds().contains(subscriptionDetail.productDetails.id) &&
              !(subscriptionDetail.status == IAPProductStatus.completed ||
                  subscriptionDetail.status == IAPProductStatus.trial &&
                      subscriptionDetail.trialExpiredDate != null &&
                      subscriptionDetail.trialExpiredDate!
                          .isBefore(DateTime.now()));
      if (!shouldIgnoreOnUI) {
        activeSubscriptionDetails.add(subscriptionDetail);
      }
    }
    return activeSubscriptionDetails;
  }
}
