//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
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

  WalletStorage wallet() {
    return LibAukDart.getWallet(uuid);
  }

  bool isDefault() => defaultAccount == 1;

  Future<List<String>> getAddresses() async {
    final List<String> addresses = [];
    addresses.addAll(await getEthAddresses());
    addresses.addAll(await getTezosAddresses());
    return addresses;
  }

  Future<List<String>> getEthAddresses() async {
    return await Future.wait(
        getEthIndexes().map((e) => wallet().getETHEip55Address(index: e)));
  }

  Future<List<String>> getTezosAddresses() async {
    return await Future.wait(
        getTezIndexes().map((e) => wallet().getTezosAddress(index: e)));
  }

  List<int> getEthIndexes() {
    return _getIndexes(ethereumIndexes ?? "");
  }

  List<int> getTezIndexes() {
    return _getIndexes(tezosIndexes ?? "");
  }

  Future<int?> getEthAddressIndex(String address) async {
    final listIndex = getEthIndexes();
    for (int i = 0; i < listIndex.length; i++) {
      if ((await wallet().getETHEip55Address(index: listIndex[i])) == address) {
        return listIndex[i];
      }
    }
    return null;
  }

  Future<int?> getTezAddressIndex(String address) async {
    final listIndex = getTezIndexes();
    for (int i = 0; i < listIndex.length; i++) {
      if ((await wallet().getTezosAddress(index: listIndex[i])) == address) {
        return listIndex[i];
      }
    }
    return null;
  }

  List<int> _getIndexes(String str) {
    List<String> indexes = str.split(',');
    indexes.removeWhere((element) => element.isEmpty);
    return indexes.map((e) => int.parse(e)).toList();
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
