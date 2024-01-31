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
}
