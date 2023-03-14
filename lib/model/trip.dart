import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Trip {
  final String from;
  final String to;
  final int? distance;

  static Trip sendingTrip(String from) {
    return Trip(from: from, to: "Unknow", distance: null);
  }

  Trip({required this.from, required this.to, required this.distance});

  // factory Otp.fromJson(Map<String, dynamic> json) => _$OtpFromJson(json);

  // Map<String, dynamic> toJson() => _$OtpToJson(this);
}
