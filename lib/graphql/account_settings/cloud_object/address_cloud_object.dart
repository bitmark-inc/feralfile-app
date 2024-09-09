import 'dart:convert';

import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';

class WalletAddressCloudObject {
  final AccountSettingsDB _accountSettingsDB;

  WalletAddressCloudObject(this._accountSettingsDB);

  Future<void> deleteAddress(WalletAddress address) async {
    await _accountSettingsDB.delete([address.key]);
  }

  Future<void> deleteAddressesByPersona(String uuid) async {
    final addressesWithUUid = findByWalletID(uuid);
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
    final value = _accountSettingsDB.query([address]);
    if (value.isEmpty) {
      return null;
    }
    final addressJson = jsonDecode(value.first['value']!);
    return WalletAddress.fromJson(addressJson);
  }

  List<WalletAddress> findByWalletID(String uuid) {
    final allAddresses = getAllAddresses();
    return allAddresses.where((element) => element.uuid == uuid).toList();
  }

  List<WalletAddress> getAddresses(String uuid, String cryptoType) {
    final allAddresses = getAllAddresses();
    return allAddresses
        .where((element) =>
            element.uuid == uuid && element.cryptoType == cryptoType)
        .toList();
  }

  List<WalletAddress> getAddressesByPersona(String uuid) {
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
    final cache = _accountSettingsDB.caches;
    final addresses = cache.values
        .map((value) => WalletAddress.fromJson(jsonDecode(value)))
        .toList();
    return addresses;
  }

  Future<void> insertAddresses(List<WalletAddress> addresses) async {
    await _accountSettingsDB
        .write(addresses.map((address) => address.toKeyValue).toList());
  }

  Future<void> removeAll() async {
    final keys = _accountSettingsDB.caches.keys.toList();
    await _accountSettingsDB.delete(keys);
  }

  Future<void> setAddressIsHidden(String address, bool isHidden) async {
    final walletAddress = findByAddress(address);
    if (walletAddress == null) {
      return;
    }
    await updateAddress(walletAddress.copyWith(isHidden: isHidden));
  }

  Future<void> updateAddress(WalletAddress address) async {
    await _accountSettingsDB.write([address.toKeyValue]);
  }

  Future<void> updateAddresses(List<WalletAddress> addresses) async {
    await _accountSettingsDB.write(addresses.map((e) => e.toKeyValue).toList());
  }

  AccountSettingsDB get accountSettingsDB => _accountSettingsDB;
}
