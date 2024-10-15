import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/setting_object.dart';
import 'package:nft_collection/models/address_index.dart';

class WalletAddress implements SettingObject {
  final String address;
  final String uuid;
  final int index;
  final String cryptoType;
  final DateTime createdAt;
  final bool isHidden;
  final String? name;
  final int? accountOrder;

  WalletAddress(
      {required this.address,
      required this.uuid,
      required this.index,
      required this.cryptoType,
      required this.createdAt,
      this.isHidden = false,
      this.name,
      this.accountOrder});

  WalletAddress copyWith({
    String? address,
    String? uuid,
    int? index,
    String? cryptoType,
    DateTime? createdAt,
    bool? isHidden,
    String? name,
    int? accountOrder,
  }) =>
      WalletAddress(
        address: address ?? this.address,
        uuid: uuid ?? this.uuid,
        index: index ?? this.index,
        cryptoType: cryptoType ?? this.cryptoType,
        createdAt: createdAt ?? this.createdAt,
        isHidden: isHidden ?? this.isHidden,
        name: name ?? this.name,
        accountOrder: accountOrder ?? this.accountOrder,
      );

  AddressIndex get addressIndex =>
      AddressIndex(address: address, createdAt: createdAt);

  // fromJson and toJson methods
  factory WalletAddress.fromJson(Map<String, dynamic> json) => WalletAddress(
        address: json['address'] as String,
        uuid: json['uuid'] as String,
        index: json['index'] as int,
        cryptoType: json['cryptoType'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isHidden: json['isHidden'] as bool,
        name: json['name'] as String?,
        accountOrder: json['accountOrder'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'address': address,
        'uuid': uuid,
        'index': index,
        'cryptoType': cryptoType,
        'createdAt': createdAt.toIso8601String(),
        'isHidden': isHidden,
        'name': name,
        'accountOrder': accountOrder,
      };

  @override
  String get key => address;

  @override
  Map<String, String> get toKeyValue => {
        'key': key,
        'value': value,
      };

  @override
  String get value => jsonEncode(toJson());
}
