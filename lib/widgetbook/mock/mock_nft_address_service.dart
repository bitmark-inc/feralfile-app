import 'package:autonomy_flutter/nft_collection/models/address_collection.dart';
import 'package:autonomy_flutter/nft_collection/services/address_service.dart';
import 'mock_nft_collection_database.dart';

class MockNftAddressService extends AddressService {
  MockNftAddressService() : super(MockNftCollectionDatabase());

  @override
  Future<void> addAddresses(List<String> addresses) async {}

  @override
  Future<void> deleteAddresses(List<String> addresses) async {}

  @override
  Future<List<AddressCollection>> getAllAddresses() async {
    return [];
  }

  @override
  Future<List<String>> getActiveAddresses() async {
    return [];
  }

  @override
  Future<List<String>> getHiddenAddresses() async {
    return [];
  }

  @override
  Future<void> setIsHiddenAddresses(
      List<String> addresses, bool isHidden) async {}

  @override
  Future<void> updateRefreshedTime(
      List<String> addresses, DateTime time) async {}
}
