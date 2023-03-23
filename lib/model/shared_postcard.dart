//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:json_annotation/json_annotation.dart';

part 'shared_postcard.g.dart';

@JsonSerializable()
class SharedPostcard {
  final String tokenID;
  final String owner;

  SharedPostcard(this.tokenID, this.owner);

  factory SharedPostcard.fromJson(Map<String, dynamic> json) =>
      _$SharedPostcardFromJson(json);

  Map<String, dynamic> toJson() => _$SharedPostcardToJson(this);
}
