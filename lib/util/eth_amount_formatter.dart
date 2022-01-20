import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';

class EthAmountFormatter {
  EthAmountFormatter(this.amount);

  final BigInt amount;
  String format({
    fromUnit = EtherUnit.wei,
    toUnit = EtherUnit.ether,
  }) {
    if (amount == BigInt.zero) return "0.0";

    return EtherAmount.fromUnitAndValue(fromUnit, amount)
        .getValueInUnit(toUnit)
        .toString()
        .characters
        .take(7)
        .toString();
  }
}