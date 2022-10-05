import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:easy_localization/easy_localization.dart';

extension FeralfileErrorExt on FeralfileError {
  String get dialogTitle {
    switch (code) {
      case 5011:
        return "Already accepted";
      default:
        return "error".tr();
    }
  }

  String get dialogMessage {
    switch (code) {
      case 5011:
        return "You have already claimed your gift edition. The offer is valid only one time.";
      default:
        return message;
    }
  }
}
