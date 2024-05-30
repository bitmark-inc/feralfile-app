import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/log.dart';

class ExhibitionBloc extends AuBloc<ExhibitionsEvent, ExhibitionsState> {
  final FeralFileService _feralFileService;

  static const limit = 25;

  ExhibitionBloc(this._feralFileService) : super(ExhibitionsState()) {
    on<GetAllExhibitionsEvent>((event, emit) async {
      if (state.allExhibitionIds.isNotEmpty) {
        return;
      }
      final result = await Future.wait([
        injector.get<IAPService>().isSubscribed(),
        _feralFileService.getFeaturedExhibition(),
        _feralFileService.getAllExhibitions(limit: limit),
        _feralFileService.getSourceExhibition(withSeries: false),
      ]);
      final isSubscribed = result[0] as bool;
      final featuredExhibition = result[1] as Exhibition;
      var proExhibitions = result[2] as List<Exhibition>;
      final sourceExhibition = result[3] as Exhibition;
      log.info('[ExhibitionBloc] getAllExhibitionsEvent:'
          ' pro ${proExhibitions.length}');
      proExhibitions
          .removeWhere((element) => element.id == featuredExhibition.id);
      proExhibitions =
          _addSourceExhibitionIfNeeded(proExhibitions, sourceExhibition);
      emit(state.copyWith(
        freeExhibitions: [featuredExhibition],
        proExhibitions: proExhibitions,
        isSubscribed: isSubscribed,
        currentPage: 1,
        sourceExhibition: sourceExhibition,
      ));
      add(GetNextPageEvent(isLoop: true));
    });

    on<GetNextPageEvent>(
      (event, emit) async {
        log.info('[ExhibitionBloc] getNextPageEvent:'
            'offset  ${state.currentPage * limit}');
        List<Exhibition> proExhibitions =
            await _feralFileService.getAllExhibitions(
          limit: limit,
          offset: state.currentPage * limit,
        );
        final resultLength = proExhibitions.length;
        log.info('[ExhibitionBloc] getNextPageEvent: $resultLength');

        proExhibitions.removeWhere(
            (element) => state.allExhibitionIds.contains(element.id));
        if (state.sourceExhibition != null &&
            !(state.proExhibitions ?? [])
                .any((element) => element.id == SOURCE_EXHIBITION_ID)) {
          proExhibitions = _addSourceExhibitionIfNeeded(
              proExhibitions, state.sourceExhibition!);
        }
        emit(state.copyWith(
          proExhibitions: [...state.proExhibitions ?? [], ...proExhibitions],
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
