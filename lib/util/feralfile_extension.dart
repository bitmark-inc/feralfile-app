import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:easy_localization/easy_localization.dart';

extension FeralfileErrorExt on FeralfileError {
  String get dialogTitle {
    switch (code) {
      case 5011:
        return "already_accepted".tr();
      default:
        return "error".tr();
    }
  }

  String get dialogMessage {
    switch (code) {
      case 5011:
        return "claimed_error_message".tr();
      default:
        return message;
    }
  }
}
