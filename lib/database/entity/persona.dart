//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:floor/floor.dart';
import 'package:libauk_dart/libauk_dart.dart';

class DateTimeConverter extends TypeConverter<DateTime, int> {
  @override
  DateTime decode(int databaseValue) {
    return DateTime.fromMillisecondsSinceEpoch(databaseValue);
  }

  @override
  int encode(DateTime value) {
    return value.millisecondsSinceEpoch;
  }
}

@entity
class Persona {
  @primaryKey
  String uuid;
  String name;
  DateTime createdAt;
  int? defaultAccount;
  int ethereumIndex;
  int tezosIndex;
  String? ethereumIndexes;
  String? tezosIndexes;

  Persona(
      {required this.uuid,
      required this.name,
      required this.createdAt,
      this.defaultAccount,
      this.ethereumIndex = 1,
      this.tezosIndex = 1,
      this.ethereumIndexes = "",
      this.tezosIndexes = ""});

  Persona.newPersona(
      {required this.uuid,
      this.name = "",
      this.defaultAccount,
      DateTime? createdAt,
      this.ethereumIndex = 1,
      this.tezosIndex = 1,
      this.ethereumIndexes = "0",
      this.tezosIndexes = "0"})
      : createdAt = createdAt ?? DateTime.now();

  Persona copyWith({
    String? name,
    DateTime? createdAt,
    String? ethereumIndexes,
    String? tezosIndexes,
  }) {
    return Persona(
        uuid: uuid,
        name: name ?? this.name,
        defaultAccount: defaultAccount,
        createdAt: createdAt ?? this.createdAt,
        ethereumIndexes: ethereumIndexes ?? this.ethereumIndexes,
        tezosIndexes: tezosIndexes ?? this.tezosIndexes);
  }

  // fromJson method
  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      uuid: json['uuid'],
      name: json['name'],
      createdAt: DateTimeConverter().decode(json['createdAt']),
      defaultAccount: json['defaultAccount'],
      ethereumIndex: json['ethereumIndex'],
      tezosIndex: json['tezosIndex'],
      ethereumIndexes: json['ethereumIndexes'],
      tezosIndexes: json['tezosIndexes'],
    );
  }

  WalletStorage wallet() {
    return LibAukDart.getWallet(uuid);
  }

  Future<List<WalletAddress>> getWalletAddresses() async {
    return injector<CloudDatabase>().addressDao.findByWalletID(uuid);
  }

  Future<List<WalletAddress>> getEthWalletAddresses() async {
    return injector<CloudDatabase>()
        .addressDao
        .getAddresses(uuid, CryptoType.ETH.source);
  }

  Future<List<WalletAddress>> getTezWalletAddresses() async {
    return injector<CloudDatabase>()
        .addressDao
        .getAddresses(uuid, CryptoType.XTZ.source);
  }

  bool isDefault() => defaultAccount == 1;

  Future<List<String>> getAddresses() async {
    final walletAddress = await getWalletAddresses();
    return walletAddress.map((e) => e.address).toList();
  }

  Future<List<String>> getEthAddresses() async {
    final walletAddress = await getEthWalletAddresses();
    return walletAddress.map((e) => e.address).toList();
  }

  Future<List<String>> getTezosAddresses() async {
    final walletAddress = await getTezWalletAddresses();
    return walletAddress.map((e) => e.address).toList();
  }

  Future<int?> getAddressIndex(String address) async {
    final walletAddress =
        await injector<CloudDatabase>().addressDao.findByAddress(address);
    if (walletAddress != null) {
      return walletAddress.index;
    }
    return null;
  }

  Future<List<WalletAddress>> insertNextAddress(WalletType walletType,
      {String? name}) async {
    final List<WalletAddress> addresses = [];
    final walletAddresses = await getWalletAddresses();
    final ethIndexes = walletAddresses
        .where((element) => element.cryptoType == CryptoType.ETH.source)
        .map((e) => e.index)
        .toSet()
        .toList();
    final ethIndex = _getNextIndex(ethIndexes);
    final tezIndexes = walletAddresses
        .where((element) => element.cryptoType == CryptoType.XTZ.source)
        .map((e) => e.index)
        .toSet()
        .toList();
    final tezIndex = _getNextIndex(tezIndexes);
    final ethAddress = WalletAddress(
        address: await wallet().getETHEip55Address(index: ethIndex),
        uuid: uuid,
        index: ethIndex,
        cryptoType: CryptoType.ETH.source,
        createdAt: DateTime.now(),
        name: name ?? CryptoType.ETH.source);
    final tezAddress = WalletAddress(
        address: await wallet().getTezosAddress(index: tezIndex),
        uuid: uuid,
        index: tezIndex,
        cryptoType: CryptoType.XTZ.source,
        createdAt: DateTime.now(),
        name: name ?? CryptoType.XTZ.source);
    switch (walletType) {
      case WalletType.Ethereum:
        addresses.add(ethAddress);
        break;
      case WalletType.Tezos:
        addresses.add(tezAddress);
        break;
      default:
        addresses.addAll([ethAddress, tezAddress]);
    }
    await injector<CloudDatabase>().addressDao.insertAddresses(addresses);
    return addresses;
  }

  int _getNextIndex(List<int> indexes) {
    indexes.sort();
    if (indexes.isEmpty) {
      return 0;
    }
    return indexes.last + 1;
  }

  @override
  bool operator ==(covariant Persona other) {
    if (identical(this, other)) return true;

    return other.uuid == uuid &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.defaultAccount == defaultAccount &&
        other.ethereumIndexes == ethereumIndexes &&
        other.tezosIndexes == tezosIndexes;
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        defaultAccount.hashCode ^
        ethereumIndexes.hashCode ^
        tezosIndexes.hashCode;
  }
}
