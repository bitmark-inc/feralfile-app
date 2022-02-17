import 'package:in_app_purchase/in_app_purchase.dart';

abstract class UpgradeEvent {}

class UpgradeInfoEvent extends UpgradeEvent {}

class UpgradeUpdateEvent extends UpgradeEvent {
  final UpgradeState newState;

  UpgradeUpdateEvent(this.newState);
}

class UpgradeState {
  final bool isPaid;
  final bool purchasePending;
  final ProductDetails? productDetails;

  UpgradeState(this.isPaid, this.purchasePending, this.productDetails);
}
