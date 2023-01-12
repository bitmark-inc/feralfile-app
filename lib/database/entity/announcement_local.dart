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
  final String announcementID;
  final String title;
  final String body;
  final int announceAt;
  final String type;
  final bool unread;

  AnnouncementLocal(
      {required this.announcementID,
      required this.title,
      required this.body,
      required this.announceAt,
      required this.type,
      required this.unread});

  factory AnnouncementLocal.fromAnnouncement(Announcement announcement) =>
      AnnouncementLocal(
          announcementID: announcement.announcementId,
          title: announcement.title,
          body: announcement.body,
          announceAt: announcement.announceAt,
          type: announcement.type,
          unread: true);
}
