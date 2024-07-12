import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/util/primary_address_channel.dart';

extension WalletAddressExt on WalletAddress {
  bool isMatchAddressInfo(AddressInfo? addressInfo) {
    if (addressInfo == null) {
      return false;
    }
    return addressInfo.uuid == uuid &&
        addressInfo.index == index &&
        addressInfo.chain == cryptoType.toLowerCase();
  }
}
