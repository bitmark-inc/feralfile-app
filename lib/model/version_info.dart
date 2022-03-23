import 'dart:ffi';

import 'package:json_annotation/json_annotation.dart';

part 'version_info.g.dart';

@JsonSerializable()
class VersionsInfo {
  VersionInfo productionIOS;
  VersionInfo productionAndroid;
  VersionInfo testIOS;
  VersionInfo testAndroid;

  VersionsInfo({
    required this.productionIOS,
    required this.productionAndroid,
    required this.testIOS,
    required this.testAndroid,
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
