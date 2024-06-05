import 'package:autonomy_flutter/model/ff_exhibition.dart';

class ExhibitionsEvent {}

class GetAllExhibitionsEvent extends ExhibitionsEvent {}

class GetNextPageEvent extends ExhibitionsEvent {
  final bool isLoop;

  GetNextPageEvent({this.isLoop = false});
}

class GetOpeningExhibitionsEvent extends ExhibitionsEvent {}

class ExhibitionsState {
  ExhibitionsState({
    this.freeExhibitions,
    this.proExhibitions,
    this.currentPage = 0,
    this.sourceExhibition,
  });

  final List<Exhibition>? freeExhibitions;
  final List<Exhibition>? proExhibitions;
  final Exhibition? sourceExhibition;
  final int currentPage;

  ExhibitionsState copyWith({
    List<Exhibition>? freeExhibitions,
    final List<Exhibition>? proExhibitions,
    bool? isSubscribed,
    int? currentPage,
    Exhibition? sourceExhibition,
  }) =>
      ExhibitionsState(
        freeExhibitions: freeExhibitions ?? this.freeExhibitions,
        proExhibitions: proExhibitions ?? this.proExhibitions,
        currentPage: currentPage ?? this.currentPage,
        sourceExhibition: sourceExhibition ?? this.sourceExhibition,
      );

  List<String> get allExhibitionIds => [
        ...freeExhibitions?.map((e) => e.id) ?? [],
        ...proExhibitions?.map((e) => e.id) ?? [],
      ];
}
