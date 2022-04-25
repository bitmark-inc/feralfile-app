// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Audit _$AuditFromJson(Map<String, dynamic> json) => Audit(
      uuid: json['uuid'] as String,
      category: json['category'] as String,
      action: json['action'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as String,
    );

Map<String, dynamic> _$AuditToJson(Audit instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'category': instance.category,
      'action': instance.action,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
    };
