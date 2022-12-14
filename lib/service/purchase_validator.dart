// ignore_for_file: depend_on_referenced_packages

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:iso_duration_parser/iso_duration_parser.dart';

abstract class PurchaseValidator {
  Future<bool> isValid();

  // Get free trial period date. Returns null if currently not in trial period
  Future<DateTime?> getTrialExpireDate();

  DateTime getPurchaseDate(PurchaseDetails purchase) {
    return DateTime.fromMillisecondsSinceEpoch(
        int.parse(purchase.transactionDate ?? "0"));
  }
}

class PurchaseValidatorFactory {
  static PurchaseValidator createPurchaseValidator(
      {required ProductDetails product, required PurchaseDetails purchase}) {
    if (purchase is GooglePlayPurchaseDetails &&
        product is GooglePlayProductDetails) {
      return _PurchaseVerifierAndroidImpl(product, purchase);
    } else if (purchase is AppStorePurchaseDetails &&
        product is AppStoreProductDetails) {
      return _PurchaseVerifierIOSImpl(purchase);
    } else {
      throw UnimplementedError();
    }
  }
}

class _PurchaseVerifierAndroidImpl extends PurchaseValidator {
  final GooglePlayProductDetails _product;
  final GooglePlayPurchaseDetails _purchase;

  _PurchaseVerifierAndroidImpl(this._product, this._purchase);

  @override
  Future<bool> isValid() async {
    return (_purchase.status == PurchaseStatus.purchased ||
        _purchase.status == PurchaseStatus.restored);
  }

  @override
  Future<DateTime?> getTrialExpireDate() async {
    if (!await isValid()) {
      return null;
    }
    try {
      final trialPeriod = _product.skuDetails.freeTrialPeriod;
      final trialDuration =
          Duration(seconds: IsoDuration.parse(trialPeriod).toSeconds().toInt());
      final purchaseDate = getPurchaseDate(_purchase);
      final trialExpireDate = purchaseDate.add(trialDuration);
      if (trialExpireDate.isAfter(DateTime.now())) {
        return trialExpireDate;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

class _PurchaseVerifierIOSImpl extends PurchaseValidator {
  final AppStorePurchaseDetails _purchase;

  _PurchaseVerifierIOSImpl(this._purchase);

  @override
  Future<bool> isValid() async {
    return (_purchase.status == PurchaseStatus.purchased ||
        _purchase.status == PurchaseStatus.restored);
  }

  @override
  Future<DateTime?> getTrialExpireDate() async {
    if (!await isValid()) {
      return null;
    }
    final purchaseDate = getPurchaseDate(_purchase);
    final trialExpireDate = purchaseDate.add(const Duration(days: 30));
    if (trialExpireDate.isAfter(DateTime.now())) {
      return trialExpireDate;
    } else {
      return null;
    }
  }
}
