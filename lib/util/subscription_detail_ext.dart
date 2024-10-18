import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/product_details_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:system_date_time_format/system_date_time_format.dart';

extension SubscriptionDetailExt on SubscriptionDetails {
  String get price => '${productDetails.price}/${productDetails.period.name}';

  String? get renewDate {
    final expiredDate = purchaseDetails?.transactionDate;
    final context = injector<NavigationService>().context;
    final pattern = SystemDateTimeFormat.of(context);

    final renewDate = expiredDate != null
        ? DateFormat(pattern.mediumDatePattern).format(
            DateTime.fromMillisecondsSinceEpoch(int.parse(expiredDate))
                .add(const Duration(days: 365)))
        : null;
    return renewDate;
  }

  String? get cancelAtFormatted {
    final cancelAt = injector<IAPService>().cancelAt[productDetails.id];
    if (cancelAt == null) {
      return null;
    }
    final context = injector<NavigationService>().context;
    final pattern = SystemDateTimeFormat.of(context);

    final cancelAtFormatted =
        DateFormat(pattern.mediumDatePattern).format(cancelAt);
    return cancelAtFormatted;
  }
}
