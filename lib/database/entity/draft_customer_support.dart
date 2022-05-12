import 'dart:convert';

import 'package:floor/floor.dart';
import 'package:json_annotation/json_annotation.dart';

part 'draft_customer_support.g.dart';

enum CSMessageType {
  CreateIssue,
  PostMessage,
  PostPhotos,
  PostLogs,
}

extension RawValue on CSMessageType {
  String get rawValue => this.toString().split('.').last;
}

@entity
class DraftCustomerSupport {
  @primaryKey
  String uuid;
  String issueID;
  String type;
  String data; // jsonData
  DateTime createdAt;
  String reportIssueType;
  String mutedMessages;

  DraftCustomerSupport({
    required this.uuid,
    required this.issueID,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.reportIssueType,
    this.mutedMessages = '',
  });
}

extension Supporter on DraftCustomerSupport {
  DraftCustomerSupportData get draftData =>
      DraftCustomerSupportData.fromJson(jsonDecode(data));
}

@JsonSerializable()
class DraftCustomerSupportData {
  String? text;
  List<LocalAttachment>? attachments;
  String? title;

  DraftCustomerSupportData({
    this.text,
    this.attachments,
    this.title,
  });

  factory DraftCustomerSupportData.fromJson(Map<String, dynamic> json) =>
      _$DraftCustomerSupportDataFromJson(json);

  Map<String, dynamic> toJson() => _$DraftCustomerSupportDataToJson(this);
}

@JsonSerializable()
class LocalAttachment {
  String path;
  String fileName;

  LocalAttachment({
    required this.path,
    required this.fileName,
  });

  factory LocalAttachment.fromJson(Map<String, dynamic> json) =>
      _$LocalAttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$LocalAttachmentToJson(this);
}
