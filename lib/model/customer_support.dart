//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_support.g.dart';

abstract class ChatThread {
  String getListTitle();

  bool isUnread();

  DateTime get sortTime;
}

@JsonSerializable()
class Issue implements ChatThread {
  @JsonKey(name: 'issue_id')
  String issueID;
  String status;
  String title;
  List<String> tags;
  DateTime timestamp;
  int total;
  int unread;
  int rating;
  @JsonKey(name: 'last_message')
  Message? lastMessage;
  @JsonKey(name: 'first_message')
  Message? firstMessage;
  @JsonKey(name: 'announcement_content_id')
  String? announcementContentId;
  @JsonKey(name: 'user_id')
  String? userId;

  // only on local
  @JsonKey(includeFromJson: false, includeToJson: false)
  DraftCustomerSupport? draft;

  Issue({
    required this.issueID,
    required this.status,
    required this.title,
    required this.tags,
    required this.timestamp,
    required this.total,
    required this.unread,
    required this.lastMessage,
    required this.firstMessage,
    required this.rating,
    this.draft,
    this.announcementContentId,
    this.userId,
  });

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);

  Map<String, dynamic> toJson() => _$IssueToJson(this);

  String get reportIssueType =>
      ReportIssueType.getList
          .firstWhereOrNull((element) => tags.contains(element)) ??
      '';

  @override
  String getListTitle() => ReportIssueType.toTitle(reportIssueType);

  @override
  bool isUnread() => unread > 0;

  Issue copyWith({
    String? issueID,
    String? status,
    String? title,
    List<String>? tags,
    DateTime? timestamp,
    int? total,
    int? unread,
    int? rating,
    Message? lastMessage,
    Message? firstMessage,
    String? announcementContentId,
    DraftCustomerSupport? draft,
    String? userId,
  }) =>
      Issue(
        issueID: issueID ?? this.issueID,
        status: status ?? this.status,
        title: title ?? this.title,
        tags: tags ?? this.tags,
        timestamp: timestamp ?? this.timestamp,
        total: total ?? this.total,
        unread: unread ?? this.unread,
        rating: rating ?? this.rating,
        lastMessage: lastMessage ?? this.lastMessage,
        firstMessage: firstMessage ?? this.firstMessage,
        announcementContentId:
            announcementContentId ?? this.announcementContentId,
        draft: draft ?? this.draft,
        userId: userId ?? this.userId,
      );

  @override
  DateTime get sortTime => lastMessage?.timestamp ?? timestamp;
}

@JsonSerializable()
class SendAttachment {
  String data;
  String title;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String path;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String contentType;

  SendAttachment({
    required this.data,
    required this.title,
    this.path = '',
    this.contentType = '',
  });

  factory SendAttachment.fromJson(Map<String, dynamic> json) =>
      _$SendAttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$SendAttachmentToJson(this);
}

@JsonSerializable()
class ReceiveAttachment {
  String title;
  String name;
  @JsonKey(name: 'content_type')
  String contentType;

  ReceiveAttachment({
    required this.title,
    required this.name,
    required this.contentType,
  });

  factory ReceiveAttachment.fromJson(Map<String, dynamic> json) =>
      _$ReceiveAttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiveAttachmentToJson(this);

  // Because logs are big and aren't valuable for user.
  // I don't store  the local logs files
  // I join the size of file inside the attachment's title
  static List<dynamic> extractSizeAndRealTitle(String title) {
    final fileInfos = title.split('_');
    final maybeSize = fileInfos.removeAt(0);
    final size = int.tryParse(maybeSize);
    if (size == null) {
      fileInfos.insert(0, maybeSize);
    }

    return [
      size,
      fileInfos.join('_'),
    ];
  }
}

@JsonSerializable()
class Message {
  int id;
  bool read;
  String from;
  String message;
  List<ReceiveAttachment> attachments;
  DateTime timestamp;

  Message({
    required this.id,
    required this.read,
    required this.from,
    required this.message,
    required this.attachments,
    required this.timestamp,
  });

  String get filteredMessage {
    if (message.isEmpty || message == EMPTY_ISSUE_MESSAGE) {
      return '';
    }
    return message
        .replaceAll(RegExp(r'\[MUTED\](.|\n)*\[/MUTED\]'), '')
        .replaceAll(RegExp(r'^(\n)*'), '');
  }

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable()
class IssueDetails {
  Issue issue;
  List<Message> messages;

  IssueDetails({
    required this.issue,
    required this.messages,
  });

  factory IssueDetails.fromJson(Map<String, dynamic> json) =>
      _$IssueDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$IssueDetailsToJson(this);
}

@JsonSerializable()
class PostedMessageResponse {
  @JsonKey(name: 'issue_id')
  String issueID;
  Message message;

  PostedMessageResponse({
    required this.issueID,
    required this.message,
  });

  factory PostedMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$PostedMessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PostedMessageResponseToJson(this);
}
