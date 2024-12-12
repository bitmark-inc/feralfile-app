import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';

class WalletAddressCloudObject {
  final AccountSettingsDB _accountSettingsDB;

  WalletAddressCloudObject(this._accountSettingsDB);

  AccountSettingsDB get db => _accountSettingsDB;

  Future<void> deleteAddress(WalletAddress address) async {
    // address is also the key
    await _accountSettingsDB.delete([address.key]);
  }

  WalletAddress? findByAddress(String address) {
    // address is also the key
    final value = _accountSettingsDB.query([address]);
    if (value.isEmpty) {
      return null;
    }
    final addressJson =
        jsonDecode(value.first['value']!) as Map<String, dynamic>;
    return WalletAddress.fromJson(addressJson);
  }

  List<WalletAddress> getAllAddresses() {
    final addresses = _accountSettingsDB.values
        .map((value) =>
            WalletAddress.fromJson(jsonDecode(value) as Map<String, dynamic>))
        .toList();
    return addresses;
  }

  Future<void> insertAddresses(List<WalletAddress> addresses,
      {OnConflict onConflict = OnConflict.override}) async {
    await _accountSettingsDB.write(
        addresses.map((address) => address.toKeyValue).toList(),
        onConflict: onConflict);
  }

  Future<void> setAddressIsHidden(String address, bool isHidden) async {
    final walletAddress = findByAddress(address);
    if (walletAddress == null) {
      return;
    }
    await updateAddresses([walletAddress.copyWith(isHidden: isHidden)]);
  }

  Future<void> updateAddresses(List<WalletAddress> addresses) async {
    await _accountSettingsDB.write(addresses.map((e) => e.toKeyValue).toList());
  }

  Future<void> download() async {
    await _accountSettingsDB.download();
  }
}
