import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart';
import 'package:libauk_dart/libauk_dart.dart';

extension WalletAddressExt on WalletAddress {
  bool isMatchAddressInfo(AddressInfo? addressInfo) {
    if (addressInfo == null) {
      return false;
    }
    return addressInfo.uuid == uuid &&
        addressInfo.index == index &&
        addressInfo.chain == cryptoType.toLowerCase();
  }

  WalletStorage get wallet => WalletStorage(uuid);
}
