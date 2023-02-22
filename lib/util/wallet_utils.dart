import 'package:easy_localization/easy_localization.dart';

enum WalletType { Autonomy, Ethereum, Tezos }

extension WalletTypeExtension on WalletType {
  String getString() {
    switch (this) {
      case WalletType.Ethereum:
        return "Ethereum";
      case WalletType.Tezos:
        return "Tezos";
      default:
        return "au_multi_chains".tr();
    }
  }
}
