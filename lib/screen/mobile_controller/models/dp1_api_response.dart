import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';

class DP1PlaylistResponse {
  DP1PlaylistResponse(
    this.items,
    this.hasMore,
  );

  factory DP1PlaylistResponse.fromJson(Map<String, dynamic> json) =>
      DP1PlaylistResponse(
        (json['items'] as List<dynamic>)
            .map((e) => DP1Call.fromJson(e as Map<String, dynamic>))
            .toList(),
        json['hasMore'] as bool,
      );
  final List<DP1Call> items;
  final bool hasMore;

  Map<String, dynamic> toJson() => {
        'items': items,
        'hasMore': hasMore,
      };
}
