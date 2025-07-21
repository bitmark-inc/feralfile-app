import 'package:autonomy_flutter/nft_collection/database/dao/address_collection_dao.dart';
import 'package:autonomy_flutter/nft_collection/models/address_collection.dart';

class MockAddressCollectionDao extends AddressCollectionDao {
  @override
  Future<void> insertAddressesAbort(List<AddressCollection> addresses) async {}

  @override
  Future<void> deleteAddresses(List<String> addresses) async {}

  @override
  Future<List<AddressCollection>> findAllAddresses() async {
    return [];
  }

  @override
  Future<List<String>> findAddressesIsHidden(bool isHidden) async {
    return [];
  }

  @override
  Future<void> setAddressIsHidden(
      List<String> addresses, bool isHidden) async {}

  @override
  Future<void> updateRefreshTime(List<String> addresses, int time) async {}

  @override
  Future<void> deleteAddress(AddressCollection address) async {}

  @override
  Future<List<AddressCollection>> findAddresses(List<String> addresses) async {
    return [];
  }

  @override
  Future<void> insertAddresses(List<AddressCollection> addresses) async {}

  @override
  Future<void> removeAll() async {}

  @override
  Future<void> updateAddresses(List<AddressCollection> addresses) async {}
}
