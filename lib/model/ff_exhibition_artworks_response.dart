import 'package:autonomy_flutter/model/ff_account.dart';

class ArtworksResponse {
  final List<Artwork> result;

  ArtworksResponse({
    required this.result,
  });

  factory ArtworksResponse.fromJson(Map<String, dynamic> json) =>
      ArtworksResponse(
        result: (json['result'] as List<dynamic>)
            .map((e) => Artwork.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'result': result.map((e) => e.toJson()).toList(),
      };
}
