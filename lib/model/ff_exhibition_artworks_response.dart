import 'package:autonomy_flutter/model/ff_account.dart';

class ExhibitionArtworksResponse {
  final List<Artwork> result;

  ExhibitionArtworksResponse({
    required this.result,
  });

  factory ExhibitionArtworksResponse.fromJson(Map<String, dynamic> json) =>
      ExhibitionArtworksResponse(
        result: (json['result'] as List<dynamic>)
            .map((e) => Artwork.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'result': result.map((e) => e.toJson()).toList(),
      };
}
