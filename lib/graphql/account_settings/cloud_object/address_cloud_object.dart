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

  Future<void> deleteAddressesByUuid(String uuid) async {
    final addressesWithUUid = getAddressesByUuid(uuid);
    await _accountSettingsDB
        .delete(addressesWithUUid.map((e) => e.key).toList());
  }

  List<WalletAddress> findAddressesWithHiddenStatus(bool isHidden) {
    final allAddresses = getAllAddresses();
    return allAddresses
        .where((element) => element.isHidden == isHidden)
        .toList();
  }

  WalletAddress? findByAddress(String address) {
    // address is also the key
    final value = _accountSettingsDB.query([address]);
    if (value.isEmpty) {
      return null;
    }
    final addressJson = jsonDecode(value.first['value']!) as Map<String, dynamic>;
    return WalletAddress.fromJson(addressJson);
  }

  List<WalletAddress> getAddresses(String uuid, String cryptoType) {
    final allAddresses = getAllAddresses();
    return allAddresses
        .where((element) =>
            element.uuid == uuid && element.cryptoType == cryptoType)
        .toList();
  }

  List<WalletAddress> getAddressesByUuid(String uuid) {
    final allAddresses = getAllAddresses();
    return allAddresses.where((element) => element.uuid == uuid).toList();
  }

  List<WalletAddress> getAddressesByType(String cryptoType) {
    final allAddresses = getAllAddresses();
    return allAddresses
        .where((element) => element.cryptoType == cryptoType)
        .toList();
  }

  List<WalletAddress> getAllAddresses() {
    final addresses = _accountSettingsDB.values
        .map((value) => WalletAddress.fromJson(jsonDecode(value) as Map<String, dynamic>))
        .toList();
    return addresses;
  }

  Future<void> insertAddresses(List<WalletAddress> addresses) async {
    await _accountSettingsDB
        .write(addresses.map((address) => address.toKeyValue).toList());
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

  AccountSettingsDB get accountSettingsDB => _accountSettingsDB;
}
