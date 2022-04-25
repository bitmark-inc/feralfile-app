import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/credentials.dart';

extension StringExtension on WalletStorage {
  Future<String> getETHEip55Address() async {
    String address = await this.getETHAddress();
    if (address.isNotEmpty) {
      return EthereumAddress.fromHex(address).hexEip55;
    } else {
      return "";
    }
  }
}