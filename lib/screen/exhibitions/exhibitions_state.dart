import 'package:autonomy_flutter/model/ff_exhibition.dart';

class ExhibitionsEvent {}

class GetAllExhibitionsEvent extends ExhibitionsEvent {}

class GetOpeningExhibitionsEvent extends ExhibitionsEvent {}

class ExhibitionsState {
  ExhibitionsState({
    this.freeExhibitions,
    this.proExhibitions,
    this.isSubscribed = false,
  });

  final List<ExhibitionDetail>? freeExhibitions;
  final List<ExhibitionDetail>? proExhibitions;
  final bool isSubscribed;

  ExhibitionsState copyWith({
    List<ExhibitionDetail>? freeExhibitions,
    final List<ExhibitionDetail>? proExhibitions,
    bool? isSubscribed,
  }) =>
      ExhibitionsState(
        freeExhibitions: freeExhibitions ?? this.freeExhibitions,
        proExhibitions: proExhibitions ?? this.proExhibitions,
        isSubscribed: isSubscribed ?? this.isSubscribed,
      );
}
