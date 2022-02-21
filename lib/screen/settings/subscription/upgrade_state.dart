import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class UpgradeEvent {}

class UpgradeInfoEvent extends UpgradeEvent {}

class UpgradePurchaseEvent extends UpgradeEvent {}

class UpgradeUpdateEvent extends UpgradeEvent {
  final UpgradeState newState;

  UpgradeUpdateEvent(this.newState);
}

class UpgradeState {
  final IAPProductStatus status;
  final ProductDetails? productDetails;

  UpgradeState(this.status, this.productDetails);
}
