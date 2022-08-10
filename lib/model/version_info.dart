//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'version_info.g.dart';

@JsonSerializable()
class VersionsInfo {
  VersionInfo productionIOS;
  VersionInfo productionAndroid;
  VersionInfo devIOS;
  VersionInfo devAndroid;

  VersionsInfo({
    required this.productionIOS,
    required this.productionAndroid,
    required this.devIOS,
    required this.devAndroid,
  });

  factory VersionsInfo.fromJson(Map<String, dynamic> json) =>
      _$VersionsInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VersionsInfoToJson(this);
}

@JsonSerializable()
class VersionInfo {
  String requiredVersion;
  String link;

  VersionInfo({
    required this.requiredVersion,
    required this.link,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) =>
      _$VersionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VersionInfoToJson(this);
}
