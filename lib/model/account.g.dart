// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) {
  return Account(
    accountNumber: json['accountNumber'] as String,
    email: json['email'] as String,
    alias: json['alias'] as String,
    fullName: json['fullName'] as String,
    bio: json['bio'] as String,
    location: json['location'] as String,
    website: json['website'] as String,
    avatarURI: json['avatarURI'] as String,
  );
}

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
      'accountNumber': instance.accountNumber,
      'email': instance.email,
      'alias': instance.alias,
      'fullName': instance.fullName,
      'bio': instance.bio,
      'location': instance.location,
      'website': instance.website,
      'avatarURI': instance.avatarURI,
    };
