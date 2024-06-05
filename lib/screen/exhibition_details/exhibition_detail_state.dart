import 'package:autonomy_flutter/model/ff_exhibition.dart';

class ExhibitionDetailEvent {}

class GetExhibitionDetailEvent extends ExhibitionDetailEvent {
  GetExhibitionDetailEvent(this.exhibitionId);

  final String exhibitionId;
}

class LoadMoreArtworkEvent extends ExhibitionDetailEvent {
  final int offset;
  final int limit;

  LoadMoreArtworkEvent(this.offset, this.limit);
}

class ExhibitionDetailState {
  ExhibitionDetailState({this.exhibitionDetail});

  final ExhibitionDetail? exhibitionDetail;

  ExhibitionDetailState copyWith({ExhibitionDetail? exhibitionDetail}) =>
      ExhibitionDetailState(
        exhibitionDetail: exhibitionDetail ?? this.exhibitionDetail,
      );
}
