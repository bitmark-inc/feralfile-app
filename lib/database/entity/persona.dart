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

  Persona(
      {required this.uuid,
      required this.name,
      required this.createdAt,
      this.defaultAccount,
      this.ethereumIndex = 1,
      this.tezosIndex = 1});

  Persona.newPersona(
      {required this.uuid,
      this.name = "",
      this.defaultAccount,
      DateTime? createdAt,
      this.ethereumIndex = 1,
      this.tezosIndex = 1})
      : createdAt = createdAt ?? DateTime.now();

  Persona copyWith({
    String? name,
    DateTime? createdAt,
    int? ethereumIndex,
    int? tezosIndex,
  }) {
    return Persona(
        uuid: uuid,
        name: name ?? this.name,
        defaultAccount: defaultAccount,
        createdAt: createdAt ?? this.createdAt,
        ethereumIndex: ethereumIndex ?? this.ethereumIndex,
        tezosIndex: tezosIndex ?? this.tezosIndex);
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
    final List<String> addresses = [];
    for (int i = 0; i < ethereumIndex; i++) {
      addresses.add(await wallet().getETHAddress(index: i));
    }
    return addresses;
  }

  Future<List<String>> getTezosAddresses() async {
    final List<String> addresses = [];
    for (int i = 0; i < tezosIndex; i++) {
      addresses.add(await wallet().getTezosAddress(index: i));
    }
    return addresses;
  }

  @override
  bool operator ==(covariant Persona other) {
    if (identical(this, other)) return true;

    return other.uuid == uuid &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.defaultAccount == defaultAccount &&
        other.ethereumIndex == ethereumIndex &&
        other.tezosIndex == tezosIndex;
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        defaultAccount.hashCode ^
        ethereumIndex.hashCode ^
        tezosIndex.hashCode;
  }
}
