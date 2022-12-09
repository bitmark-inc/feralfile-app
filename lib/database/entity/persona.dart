//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

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

  Persona(
      {required this.uuid,
      required this.name,
      required this.createdAt,
      this.defaultAccount});

  Persona.newPersona(
      {required this.uuid,
      this.name = "",
      this.defaultAccount,
      DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Persona copyWith({
    String? name,
    DateTime? createdAt,
  }) {
    return Persona(
        uuid: uuid,
        name: name ?? this.name,
        defaultAccount: defaultAccount,
        createdAt: createdAt ?? this.createdAt);
  }

  WalletStorage wallet() {
    return LibAukDart.getWallet(uuid);
  }

  bool isDefault() => defaultAccount == 1;

  @override
  bool operator ==(covariant Persona other) {
    if (identical(this, other)) return true;

    return other.uuid == uuid &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.defaultAccount == defaultAccount;
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        defaultAccount.hashCode;
  }
}
