// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:http/http.dart' as http;
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
      return _PurchaseVerifierIOSImpl(product, purchase);
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
  static const _prdVerifyEndPoint =
      "https://buy.itunes.apple.com/verifyReceipt";
  static const _sandboxVerifyEndPoint =
      "https://sandbox.itunes.apple.com/verifyReceipt";

  final AppStoreProductDetails _product;
  final AppStorePurchaseDetails _purchase;
  Map<String, dynamic>? _receiptInfo;

  _PurchaseVerifierIOSImpl(this._product, this._purchase);

  Future<http.Response> _makeRequest(
      String endpoint, String receiptData) async {
    return await http.post(
      Uri.parse(endpoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "receipt-data": receiptData,
        "exclude-old-transactions": "true",
        "password": Environment.appStoreSharedSecret,
      }),
    );
  }

  DateTime? _getExpireDate() {
    final expireDateMs = _receiptInfo?["expires_date_ms"] as String?;
    if (expireDateMs != null) {
      final ts = int.tryParse(expireDateMs) ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      return null;
    }
  }

  @override
  Future<bool> isValid() async {
    if (_receiptInfo == null) {
      try {
        final receiptData = _purchase.verificationData.serverVerificationData;
        var resp = await _makeRequest(_prdVerifyEndPoint, receiptData);
        if (jsonDecode(resp.body)["status"] == 21007) {
          resp = await _makeRequest(_sandboxVerifyEndPoint, receiptData);
        }
        if (jsonDecode(resp.body)["status"] == 0) {
          _receiptInfo = jsonDecode(resp.body)["latest_receipt_info"][0];
        } else {
          log.info("[PurchaseVerify] Verify failed ${resp.statusCode}");
          return false;
        }
      } catch (e) {
        log.info("[PurchaseVerify] Error $e");
        return false;
      }
    }
    return _getExpireDate()?.isAfter(DateTime.now()) == true;
  }

  @override
  Future<DateTime?> getTrialExpireDate() async {
    if (!await isValid()) {
      return null;
    }
    if (_receiptInfo?["is_trial_period"] == "true") {
      return _getExpireDate();
    } else {
      return null;
    }
  }
}
