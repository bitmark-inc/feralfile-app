import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/setting_object.dart';
import 'package:nft_collection/models/address_index.dart';

class WalletAddress implements SettingObject {
  final String address;
  final String cryptoType;
  final DateTime createdAt;
  final bool isHidden;
  final String? name;

  WalletAddress({
    required this.address,
    required this.cryptoType,
    required this.createdAt,
    this.isHidden = false,
    this.name,
  });

  WalletAddress copyWith({
    String? address,
    String? cryptoType,
    DateTime? createdAt,
    bool? isHidden,
    String? name,
  }) =>
      WalletAddress(
        address: address ?? this.address,
        cryptoType: cryptoType ?? this.cryptoType,
        createdAt: createdAt ?? this.createdAt,
        isHidden: isHidden ?? this.isHidden,
        name: name ?? this.name,
      );

  AddressIndex get addressIndex =>
      AddressIndex(address: address, createdAt: createdAt);

  // fromJson and toJson methods
  factory WalletAddress.fromJson(Map<String, dynamic> json) => WalletAddress(
        address: json['address'] as String,
        cryptoType: json['cryptoType'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isHidden: json['isHidden'] as bool,
        name: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'address': address,
        'cryptoType': cryptoType,
        'createdAt': createdAt.toIso8601String(),
        'isHidden': isHidden,
        'name': name,
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
