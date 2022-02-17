import 'dart:io';

import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

const String _subscriptionId = 'Au_IntroSub';

class UpgradesBloc extends Bloc<UpgradeEvent, UpgradeState> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  ConfigurationService _configurationService;

  static List<String> _kProductIds = <String>[
    _subscriptionId,
  ];

  UpgradesBloc(this._configurationService)
      : super(UpgradeState(false, false, null)) {
    on<UpgradeInfoEvent>((event, emit) async {
      final isPaid = await _checkIsPaid();

      emit(UpgradeState(isPaid, false, null));
    });

    on<UpgradeUpdateEvent>((event, emit) async {
      emit(event.newState);
    });
  }

  Future<bool> _checkIsPaid() async {
    return false;
  }

  Future<void> setupIAP() async {
    if (Platform.isIOS) {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
    }

    ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      return;
    }
  }
}

class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
