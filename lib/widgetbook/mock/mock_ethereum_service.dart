import 'dart:typed_data';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:web3dart/web3dart.dart';

class MockEthereumService implements EthereumService {
  @override
  Future<EtherAmount> getBalance(String address, {bool doRetry = false}) async {
    // Mock balance for testing
    return EtherAmount.fromBigInt(
      EtherUnit.ether,
      BigInt.from(1), // 1 ETH
    );
  }

  @override
  Future<String> getFeralFileTokenMetadata(
    EthereumAddress contract,
    Uint8List data,
  ) async {
    // Mock metadata response
    return '''
    {
      "name": "Mock NFT",
      "description": "This is a mock NFT for testing",
      "image": "https://example.com/mock-image.jpg",
      "attributes": [
        {
          "trait_type": "Mock Trait",
          "value": "Mock Value"
        }
      ]
    }
    ''';
  }
}
