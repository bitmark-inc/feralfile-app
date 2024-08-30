import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/util/product_details_ext.dart';
import 'package:easy_localization/easy_localization.dart';

extension SubscriptionDetailExt on SubscriptionDetails {
  String get price => '${productDetails.price}/${productDetails.period.name}';

  String? get renewDate {
    final expiredDate = purchaseDetails?.transactionDate;
    final renewDate = expiredDate != null
        ? DateFormat('dd-MM-yyyy').format(
            DateTime.fromMillisecondsSinceEpoch(int.parse(expiredDate))
                .add(const Duration(days: 365)))
        : null;
    return renewDate;
  }
}
