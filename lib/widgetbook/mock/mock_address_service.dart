import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/util/constants.dart';

import 'mock_cloud_manager.dart';
import 'mock_wallet_data.dart';
import 'nft_collection/mock_nft_address_service.dart' as nft;

class MockAddressService extends AddressService {
  MockAddressService() : super(MockCloudManager(), nft.MockNftAddressService());

  @override
  List<WalletAddress> getAllWalletAddresses(
      {CryptoType? chain, bool? isHidden}) {
    return MockWalletData.getAddresses();
  }

  @override
  Future<void> deleteAddress(WalletAddress address) async {}

  @override
  Future<WalletAddress> insertAddress(WalletAddress address,
      {bool checkAddressDuplicated = true}) async {
    return address;
  }

  @override
  Future<void> insertAddresses(List<WalletAddress> addresses) async {}

  @override
  Future<WalletAddress> nameAddress(WalletAddress address, String name) async {
    return address;
  }

  @override
  Future<void> setHiddenStatus(
      {required List<String> addresses, required bool isHidden}) async {}
}
