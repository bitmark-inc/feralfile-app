import 'package:autonomy_flutter/model/ff_artwork.dart';

class FFArtworkPreviewEvent {}

class FFArtworkPreviewConfigByArtwork extends FFArtworkPreviewEvent {
  final Artwork artwork;

  FFArtworkPreviewConfigByArtwork(this.artwork);
}

/// -----------------------------------

class FFArtworkPreviewState {
  final Map<String, String> mediumMap;
  final Map<String, String> overriddenHtml;

  FFArtworkPreviewState(
      {this.mediumMap = const {}, this.overriddenHtml = const {}});

  FFArtworkPreviewState copyWith({
    Map<String, String>? mediumMap,
    Map<String, String>? overriddenHtml,
  }) =>
      FFArtworkPreviewState(
        mediumMap: mediumMap ?? this.mediumMap,
        overriddenHtml: overriddenHtml ?? this.overriddenHtml,
      );
}
