import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web3dart/json_rpc.dart';

extension RPCErrorExtension on RPCError {
  bool get isNotEnoughBalance => message == EthError.notEnoughBalance.message;

  EthError get ethError {
    if (isNotEnoughBalance) {
      return EthError.notEnoughBalance;
    } else {
      return EthError.other;
    }
  }

  String get errorMessage {
    switch (ethError) {
      case EthError.notEnoughBalance:
        return 'not_enough_eth'.tr();
      default:
        return message.capitalize();
    }
  }
}

enum EthError {
  notEnoughBalance,
  other;

  String get message {
    switch (this) {
      case EthError.notEnoughBalance:
        return 'insufficient funds for transfer';
      default:
        return 'Unknown error';
    }
  }
}
