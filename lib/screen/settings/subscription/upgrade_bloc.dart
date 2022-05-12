import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class UpgradesBloc extends Bloc<UpgradeEvent, UpgradeState> {
  IAPService _iapService;
  ConfigurationService _configurationService;

  UpgradesBloc(this._iapService, this._configurationService)
      : super(UpgradeState(IAPProductStatus.loading, null)) {
    // Query IAP info initially
    on<UpgradeQueryInfoEvent>((event, emit) async {
      final jwt = _configurationService.getIAPJWT();
      if (jwt != null) {
        if (jwt.isValid()) {
          emit(UpgradeState(IAPProductStatus.completed, null));
        } else {
          final result = await _iapService.renewJWT();
          emit(UpgradeState(
              result
                  ? IAPProductStatus.completed
                  : IAPProductStatus.notPurchased,
              null));
        }
      } else {
        if (_iapService.products.value.isEmpty) {
          emit(UpgradeState(IAPProductStatus.loading, null));
        } else {
          _onNewIAPEventFunc();
        }
      }
    });

// Return IAP info after getting from Apple / Google
    on<UpgradeIAPInfoEvent>((event, emit) async {
      ProductDetails? productDetail;
      IAPProductStatus state = IAPProductStatus.loading;

      if (_iapService.products.value.isNotEmpty) {
        final productId = _iapService.products.value.keys.first;
        productDetail = _iapService.products.value[productId];

        final subscriptionState = _iapService.purchases.value[productId];
        state = subscriptionState ?? IAPProductStatus.notPurchased;
      }

      emit(UpgradeState(state, productDetail));
    });

// Update new state if needed
    on<UpgradeUpdateEvent>((event, emit) async {
      emit(event.newState);
    });

// Purchase event
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

    _iapService.purchases.addListener(_onNewIAPEventFunc);
    _iapService.products.addListener(_onNewIAPEventFunc);
  }

  void _onNewIAPEventFunc() {
    add(UpgradeIAPInfoEvent());
  }

  @override
  Future<void> close() {
    _iapService.purchases.removeListener(_onNewIAPEventFunc);
    _iapService.products.removeListener(_onNewIAPEventFunc);
    return super.close();
  }
}
