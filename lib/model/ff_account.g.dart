// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ff_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FFAccount _$FFAccountFromJson(Map<String, dynamic> json) {
  return FFAccount(
    accountNumber: json['accountNumber'] as String,
    email: json['email'] as String,
    alias: json['alias'] as String,
    location: json['location'] as String,
    website: json['website'] as String,
    avatarURI: json['avatarURI'] as String,
    wyreWallet: json['wyreWallet'] == null
        ? null
        : WyreWallet.fromJson(json['wyreWallet'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FFAccountToJson(FFAccount instance) => <String, dynamic>{
      'accountNumber': instance.accountNumber,
      'email': instance.email,
      'alias': instance.alias,
      'location': instance.location,
      'website': instance.website,
      'avatarURI': instance.avatarURI,
      'wyreWallet': instance.wyreWallet,
    };

WyreWallet _$WyreWalletFromJson(Map<String, dynamic> json) {
  return WyreWallet(
    availableBalances: (json['availableBalances'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, (e as num).toDouble()),
    ),
  );
}

Map<String, dynamic> _$WyreWalletToJson(WyreWallet instance) =>
    <String, dynamic>{
      'availableBalances': instance.availableBalances,
    };
