import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/ff_user.dart';

class FeralfileHomeBlocState {
  List<Artwork>? featuredArtworks;
  final FeralFileListResponse<FFSeries>? artworks;
  final List<Exhibition>? exhibitions;
  final FeralFileListResponse<FFArtist>? artists;
  final FeralFileListResponse<FFCurator>? curators;

  FeralfileHomeBlocState({
    this.featuredArtworks,
    this.artworks,
    this.exhibitions,
    this.artists,
    this.curators,
  });

  FeralfileHomeBlocState copyWith({
    List<Artwork>? featuredArtworks,
    FeralFileListResponse<FFSeries>? artworks,
    List<Exhibition>? exhibitions,
    FeralFileListResponse<FFArtist>? artists,
    FeralFileListResponse<FFCurator>? curators,
  }) {
    return FeralfileHomeBlocState(
      featuredArtworks: featuredArtworks ?? this.featuredArtworks,
      artworks: artworks ?? this.artworks,
      exhibitions: exhibitions ?? this.exhibitions,
      artists: artists ?? this.artists,
      curators: curators ?? this.curators,
    );
  }
}
