// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wc_connected_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WCConnectedSession _$WCConnectedSessionFromJson(Map<String, dynamic> json) =>
    WCConnectedSession(
      sessionStore:
          WCSessionStore.fromJson(json['sessionStore'] as Map<String, dynamic>),
      accounts:
          (json['accounts'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$WCConnectedSessionToJson(WCConnectedSession instance) =>
    <String, dynamic>{
      'sessionStore': instance.sessionStore,
      'accounts': instance.accounts,
    };
