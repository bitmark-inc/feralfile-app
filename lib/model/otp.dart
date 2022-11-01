import 'package:json_annotation/json_annotation.dart';

part 'otp.g.dart';

@JsonSerializable()
class Otp {
  final String code;
  final DateTime? expireAt;

  Otp(this.code, this.expireAt);

  factory Otp.fromJson(Map<String, dynamic> json) => _$OtpFromJson(json);

  Map<String, dynamic> toJson() => _$OtpToJson(this);

  bool get isExpired => expireAt?.isBefore(DateTime.now()) == true;
}
