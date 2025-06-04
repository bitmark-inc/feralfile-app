import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/util/constants.dart';

class MockWalletData {
  static List<WalletAddress> getAddresses() {
    return [
      WalletAddress(
        address: '0x1234567890abcdef1234567890abcdef12345678',
        createdAt: DateTime.now(),
        name: 'Ethereum',
      ),
      WalletAddress(
        address: 'tz1abcdefghijklmnopqrstuvwxyz1234567890',
        createdAt: DateTime.now(),
        name: 'Tezos',
      ),
      WalletAddress(
        address: '0xabcdef1234567890abcdef1234567890abcdef12',
        createdAt: DateTime.now(),
        name: 'USDC',
      ),
    ];
  }

  static List<WalletAddress> getEmptyAddresses() {
    return [];
  }

  static List<WalletAddress> getNoEditAddresses() {
    return [
      WalletAddress(
        address: '0x1234567890abcdef1234567890abcdef12345678',
        createdAt: DateTime.now(),
        name: 'Ethereum',
        isHidden: true,
      ),
      WalletAddress(
        address: 'tz1abcdefghijklmnopqrstuvwxyz1234567890',
        createdAt: DateTime.now(),
        name: 'Tezos',
        isHidden: true,
      ),
    ];
  }
}
