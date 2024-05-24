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
      proExhibitions = _addSourceExhibitionIfNeeded(
          proExhibitions, ExhibitionDetail(exhibition: sourceExhibition));
      emit(state.copyWith(
        freeExhibitions: [featuredExhibition],
        proExhibitions: proExhibitions,
        isSubscribed: isSubscribed,
        currentPage: 1,
        sourceExhibition: ExhibitionDetail(exhibition: sourceExhibition),
      ));
      add(GetNextPageEvent(isLoop: true));
    });

    on<GetNextPageEvent>(
      (event, emit) async {
        log.info('[ExhibitionBloc] getNextPageEvent:'
            'offset  ${state.currentPage * limit}');
        List<ExhibitionDetail> proExhibitions =
            await _feralFileService.getAllExhibitions(
          limit: limit,
          offset: state.currentPage * limit,
        );
        final resultLength = proExhibitions.length;
        log.info('[ExhibitionBloc] getNextPageEvent: $resultLength');

        proExhibitions.removeWhere((element) =>
            state.allExhibitionIds.contains(element.exhibition.id));
        if (state.sourceExhibition != null &&
            !(state.proExhibitions ?? []).any(
                (element) => element.exhibition.id == SOURCE_EXHIBITION_ID)) {
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

  List<ExhibitionDetail> _addSourceExhibitionIfNeeded(
      List<ExhibitionDetail> exhibitions, ExhibitionDetail sourceExhibition) {
    final isExistSourceExhibition = exhibitions.any((exhibition) =>
        exhibition.exhibition.id == sourceExhibition.exhibition.id);
    if (isExistSourceExhibition) {
      return exhibitions;
    }
    final lastExhibition = exhibitions.last;
    if (lastExhibition.exhibition.exhibitionViewAt
        .isBefore(sourceExhibition.exhibition.exhibitionViewAt)) {
      log.info('[ExhibitionBloc] inserted Source Exhibition');
      exhibitions
        ..add(sourceExhibition)
        ..sort((a, b) => b.exhibition.exhibitionViewAt
            .compareTo(a.exhibition.exhibitionViewAt));
    }
    return exhibitions;
  }
}
