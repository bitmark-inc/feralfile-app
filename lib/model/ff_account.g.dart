// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ff_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FFAccount _$FFAccountFromJson(Map<String, dynamic> json) => FFAccount(
      id: json['ID'] as String? ?? '',
      alias: json['alias'] as String,
      location: json['location'] as String,
      wyreWallet: json['wyreWallet'] == null
          ? null
          : WyreWallet.fromJson(json['wyreWallet'] as Map<String, dynamic>),
      vaultAddresses: (json['vaultAddresses'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$FFAccountToJson(FFAccount instance) => <String, dynamic>{
      'ID': instance.id,
      'alias': instance.alias,
      'location': instance.location,
      'wyreWallet': instance.wyreWallet,
      'vaultAddresses': instance.vaultAddresses,
    };

WyreWallet _$WyreWalletFromJson(Map<String, dynamic> json) => WyreWallet(
      availableBalances:
          (json['availableBalances'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$WyreWalletToJson(WyreWallet instance) =>
    <String, dynamic>{
      'availableBalances': instance.availableBalances,
    };
