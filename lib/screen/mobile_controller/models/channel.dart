import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';

class Channel {
  Channel({
    required this.id,
    required this.slug,
    required this.title,
    this.curator,
    this.summary,
    required this.playlists,
    required this.created,
    this.coverImage,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      curator: json['curator'] as String?,
      summary: json['summary'] as String?,
      playlists:
          (json['playlists'] as List<dynamic>).map((e) => e as String).toList(),
      created: DateTime.parse(json['created'] as String),
      coverImage: json['coverImage'] as String?,
    );
  }

  final String id;
  final String slug;
  final String title;
  final String? curator;
  final String? summary;
  final List<String> playlists;
  final DateTime created;
  final String? coverImage;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'curator': curator,
      'summary': summary,
      'playlists': playlists,
      'created': created.toIso8601String(),
      'coverImage': coverImage,
    };
  }
}

extension ChannelExtension on Channel {
  Future<List<DP1Call>> getPlaylists() async {
    final dio = Dio();
    List<DP1Call> result = [];
    for (final url in playlists) {
      try {
        final response = await dio.get<Map<String, dynamic>>(url);
        if (response.statusCode == 200 && response.data != null) {
          result.add(DP1Call.fromJson(response.data as Map<String, dynamic>));
        }
      } catch (e) {
        log.info('Error when get playlists: $e');
      }
    }
    return result;
  }
}
