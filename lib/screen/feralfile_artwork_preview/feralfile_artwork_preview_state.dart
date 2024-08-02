import 'package:autonomy_flutter/model/ff_artwork.dart';

class FFArtworkPreviewEvent {}

class FFArtworkPreviewConfigByArtwork extends FFArtworkPreviewEvent {
  final Artwork artwork;

  FFArtworkPreviewConfigByArtwork(this.artwork);
}

/// -----------------------------------

class FFArtworkPreviewState {
  final Map<String, String> mediumMap;

  FFArtworkPreviewState({this.mediumMap = const {}});

  FFArtworkPreviewState copyWith({
    Map<String, String>? mediumMap,
  }) =>
      FFArtworkPreviewState(
        mediumMap: mediumMap ?? this.mediumMap,
      );
}
