import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

abstract class FeralFileHomeEvent {}

class FeralFileHomeFetchDataEvent extends FeralFileHomeEvent {}

class FeralfileHomeBloc
    extends AuBloc<FeralFileHomeEvent, FeralfileHomeBlocState> {
  final FeralFileService _feralFileService;

  FeralfileHomeBloc(this._feralFileService) : super(FeralfileHomeBlocState()) {
    on<FeralFileHomeFetchDataEvent>((event, emit) async {
      final statistics = await _feralFileService.getExploreStatistics();
      final featuredWorks = await _feralFileService.getFeaturedArtworks();
      final allArtworks =
          null; //await _feralFileService.exploreArtworks(limit: 100);
      final exhibitions = null; //await _feralFileService.getAllExhibitions();
      final artists =
          null; //await _feralFileService.exploreArtists(limit: 200);
      final curators = null; //await _feralFileService.exploreCurators();

      emit(FeralfileHomeBlocState(
        exploreStatisticsData: statistics,
        featuredArtworks: featuredWorks,
      ));
    });
  }
}
