import 'package:autonomy_flutter/database/dao/address_dao.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';

class WalletAddressDaoImpl implements WalletAddressDao {
  @override
  Future<void> deleteAddress(WalletAddress address) {
    // TODO: implement deleteAddress
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAddressesByPersona(String uuid) {
    // TODO: implement deleteAddressesByPersona
    throw UnimplementedError();
  }

  @override
  Future<List<WalletAddress>> findAddressesWithHiddenStatus(bool isHidden) {
    // TODO: implement findAddressesWithHiddenStatus
    throw UnimplementedError();
  }

  @override
  Future<WalletAddress?> findByAddress(String address) {
    // TODO: implement findByAddress
    throw UnimplementedError();
  }

  @override
  Future<List<WalletAddress>> findByWalletID(String uuid) {
    // TODO: implement findByWalletID
    throw UnimplementedError();
  }

  @override
  Future<List<WalletAddress>> getAddresses(String uuid, String cryptoType) {
    // TODO: implement getAddresses
    throw UnimplementedError();
  }

  @override
  Future<List<WalletAddress>> getAddressesByPersona(String uuid) {
    // TODO: implement getAddressesByPersona
    throw UnimplementedError();
  }

  @override
  Future<List<WalletAddress>> getAddressesByType(String cryptoType) {
    // TODO: implement getAddressesByType
    throw UnimplementedError();
  }

  @override
  Future<List<WalletAddress>> getAllAddresses() {
    // TODO: implement getAllAddresses
    throw UnimplementedError();
  }

  @override
  Future<void> insertAddress(WalletAddress address) {
    // TODO: implement insertAddress
    throw UnimplementedError();
  }

  @override
  Future<void> insertAddresses(List<WalletAddress> addresses) {
    // TODO: implement insertAddresses
    throw UnimplementedError();
  }

  @override
  Future<void> removeAll() {
    // TODO: implement removeAll
    throw UnimplementedError();
  }

  @override
  Future<void> setAddressIsHidden(String address, bool isHidden) {
    // TODO: implement setAddressIsHidden
    throw UnimplementedError();
  }

  @override
  Future<void> setAddressOrder(String address, int accountOrder) {
    // TODO: implement setAddressOrder
    throw UnimplementedError();
  }

  @override
  Future<void> updateAddress(WalletAddress address) {
    // TODO: implement updateAddress
    throw UnimplementedError();
  }
}
