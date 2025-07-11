import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';

class DP1PlaylistResponse {
  DP1PlaylistResponse(
    this.items,
    this.hasMore,
    this.cursor,
  );

  factory DP1PlaylistResponse.fromJson(Map<String, dynamic> json) =>
      DP1PlaylistResponse(
        (json['items'] as List<dynamic>)
            .map((e) => DP1Call.fromJson(e as Map<String, dynamic>))
            .toList(),
        json['hasMore'] as bool,
        json['cursor'] as String?,
      );
  final List<DP1Call> items;
  final bool hasMore;
  final String? cursor;

  Map<String, dynamic> toJson() => {
        'items': items,
        'hasMore': hasMore,
        'cursor': cursor,
      };
}

class DP1ChannelsResponse {
  DP1ChannelsResponse(
    this.items,
    this.hasMore,
    this.cursor,
  );

  factory DP1ChannelsResponse.fromJson(Map<String, dynamic> json) =>
      DP1ChannelsResponse(
        (json['items'] as List<dynamic>)
            .map((e) => Channel.fromJson(e as Map<String, dynamic>))
            .toList(),
        json['hasMore'] as bool,
        json['cursor'] as String?,
      );

  final List<Channel> items;
  final bool hasMore;
  final String? cursor;
}

class DP1PlaylistItemsResponse {
  DP1PlaylistItemsResponse(this.items, this.hasMore, this.cursor);

  factory DP1PlaylistItemsResponse.fromJson(Map<String, dynamic> json) =>
      DP1PlaylistItemsResponse(
        (json['items'] as List<dynamic>)
            .map((e) => DP1Item.fromJson(e as Map<String, dynamic>))
            .toList(),
        json['hasMore'] as bool,
        json['cursor'] as String?,
      );

  final List<DP1Item> items;
  final bool hasMore;
  final String? cursor;
}
