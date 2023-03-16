import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/web3dart.dart';

class ScanWalletState {
  final List<EthereumAddressInfo> ethereumAddresses;
  final List<TezosAddressInfo> tezosAddresses;
  final bool hitStopGap;
  final bool isScanning;

  //constructor
  ScanWalletState(
      {required this.ethereumAddresses,
      required this.tezosAddresses,
      this.hitStopGap = false,
      this.isScanning = false});

  //add new addresses
  ScanWalletState addNewAddresses(List<EthereumAddressInfo> ethereumAddresses,
      List<TezosAddressInfo> tezosAddresses,
      {bool? hitStopGap, bool? isScanning}) {
    return ScanWalletState(
        ethereumAddresses: [...this.ethereumAddresses, ...ethereumAddresses],
        tezosAddresses: [...this.tezosAddresses, ...tezosAddresses],
        hitStopGap: hitStopGap ?? this.hitStopGap,
        isScanning: isScanning ?? this.isScanning);
  }
}

abstract class ScanWalletEvent {}

class ScanEthereumWalletEvent extends ScanWalletEvent {
  final WalletStorage wallet;
  final int startIndex;
  final int gapLimit;
  final int maxLength;
  final bool showEmptyAddresses;

  //constructor
  ScanEthereumWalletEvent(
      {required this.wallet,
      this.startIndex = 0,
      this.gapLimit = 2,
      this.maxLength = 10,
      this.showEmptyAddresses = true});
}

class ScanTezosWalletEvent extends ScanWalletEvent {
  final WalletStorage wallet;
  final int startIndex;
  final int gapLimit;
  final int maxLength;
  final bool showEmptyAddresses;

  //constructor
  ScanTezosWalletEvent(
      {required this.wallet,
      this.startIndex = 0,
      this.gapLimit = 2,
      this.maxLength = 10,
      this.showEmptyAddresses = true});
}

class EthereumAddressInfo {
  final int index;
  final String address;
  final EtherAmount balance;

  //constructor
  EthereumAddressInfo(this.index, this.address, this.balance);

  // override toString
  @override
  String toString() {
    return 'EthereumAddressInfo{index: $index, address: $address, balance: ${balance.getInWei}}';
  }
}

class TezosAddressInfo {
  final int index;
  final String address;
  final int balance;

  //constructor
  TezosAddressInfo(this.index, this.address, this.balance);

  // override toString
  @override
  String toString() {
    return 'TezosAddressInfo{index: $index, address: $address, balance: $balance}';
  }
}
