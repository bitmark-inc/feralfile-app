import 'package:easy_localization/easy_localization.dart';

import '../service/tezos_service.dart';

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
        return "low".tr();
      case FeeOption.MEDIUM:
        return "medium".tr();
      default:
        return "high".tr();
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
