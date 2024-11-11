//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

enum NotificationDataType {
  galleryNewNft,
  newPostcardTrip,
  postcardShareExpired,
  customerSupportNewMessage,
  customerSupportCloseIssue,
  artworkCreated,
  artworkReceived,
  newMessage,
  jgCrystallineWorkHasArrived,
  jgCrystallineWorkGenerated,
  exhibitionViewingOpening,
  exhibitionSalesOpening,
  exhibitionSaleClosing,
  navigate,
  dailyArtworkReminders,
  general,
  ;

  // toString method
  @override
  String toString() {
    switch (this) {
      case NotificationDataType.galleryNewNft:
        return 'gallery_new_nft';
      case NotificationDataType.newPostcardTrip:
        return 'new_postcard_trip';
      case NotificationDataType.postcardShareExpired:
        return 'postcard_share_expired';
      case NotificationDataType.customerSupportNewMessage:
        return 'customer_support_new_message';
      case NotificationDataType.customerSupportCloseIssue:
        return 'customer_support_close_issue';
      case NotificationDataType.artworkCreated:
        return 'artwork_created';
      case NotificationDataType.artworkReceived:
        return 'artwork_received';
      case NotificationDataType.newMessage:
        return 'new_message';
      case NotificationDataType.jgCrystallineWorkHasArrived:
        return 'jg_artwork_solar_day_arrived';
      case NotificationDataType.jgCrystallineWorkGenerated:
        return 'jg_artwork_generated';
      case NotificationDataType.exhibitionViewingOpening:
        return 'exhibition_view_opening';
      case NotificationDataType.exhibitionSalesOpening:
        return 'exhibition_sale_opening';
      case NotificationDataType.exhibitionSaleClosing:
        return 'exhibition_sale_closing';
      case NotificationDataType.navigate:
        return 'navigate';
      case NotificationDataType.general:
        return 'general';
      case NotificationDataType.dailyArtworkReminders:
        return 'daily_artwork_reminders';
    }
  }

  // fromString method
  static NotificationDataType fromString(String value) {
    switch (value) {
      case 'gallery_new_nft':
        return NotificationDataType.galleryNewNft;
      case 'new_postcard_trip':
        return NotificationDataType.newPostcardTrip;
      case 'postcard_share_expired':
        return NotificationDataType.postcardShareExpired;
      case 'customer_support_new_message':
        return NotificationDataType.customerSupportNewMessage;
      case 'customer_support_close_issue':
        return NotificationDataType.customerSupportCloseIssue;
      case 'artwork_created':
        return NotificationDataType.artworkCreated;
      case 'artwork_received':
        return NotificationDataType.artworkReceived;
      case 'new_message':
        return NotificationDataType.newMessage;
      case 'jg_artwork_solar_day_arrived':
        return NotificationDataType.jgCrystallineWorkHasArrived;
      case 'jg_artwork_generated':
        return NotificationDataType.jgCrystallineWorkGenerated;
      case 'exhibition_view_opening':
        return NotificationDataType.exhibitionViewingOpening;
      case 'exhibition_sale_opening':
        return NotificationDataType.exhibitionSalesOpening;
      case 'exhibition_sale_closing':
        return NotificationDataType.exhibitionSaleClosing;
      case 'navigate':
        return NotificationDataType.navigate;
      case 'daily_artwork_reminders':
        return NotificationDataType.dailyArtworkReminders;
      default:
        return NotificationDataType.general;
    }
  }
}
