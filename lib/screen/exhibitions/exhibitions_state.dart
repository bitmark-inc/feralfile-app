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
    this.currentPage = 0,
    this.sourceExhibition,
    this.upcomingExhibition,
    this.featuredExhibition,
    this.pastExhibitions,
  });

  final int currentPage;
  final Exhibition? sourceExhibition;
  final Exhibition? upcomingExhibition;
  final Exhibition? featuredExhibition;
  final List<Exhibition>? pastExhibitions;

  ExhibitionsState copyWith({
    Exhibition? sourceExhibition,
    final Exhibition? upcomingExhibition,
    final Exhibition? featuredExhibition,
    final List<Exhibition>? pastExhibitions,
    bool? isSubscribed,
    int? currentPage,
  }) =>
      ExhibitionsState(
        currentPage: currentPage ?? this.currentPage,
        sourceExhibition: sourceExhibition ?? this.sourceExhibition,
        upcomingExhibition: upcomingExhibition ?? this.upcomingExhibition,
        featuredExhibition: featuredExhibition ?? this.featuredExhibition,
        pastExhibitions: pastExhibitions ?? this.pastExhibitions,
      );

  List<String> get allExhibitionIds => [
        if (featuredExhibition != null) featuredExhibition!.id,
        if (upcomingExhibition != null) upcomingExhibition!.id,
        ...pastExhibitions?.map((e) => e.id) ?? [],
      ];
}
