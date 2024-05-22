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
    this.isSubscribed = false,
    this.currentPage = 0,
  });

  final List<ExhibitionDetail>? freeExhibitions;
  final List<ExhibitionDetail>? proExhibitions;
  final bool isSubscribed;
  final int currentPage;

  ExhibitionsState copyWith({
    List<ExhibitionDetail>? freeExhibitions,
    final List<ExhibitionDetail>? proExhibitions,
    bool? isSubscribed,
    int? currentPage,
  }) =>
      ExhibitionsState(
        freeExhibitions: freeExhibitions ?? this.freeExhibitions,
        proExhibitions: proExhibitions ?? this.proExhibitions,
        isSubscribed: isSubscribed ?? this.isSubscribed,
        currentPage: currentPage ?? this.currentPage,
      );

  List<String> get allExhibitionIds => [
      ...freeExhibitions?.map((e) => e.exhibition.id) ?? [],
      ...proExhibitions?.map((e) => e.exhibition.id) ?? [],
    ];
}
