import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ether_amount_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:web3dart/web3dart.dart';

extension BigIntExtension on BigInt {
  String get toXTZStringValue =>
      '${XtzAmountFormatter().format(this.toInt())} XTZ';

  String get toEthStringValue =>
      EtherAmount.fromBigInt(EtherUnit.wei, this).toEthStringValue;

  String toBalanceStringValue(CryptoType cryptoType) {
    switch (cryptoType) {
      case CryptoType.XTZ:
        return toXTZStringValue;
      case CryptoType.ETH:
        return toEthStringValue;
      case CryptoType.USDC:
      case CryptoType.UNKNOWN:
        return '--';
    }
  }
}

extension MapExtention on Map {
  Map<K, T> typeCast<K, T>() {
    if (this is Map<K, T>) {
      return this as Map<K, T>;
    } else {
      // Attempt to cast the map elements
      return map<K, T>(
        (key, value) => MapEntry(key as K, value as T),
      );
    }
  }
}
