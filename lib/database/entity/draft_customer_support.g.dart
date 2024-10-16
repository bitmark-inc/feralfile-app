// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_customer_support.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DraftCustomerSupportData _$DraftCustomerSupportDataFromJson(
        Map<String, dynamic> json) =>
    DraftCustomerSupportData(
      text: json['text'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => LocalAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      title: json['title'] as String?,
      artworkReportID: json['artworkReportID'] as String?,
      rating: json['rating'] as int? ?? 0,
    );

Map<String, dynamic> _$DraftCustomerSupportDataToJson(
        DraftCustomerSupportData instance) =>
    <String, dynamic>{
      'text': instance.text,
      'attachments': instance.attachments,
      'title': instance.title,
      'rating': instance.rating,
      'artworkReportID': instance.artworkReportID,
    };

LocalAttachment _$LocalAttachmentFromJson(Map<String, dynamic> json) =>
    LocalAttachment(
      path: json['path'] as String,
      fileName: json['fileName'] as String,
    );

Map<String, dynamic> _$LocalAttachmentToJson(LocalAttachment instance) =>
    <String, dynamic>{
      'path': instance.path,
      'fileName': instance.fileName,
    };
