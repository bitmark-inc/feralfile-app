import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/transformers.dart';

class ExhibitionBloc extends AuBloc<ExhibitionsEvent, ExhibitionsState> {
  final FeralFileService _feralFileService;

  static const limit = 10;

  EventTransformer<Event> debounceSequential<Event>(Duration duration) =>
      (events, mapper) => events.debounceTime(duration).asyncExpand(mapper);

  ExhibitionBloc(this._feralFileService) : super(ExhibitionsState()) {
    on<GetAllExhibitionsEvent>((event, emit) async {
      final result = await Future.wait([
        injector.get<IAPService>().isSubscribed(),
        _feralFileService.getFeaturedExhibition(),
        _feralFileService.getAllExhibitions(limit: limit),
        _feralFileService.getSourceExhibition(),
      ]);
      final isSubscribed = result[0] as bool;
      final featuredExhibition = result[1] as ExhibitionDetail;
      var proExhibitions = result[2] as List<ExhibitionDetail>;
      final sourceExhibition = result[3] as Exhibition;
      log.info('[ExhibitionBloc] getAllExhibitionsEvent:'
          ' pro ${proExhibitions.length}');
      proExhibitions.removeWhere((element) =>
          element.exhibition.id == featuredExhibition.exhibition.id);
      proExhibitions =
          _addSourceExhibitionIfNeeded(proExhibitions, sourceExhibition);
      emit(state.copyWith(
        freeExhibitions: [featuredExhibition],
        proExhibitions: proExhibitions,
        isSubscribed: isSubscribed,
        currentPage: 1,
      ));
      add(GetNextPageEvent(isLoop: true));
    });

    on<GetNextPageEvent>(
      (event, emit) async {
        log.info('[ExhibitionBloc] getNextPageEvent:'
            'offset  ${state.currentPage * limit}');
        final proExhibitions = await _feralFileService.getAllExhibitions(
          limit: limit,
          offset: state.currentPage * limit,
        );
        final resultLength = proExhibitions.length;
        log.info('[ExhibitionBloc] getNextPageEvent: $resultLength');

        proExhibitions.removeWhere((element) =>
            state.allExhibitionIds.contains(element.exhibition.id));
        emit(state.copyWith(
          proExhibitions: [...state.proExhibitions ?? [], ...proExhibitions],
          currentPage: state.currentPage + 1,
        ));
        if (event.isLoop && resultLength == limit) {
          add(GetNextPageEvent(isLoop: true));
        }
      },
      transformer: debounceSequential(const Duration(seconds: 5)),
    );
  }

  List<ExhibitionDetail> _addSourceExhibitionIfNeeded(
      List<ExhibitionDetail> exhibitions, Exhibition sourceExhibition) {
    final isExistSourceExhibition = exhibitions
        .any((exhibition) => exhibition.exhibition.id == SOURCE_EXHIBITION_ID);
    if (isExistSourceExhibition) {
      return exhibitions;
    }
    final lastExhibition = exhibitions.last;
    if (lastExhibition.exhibition.exhibitionViewAt
        .isBefore(sourceExhibition.exhibitionViewAt)) {
      exhibitions
        ..add(ExhibitionDetail(exhibition: sourceExhibition))
        ..sort((a, b) => b.exhibition.exhibitionViewAt
            .compareTo(a.exhibition.exhibitionViewAt));
    }
    return exhibitions;
  }
}
