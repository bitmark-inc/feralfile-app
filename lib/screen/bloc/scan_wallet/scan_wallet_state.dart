import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/web3dart.dart';

class ScanWalletState {
  final List<AddressInfo> addresses;
  final bool hitStopGap;
  final bool isScanning;

  //constructor
  ScanWalletState(
      {required this.addresses,
      this.hitStopGap = false,
      this.isScanning = false});

  //add new addresses
  ScanWalletState addNewAddresses(List<AddressInfo> addresses,
      {bool? hitStopGap, bool? isScanning}) {
    return ScanWalletState(
        addresses: [...this.addresses, ...addresses],
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
  final bool isAdd;

  //constructor
  ScanEthereumWalletEvent(
      {required this.wallet,
      this.startIndex = 0,
      this.gapLimit = 5,
      this.maxLength = 5,
      this.showEmptyAddresses = true,
      this.isAdd = false});
}

class ScanTezosWalletEvent extends ScanWalletEvent {
  final WalletStorage wallet;
  final int startIndex;
  final int gapLimit;
  final int maxLength;
  final bool showEmptyAddresses;
  final bool isAdd;

  //constructor
  ScanTezosWalletEvent(
      {required this.wallet,
      this.startIndex = 0,
      this.gapLimit = 5,
      this.maxLength = 5,
      this.showEmptyAddresses = true,
      this.isAdd = false});
}

abstract class AddressInfo {
  int get index;

  String get address;

  String getBalance();

  CryptoType getCryptoType();

  bool hasBalance();
}

class EthereumAddressInfo implements AddressInfo {
  @override
  final int index;
  @override
  final String address;
  final EtherAmount balance;

  //constructor
  EthereumAddressInfo(this.index, this.address, this.balance);

  // override toString
  @override
  String toString() {
    return 'EthereumAddressInfo{index: $index, address: $address, balance: ${balance.getInWei}}';
  }

  @override
  String getBalance() {
    return "${EthAmountFormatter(balance.getInWei).format()} ETH";
  }

  @override
  getCryptoType() {
    return CryptoType.ETH;
  }

  @override
  bool hasBalance() => balance.getInWei > BigInt.zero;
}

class TezosAddressInfo implements AddressInfo {
  @override
  final int index;
  @override
  final String address;
  final int balance;

  //constructor
  TezosAddressInfo(this.index, this.address, this.balance);

  // override toString
  @override
  String toString() {
    return 'TezosAddressInfo{index: $index, address: $address, balance: $balance}';
  }

  @override
  String getBalance() {
    return "${XtzAmountFormatter(balance).format()} XTZ";
  }

  @override
  CryptoType getCryptoType() {
    return CryptoType.XTZ;
  }

  @override
  bool hasBalance() => balance > 0;
}
