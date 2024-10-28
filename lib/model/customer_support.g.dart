// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_support.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Issue _$IssueFromJson(Map<String, dynamic> json) => Issue(
      issueID: json['issue_id'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      total: json['total'] as int,
      unread: json['unread'] as int,
      lastMessage: json['last_message'] == null
          ? null
          : Message.fromJson(json['last_message'] as Map<String, dynamic>),
      firstMessage: json['first_message'] == null
          ? null
          : Message.fromJson(json['first_message'] as Map<String, dynamic>),
      rating: json['rating'] as int,
      announcementContentId: json['announcement_content_id'] as String?,
    );

Map<String, dynamic> _$IssueToJson(Issue instance) => <String, dynamic>{
      'issue_id': instance.issueID,
      'status': instance.status,
      'title': instance.title,
      'tags': instance.tags,
      'timestamp': instance.timestamp.toIso8601String(),
      'total': instance.total,
      'unread': instance.unread,
      'rating': instance.rating,
      'last_message': instance.lastMessage,
      'first_message': instance.firstMessage,
      'announcement_content_id': instance.announcementContentId,
    };

SendAttachment _$SendAttachmentFromJson(Map<String, dynamic> json) =>
    SendAttachment(
      data: json['data'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$SendAttachmentToJson(SendAttachment instance) =>
    <String, dynamic>{
      'data': instance.data,
      'title': instance.title,
    };

ReceiveAttachment _$ReceiveAttachmentFromJson(Map<String, dynamic> json) =>
    ReceiveAttachment(
      title: json['title'] as String,
      name: json['name'] as String,
      contentType: json['content_type'] as String,
    );

Map<String, dynamic> _$ReceiveAttachmentToJson(ReceiveAttachment instance) =>
    <String, dynamic>{
      'title': instance.title,
      'name': instance.name,
      'content_type': instance.contentType,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as int,
      read: json['read'] as bool,
      from: json['from'] as String,
      message: json['message'] as String,
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => ReceiveAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'read': instance.read,
      'from': instance.from,
      'message': instance.message,
      'attachments': instance.attachments,
      'timestamp': instance.timestamp.toIso8601String(),
    };

IssueDetails _$IssueDetailsFromJson(Map<String, dynamic> json) => IssueDetails(
      issue: Issue.fromJson(json['issue'] as Map<String, dynamic>),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$IssueDetailsToJson(IssueDetails instance) =>
    <String, dynamic>{
      'issue': instance.issue,
      'messages': instance.messages,
    };

PostedMessageResponse _$PostedMessageResponseFromJson(
        Map<String, dynamic> json) =>
    PostedMessageResponse(
      issueID: json['issue_id'] as String,
      message: Message.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PostedMessageResponseToJson(
        PostedMessageResponse instance) =>
    <String, dynamic>{
      'issue_id': instance.issueID,
      'message': instance.message,
    };
