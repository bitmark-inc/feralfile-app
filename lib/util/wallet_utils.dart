import 'package:easy_localization/easy_localization.dart';

// ignore_for_file: constant_identifier_names

enum WalletType {
  Autonomy,
  Ethereum,
  Tezos;

  static WalletType? getWallet({required bool eth, required bool tezos}) {
    if (eth && tezos) {
      return WalletType.Autonomy;
    } else if (eth) {
      return WalletType.Ethereum;
    } else if (tezos) {
      return WalletType.Tezos;
    } else {
      return null;
    }
  }
}

extension WalletTypeExtension on WalletType {
  String getString() {
    switch (this) {
      case WalletType.Ethereum:
        return 'Ethereum';
      case WalletType.Tezos:
        return 'Tezos';
      default:
        return 'au_multi_chains'.tr();
    }
  }
}
