import 'package:web3dart/credentials.dart';

class Wc2EthereumTransactionParam {
  final EthereumAddress to;
  final BigInt value;
  final BigInt? gas;
  final String? data;

  Wc2EthereumTransactionParam({
    required this.to,
    required this.value,
    this.gas,
    this.data,
  });

  factory Wc2EthereumTransactionParam.fromJson(Map<String, dynamic> json) {
    final to = EthereumAddress.fromHex(json['to'] as String);
    final value = BigInt.parse(json['value'] as String);
    final gas = BigInt.parse(json['gas'] as String);
    final data = json['data'] as String?;
    return Wc2EthereumTransactionParam(
      to: to,
      value: value,
      gas: gas,
      data: data,
    );
  }
}
