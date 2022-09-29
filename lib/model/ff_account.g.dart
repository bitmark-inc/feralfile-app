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

Exhibition _$ExhibitionFromJson(Map<String, dynamic> json) => Exhibition(
      AirdropInfo.fromJson(json['airdrop_info'] as Map<String, dynamic>),
      json['title'] as String,
      json['cover_uri'] as String,
      json['thumbnail_cover_uri'] as String,
    );

Map<String, dynamic> _$ExhibitionToJson(Exhibition instance) =>
    <String, dynamic>{
      'title': instance.title,
      'cover_uri': instance.coverUri,
      'thumbnail_cover_uri': instance.thumbnailCoverUri,
      'airdrop_info': instance.airdrop,
    };

AirdropInfo _$AirdropInfoFromJson(Map<String, dynamic> json) => AirdropInfo(
      json['contract'] as String,
      json['leftEdition'] as int,
    );

Map<String, dynamic> _$AirdropInfoToJson(AirdropInfo instance) =>
    <String, dynamic>{
      'contract': instance.contract,
      'leftEdition': instance.leftEdition,
    };

TokenClaimResponse _$TokenClaimResponseFromJson(Map<String, dynamic> json) =>
    TokenClaimResponse(
      json['contract'] as String,
      json['tokenId'] as String,
    );

Map<String, dynamic> _$TokenClaimResponseToJson(TokenClaimResponse instance) =>
    <String, dynamic>{
      'contract': instance.contract,
      'tokenId': instance.tokenId,
    };
