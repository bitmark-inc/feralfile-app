import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:easy_localization/easy_localization.dart';

// ignore_for_file: constant_identifier_names

enum FeeOption {
  LOW,
  MEDIUM,
  HIGH,
}

extension FeeOptionExtention on FeeOption {
  int get tezosBaseOperationCustomFee {
    switch (this) {
      case FeeOption.LOW:
        return baseOperationCustomFeeLow;
      case FeeOption.MEDIUM:
        return baseOperationCustomFeeMedium;
      default:
        return baseOperationCustomFeeHigh;
    }
  }

  String get name {
    switch (this) {
      case FeeOption.LOW:
        return 'low'.tr();
      case FeeOption.MEDIUM:
        return 'medium'.tr();
      default:
        return 'high'.tr();
    }
  }

  BigInt get getEthereumPriorityFee {
    switch (this) {
      case FeeOption.LOW:
        return BigInt.from(1000000000);
      case FeeOption.MEDIUM:
        return BigInt.from(1500000000);
      default:
        return BigInt.from(2000000000);
    }
  }
}

class FeeOptionValue {
  final BigInt low;
  final BigInt medium;
  final BigInt high;

  FeeOptionValue(this.low, this.medium, this.high);

  BigInt getFee(FeeOption feeOption) {
    switch (feeOption) {
      case FeeOption.LOW:
        return low;
      case FeeOption.MEDIUM:
        return medium;
      default:
        return high;
    }
  }

  FeeOptionValue multipleBy(BigInt gas) =>
      FeeOptionValue(low * gas, medium * gas, high * gas);
}
