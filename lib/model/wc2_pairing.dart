import 'package:autonomy_flutter/model/wc2_proposal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wc2_pairing.g.dart';

@JsonSerializable()
class Wc2Pairing {
  final String topic;
  final int expiry;
  final AppMetadata? peerAppMetaData;

  Wc2Pairing(
    this.topic,
    this.expiry,
    this.peerAppMetaData,
  );

  factory Wc2Pairing.fromJson(Map<String, dynamic> json) =>
      _$Wc2PairingFromJson(json);

  Map<String, dynamic> toJson() => _$Wc2PairingToJson(this);
}
