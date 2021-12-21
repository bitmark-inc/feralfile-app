import 'package:web3dart/web3dart.dart';

abstract class WCSendTransactionEvent {}

class WCSendTransactionEstimateEvent extends WCSendTransactionEvent {
  final EthereumAddress address;
  final EtherAmount amount;

  WCSendTransactionEstimateEvent(this.address, this.amount);
}

class WCSendTransactionSendEvent extends WCSendTransactionEvent {
  final requestId;
  final EthereumAddress to;
  final BigInt value;
  final BigInt? gas;
  final String? data;

  WCSendTransactionSendEvent(this.requestId, this.to, this.value, this.gas, this.data);
}

class WCSendTransactionRejectEvent extends WCSendTransactionEvent {
  final requestId;

  WCSendTransactionRejectEvent(this.requestId);
}

class WCSendTransactionState {
  BigInt? fee;
}