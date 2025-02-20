// ignore_for_file: public_member_api_docs, sort_constructors_first
//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:floor_annotation/floor_annotation.dart';

@Entity(primaryKeys: ['indexID'])
class Asset {
  String? indexID;
  String? thumbnailID;
  DateTime? lastRefreshedTime;
  String? artistID;
  String? artistName;
  String? artistURL;
  String? artists;
  String? assetID;
  String? title;
  String? description;
  String? mimeType;
  String? medium;
  int? maxEdition;
  String? source;
  String? sourceURL;
  String? previewURL;
  String? thumbnailURL;
  String? galleryThumbnailURL;
  String? assetData;
  String? assetURL;
  bool? isFeralfileFrame;
  String? initialSaleModel;
  String? originalFileURL;
  String? artworkMetadata;

  Asset(
    this.indexID,
    this.thumbnailID,
    this.lastRefreshedTime,
    this.artistID,
    this.artistName,
    this.artistURL,
    this.artists,
    this.assetID,
    this.title,
    this.description,
    this.mimeType,
    this.medium,
    this.maxEdition,
    this.source,
    this.sourceURL,
    this.previewURL,
    this.thumbnailURL,
    this.galleryThumbnailURL,
    this.assetData,
    this.assetURL,
    this.initialSaleModel,
    this.originalFileURL,
    this.isFeralfileFrame,
    this.artworkMetadata,
  );

  Asset.init({
    this.indexID,
    this.thumbnailID,
    this.lastRefreshedTime,
    this.artistID,
    this.artistName,
    this.artistURL,
    this.artists,
    this.assetID,
    this.title,
    this.description,
    this.mimeType,
    this.medium,
    this.maxEdition,
    this.source,
    this.sourceURL,
    this.previewURL,
    this.thumbnailURL,
    this.galleryThumbnailURL,
    this.assetData,
    this.assetURL,
    this.initialSaleModel,
    this.originalFileURL,
    this.isFeralfileFrame,
    this.artworkMetadata,
  });

  factory Asset.fromJson(Map<String, dynamic> map) {
    return Asset(
      map['indexID'] != null ? map['indexID'] as String : null,
      map['thumbnailID'] != null ? map['thumbnailID'] as String : null,
      map['lastRefreshedTime'] != null
          ? DateTime.tryParse(map['lastRefreshedTime'] as String)
          : null,
      map['metadata']['artistID'] != null ? map['artistID'] as String : null,
      map['artistName'] != null ? map['artistName'] as String : null,
      map['artistURL'] != null ? map['artistURL'] as String : null,
      map['artists'] != null ? map['artists'] as String : null,
      map['assetID'] != null ? map['assetID'] as String : null,
      map['title'] != null ? map['title'] as String : null,
      map['description'] != null ? map['description'] as String : null,
      map['mimeType'] != null ? map['mimeType'] as String : null,
      mediumFromMimeType(map['mimeType'] as String?),
      map['maxEdition'] != null ? map['maxEdition'] as int : null,
      map['source'] != null ? map['source'] as String : null,
      map['sourceURL'] != null ? map['sourceURL'] as String : null,
      map['previewURL'] != null ? map['previewURL'] as String : null,
      map['thumbnailURL'] != null ? map['thumbnailURL'] as String : null,
      map['galleryThumbnailURL'] != null
          ? map['galleryThumbnailURL'] as String
          : null,
      map['assetData'] != null ? map['assetData'] as String : null,
      map['assetURL'] != null ? map['assetURL'] as String : null,
      map['initialSaleModel'] != null
          ? map['initialSaleModel'] as String
          : null,
      map['originalFileURL'] != null ? map['originalFileURL'] as String : null,
      map['isFeralfileFrame'] != null ? map['isFeralfileFrame'] as bool : null,
      map['artworkMetadata'] != null ? map['artworkMetadata'] as String : null,
    );
  }
}

String mediumFromMimeType(String? mimeType) {
  switch (mimeType) {
    case 'image/avif':
    case 'image/bmp':
    case 'image/jpeg':
    case 'image/jpg':
    case 'image/png':
    case 'image/tiff':
      return 'image';

    case 'image/svg+xml':
      return 'svg';

    case 'image/gif':
      return 'gif';

    case 'audio/aac':
    case 'audio/midi':
    case 'audio/x-midi':
    case 'audio/mpeg':
    case 'audio/ogg':
    case 'audio/opus':
    case 'audio/wav':
    case 'audio/webm':
    case 'audio/3gpp':
    case 'audio/vnd.wave':
      return 'audio';

    case 'video/x-msvideo':
    case 'video/3gpp':
    case 'video/mp4':
    case 'video/mpeg':
    case 'video/ogg':
    case 'video/3gpp2':
    case 'video/quicktime':
    case 'application/x-mpegURL':
    case 'video/x-flv':
    case 'video/MP2T':
    case 'video/webm':
    case 'application/octet-stream':
      return 'video';

    case 'application/pdf':
      return 'pdf';

    case 'model/gltf-binary':
      return 'model';

    default:
      return 'software';
  }
}
