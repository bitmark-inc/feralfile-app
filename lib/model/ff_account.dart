import 'dart:ffi';

import 'package:json_annotation/json_annotation.dart';

part 'ff_account.g.dart';

@JsonSerializable()
class FFAccount {
  String accountNumber;
  String email;
  String alias;
  String location;
  String website;
  String avatarURI;
  WyreWallet? wyreWallet;

  FFAccount(
      {required this.accountNumber,
      required this.email,
      required this.alias,
      required this.location,
      required this.website,
      required this.avatarURI,
      required this.wyreWallet});

  factory FFAccount.fromJson(Map<String, dynamic> json) =>
      _$FFAccountFromJson(json);

  Map<String, dynamic> toJson() => _$FFAccountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable()
class WyreWallet {
  Map<String, double> availableBalances;

  WyreWallet({
    required this.availableBalances,
  });

  factory WyreWallet.fromJson(Map<String, dynamic> json) =>
      _$WyreWalletFromJson(json);

  Map<String, dynamic> toJson() => _$WyreWalletToJson(this);
}
