import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'mock_wallet_data.dart';

class MockCloudManager extends CloudManager {
  MockCloudManager() : super();

  @override
  List<WalletAddress> getAllAddresses() {
    return MockWalletData.getAddresses();
  }

  @override
  Future<void> deleteAddress(WalletAddress address) async {}

  @override
  Future<void> insertAddresses(List<WalletAddress> addresses) async {}

  @override
  Future<void> setAddressIsHidden(String address, bool isHidden) async {}

  @override
  Future<void> updateAddresses(List<WalletAddress> addresses) async {}
}
