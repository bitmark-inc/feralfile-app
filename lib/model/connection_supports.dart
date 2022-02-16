import 'package:json_annotation/json_annotation.dart';

import 'package:autonomy_flutter/model/ff_account.dart';

part 'connection_supports.g.dart';

@JsonSerializable()
class FeralFileConnection {
  String source;
  FFAccount ffAccount;

  FeralFileConnection({
    required this.source,
    required this.ffAccount,
  });

  factory FeralFileConnection.fromJson(Map<String, dynamic> json) =>
      _$FeralFileConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$FeralFileConnectionToJson(this);
}
