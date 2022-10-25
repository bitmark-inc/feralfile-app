//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:json_annotation/json_annotation.dart';

part 'sent_artwork.g.dart';

@JsonSerializable()
class SentArtwork {
  final String tokenID;
  final String address;
  final DateTime timestamp;

  SentArtwork(this.tokenID, this.address, this.timestamp);

  factory SentArtwork.fromJson(Map<String, dynamic> json) =>
      _$SentArtworkFromJson(json);

  Map<String, dynamic> toJson() => _$SentArtworkToJson(this);

  bool isHidden(
      {required String tokenID,
      required String address,
      required DateTime timestamp}) {
    if (this.tokenID == tokenID &&
        this.address == address &&
        this.timestamp.isAfter(timestamp)) {
      return true;
    }
    return false;
  }
}
