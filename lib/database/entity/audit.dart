//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:floor/floor.dart';
import 'package:json_annotation/json_annotation.dart';

part 'audit.g.dart';

@JsonSerializable()
@entity
class Audit {
  @primaryKey
  String uuid;
  String category;
  String action;
  DateTime createdAt;
  String metadata;

  Audit({
    required this.uuid,
    required this.category,
    required this.action,
    required this.createdAt,
    required this.metadata,
  });

  factory Audit.fromJson(Map<String, dynamic> json) => _$AuditFromJson(json);

  Map<String, dynamic> toJson() => _$AuditToJson(this);
}
