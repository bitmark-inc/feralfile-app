import 'package:autonomy_flutter/model/ff_artwork.dart';

class FFArtworkPreviewEvent {}

class FFArtworkPreviewConfigByArtwork extends FFArtworkPreviewEvent {
  final Artwork artwork;

  FFArtworkPreviewConfigByArtwork(this.artwork);
}

/// -----------------------------------

class FFArtworkPreviewState {
  final String? medium;

  FFArtworkPreviewState({this.medium});

  FFArtworkPreviewState copyWith({
    String? medium,
  }) =>
      FFArtworkPreviewState(
        medium: medium ?? this.medium,
      );
}
