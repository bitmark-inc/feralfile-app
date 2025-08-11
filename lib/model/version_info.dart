//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class VersionsInfo {
  VersionInfo productionIOS;
  VersionInfo productionAndroid;

  VersionsInfo({
    required this.productionIOS,
    required this.productionAndroid,
  });

  factory VersionsInfo.fromJson(Map<String, dynamic> json) => VersionsInfo(
        productionIOS:
            VersionInfo.fromJson(json['productionIOS'] as Map<String, dynamic>),
        productionAndroid: VersionInfo.fromJson(
            json['productionAndroid'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'productionIOS': productionIOS.toJson(),
        'productionAndroid': productionAndroid.toJson(),
      };
}

@JsonSerializable()
class VersionInfo {
  String requiredVersion;
  String link;

  VersionInfo({
    required this.requiredVersion,
    required this.link,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      requiredVersion: json['requiredVersion'] as String,
      link: json['link'] as String,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'requiredVersion': requiredVersion,
        'link': link,
      };
}
