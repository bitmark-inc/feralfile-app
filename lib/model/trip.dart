import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Trip {
  final String from;
  final String to;
  final double? distance;

  static Trip sendingTrip(String from) =>
      Trip(from: from, to: 'unknow'.tr(), distance: null);

  Trip({required this.from, required this.to, required this.distance});
}
