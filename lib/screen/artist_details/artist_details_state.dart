import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/ff_user.dart';

class UserDetailsState {
  final FFUser? artist;
  final List<FFSeries>? series;
  final List<Exhibition>? exhibitions;
  final List<Post>? posts;

  UserDetailsState({
    this.artist,
    this.series,
    this.exhibitions,
    this.posts,
  });

  UserDetailsState copyWith({
    FFUser? artist,
    List<FFSeries>? series,
    List<Exhibition>? exhibitions,
    List<Post>? posts,
  }) =>
      UserDetailsState(
        artist: artist ?? this.artist,
        series: series ?? this.series,
        exhibitions: exhibitions ?? this.exhibitions,
        posts: posts ?? this.posts,
      );
}
