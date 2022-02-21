import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const String _subscriptionId = 'Au_IntroSub';

class UpgradesBloc extends Bloc<UpgradeEvent, UpgradeState> {
  IAPService _iapService;

  UpgradesBloc(this._iapService)
      : super(UpgradeState(IAPProductStatus.loading, null)) {
    _iapService.purchases.addListener(() => add(UpgradeInfoEvent()));
    _iapService.products.addListener(() => add(UpgradeInfoEvent()));

    on<UpgradeInfoEvent>((event, emit) async {
      try {
        _iapService.setup();
        final productId = _iapService.products.value.keys.first;
        final subscriptionProductDetails =
            _iapService.products.value[productId];
        final subscriptionState = _iapService.purchases.value[productId];

        emit(UpgradeState(subscriptionState ?? IAPProductStatus.notPurchased,
            subscriptionProductDetails));
      } catch (error) {
        log.warning("error when loading IAP", error);
        emit(UpgradeState(IAPProductStatus.error, null));
      }
    });

    on<UpgradeUpdateEvent>((event, emit) async {
      emit(event.newState);
    });

    on<UpgradePurchaseEvent>((event, emit) async {
      try {
        final productId = _iapService.products.value.keys.first;
        final subscriptionProductDetails =
            _iapService.products.value[productId];
        if (subscriptionProductDetails != null) {
          await _iapService.purchase(subscriptionProductDetails);
          emit(UpgradeState(
              IAPProductStatus.pending, subscriptionProductDetails));
        } else {
          log.warning("No item to purchase");
        }
      } catch (error) {
        log.warning(error);
        emit(UpgradeState(IAPProductStatus.error, null));
      }
    });
  }
}
