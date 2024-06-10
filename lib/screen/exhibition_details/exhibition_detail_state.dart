import 'package:autonomy_flutter/model/ff_exhibition.dart';

class ExhibitionDetailEvent {}

class GetExhibitionDetailEvent extends ExhibitionDetailEvent {
  GetExhibitionDetailEvent(this.exhibitionId);

  final String exhibitionId;
}

class ExhibitionDetailState {
  ExhibitionDetailState({this.exhibition});

  final Exhibition? exhibition;

  ExhibitionDetailState copyWith({Exhibition? exhibition}) =>
      ExhibitionDetailState(exhibition: exhibition ?? this.exhibition);
}
