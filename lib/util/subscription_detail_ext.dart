import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/util/product_details_ext.dart';

extension SubscriptionDetailExt on SubscriptionDetails {
  String get price => '${productDetails.price}/${productDetails.period.name}';
}
