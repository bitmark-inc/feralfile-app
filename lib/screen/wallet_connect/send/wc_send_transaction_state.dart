import 'package:wallet_connect/models/wc_peer_meta.dart';
import 'package:web3dart/web3dart.dart';

abstract class WCSendTransactionEvent {}

class WCSendTransactionEstimateEvent extends WCSendTransactionEvent {
  final EthereumAddress address;
  final EtherAmount amount;

  WCSendTransactionEstimateEvent(this.address, this.amount);
}

class WCSendTransactionSendEvent extends WCSendTransactionEvent {
  final WCPeerMeta peerMeta;
  final int requestId;
  final EthereumAddress to;
  final BigInt value;
  final BigInt? gas;
  final String? data;

  WCSendTransactionSendEvent(this.peerMeta, this.requestId, this.to, this.value, this.gas, this.data);
}

class WCSendTransactionRejectEvent extends WCSendTransactionEvent {
  final WCPeerMeta peerMeta;
  final int requestId;

  WCSendTransactionRejectEvent(this.peerMeta, this.requestId);
}

class WCSendTransactionState {
  BigInt? fee;
}