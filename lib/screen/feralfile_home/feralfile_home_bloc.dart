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
      final featuredWorks = await _feralFileService.getFeaturedArtworks();
      final allArtworks = await _feralFileService.exploreArtworks(limit: 100);
      final exhibitions = await _feralFileService.getAllExhibitions();
      final artists = await _feralFileService.exploreArtists(limit: 200);
      final curators = await _feralFileService.exploreCurators();

      emit(FeralfileHomeBlocState(
        featuredArtworks: featuredWorks,
        artworks: allArtworks,
        exhibitions: exhibitions,
        artists: artists,
        curators: curators,
      ));
    });
  }
}
