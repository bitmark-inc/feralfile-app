//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:autonomy_flutter/model/announcement.dart';
import 'package:floor/floor.dart';

@entity
class AnnouncementLocal {
  @primaryKey
  final String announcementContextId;
  final String title;
  final String body;
  final int createdAt;
  final int announceAt;
  final String type;
  final bool unread;

  AnnouncementLocal(
      {required this.announcementContextId,
      required this.title,
      required this.body,
      required this.createdAt,
      required this.announceAt,
      required this.type,
      required this.unread});

  factory AnnouncementLocal.fromAnnouncement(Announcement announcement) =>
      AnnouncementLocal(
          announcementContextId: announcement.announcementContextId,
          title: announcement.title,
          body: announcement.body,
          createdAt: announcement.createdAt,
          announceAt: announcement.announceAt,
          type: announcement.type,
          unread: true);
}
