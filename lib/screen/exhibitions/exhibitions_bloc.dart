import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/log.dart';

class ExhibitionBloc extends AuBloc<ExhibitionsEvent, ExhibitionsState> {
  final FeralFileService _feralFileService;

  static const limit = 25;
  Exhibition? _sourceExhibition;

  ExhibitionBloc(this._feralFileService) : super(ExhibitionsState()) {
    on<GetAllExhibitionsEvent>((event, emit) async {
      if (state.allExhibitionIds.isNotEmpty) {
        return;
      }
      final result = await Future.wait([
        _feralFileService.getUpcomingExhibition(),
        _feralFileService.getFeaturedExhibition(),
        _feralFileService.getAllExhibitions(limit: limit),
        _feralFileService.getSourceExhibition(),
      ]);
      final upcomingExhibition = result[0] as Exhibition?;
      final featuredExhibition = result[1]! as Exhibition;
      final allExhibitions = result[2]! as List<Exhibition>;
      final sourceExhibition = result[3]! as Exhibition;
      log.info('[ExhibitionBloc] getAllExhibitionsEvent:'
          ' pro ${allExhibitions.length}');
      var pastExhibitions = allExhibitions
          .where((exhibition) =>
              exhibition.id != featuredExhibition.id &&
              exhibition.id != upcomingExhibition?.id)
          .toList();
      pastExhibitions =
          _addSourceExhibitionIfNeeded(pastExhibitions, sourceExhibition);
      _sourceExhibition = sourceExhibition;
      emit(state.copyWith(
        currentPage: 1,
        upcomingExhibition: upcomingExhibition,
        featuredExhibition: featuredExhibition,
        pastExhibitions: pastExhibitions,
      ));
      add(GetNextPageEvent(isLoop: true));
    });

    on<GetNextPageEvent>(
      (event, emit) async {
        log.info('[ExhibitionBloc] getNextPageEvent:'
            'offset  ${state.currentPage * limit}');
        List<Exhibition> exhibitions =
            await _feralFileService.getAllExhibitions(
          limit: limit,
          offset: state.currentPage * limit,
        );
        final resultLength = exhibitions.length;
        log.info('[ExhibitionBloc] getNextPageEvent: $resultLength');

        exhibitions.removeWhere(
            (element) => state.allExhibitionIds.contains(element.id));
        if (_sourceExhibition != null &&
            (state.pastExhibitions ?? []).isNotEmpty &&
            !state.allExhibitionIds.contains(_sourceExhibition!.id)) {
          exhibitions =
              _addSourceExhibitionIfNeeded(exhibitions, _sourceExhibition!);
        }
        emit(state.copyWith(
          pastExhibitions: [...?state.pastExhibitions, ...exhibitions],
          currentPage: state.currentPage + 1,
        ));
        if (event.isLoop && resultLength == limit) {
          add(GetNextPageEvent(isLoop: true));
        }
      },
    );
  }

  List<Exhibition> _addSourceExhibitionIfNeeded(
      List<Exhibition> exhibitions, Exhibition sourceExhibition) {
    final isExistSourceExhibition =
        exhibitions.any((exhibition) => exhibition.id == sourceExhibition.id);
    if (isExistSourceExhibition) {
      return exhibitions;
    }
    final lastExhibition = exhibitions.last;
    if (lastExhibition.exhibitionViewAt
        .isBefore(sourceExhibition.exhibitionViewAt)) {
      log.info('[ExhibitionBloc] inserted Source Exhibition');
      exhibitions
        ..add(sourceExhibition)
        ..sort((a, b) => b.exhibitionViewAt.compareTo(a.exhibitionViewAt));
    }
    return exhibitions;
  }
}
