import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:web3dart/web3dart.dart';

extension EtherAmountExtension on EtherAmount {
  EtherAmount operator +(EtherAmount other) {
    final BigInt resultInWei = getInWei + other.getInWei;
    return EtherAmount.inWei(resultInWei);
  }

  EtherAmount operator -(EtherAmount other) {
    final BigInt resultInWei = getInWei - other.getInWei;
    return EtherAmount.inWei(
        resultInWei > BigInt.zero ? resultInWei : BigInt.zero);
  }

  String get toEthStringValue => '${EthAmountFormatter().format(getInWei)} ETH';
}
