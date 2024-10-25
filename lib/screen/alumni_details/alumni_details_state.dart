import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';

class AlumniDetailsState {
  final AlumniAccount? alumni;
  final List<FFSeries>? series;
  final List<Exhibition>? exhibitions;
  final List<Post>? posts;

  AlumniDetailsState({
    this.alumni,
    this.series,
    this.exhibitions,
    this.posts,
  });

  AlumniDetailsState copyWith({
    AlumniAccount? alumni,
    List<FFSeries>? series,
    List<Exhibition>? exhibitions,
    List<Post>? posts,
  }) =>
      AlumniDetailsState(
        alumni: alumni ?? this.alumni,
        series: series ?? this.series,
        exhibitions: exhibitions ?? this.exhibitions,
        posts: posts ?? this.posts,
      );
}
