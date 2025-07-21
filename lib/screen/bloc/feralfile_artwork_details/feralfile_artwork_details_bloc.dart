import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class FeralfileArtworkDetailsEvent {}

class FeralfileArtworkDetailsLoadEvent extends FeralfileArtworkDetailsEvent {
  final String artworkId;

  FeralfileArtworkDetailsLoadEvent(this.artworkId);
}

class FeralfileArtworkDetailsState {
  final Artwork? artwork;

  FeralfileArtworkDetailsState({this.artwork});
}

class FeralfileArtworkDetailsLoadedState extends FeralfileArtworkDetailsState {
  FeralfileArtworkDetailsLoadedState(Artwork artwork) : super(artwork: artwork);
}

class FeralfileArtworkDetailsLoadingState extends FeralfileArtworkDetailsState {
  FeralfileArtworkDetailsLoadingState() : super(artwork: null);
}

class FeralfileArtworkDetailsErrorState extends FeralfileArtworkDetailsState {
  final String error;

  FeralfileArtworkDetailsErrorState(this.error) : super(artwork: null);
}

// bloc
class FeralfileArtworkDetailsBloc
    extends AuBloc<FeralfileArtworkDetailsEvent, FeralfileArtworkDetailsState> {
  final FeralFileService _feralFileService;

  FeralfileArtworkDetailsBloc(this._feralFileService)
      : super(FeralfileArtworkDetailsLoadingState()) {
    on<FeralfileArtworkDetailsLoadEvent>((event, emit) async {
      emit(FeralfileArtworkDetailsLoadingState());
      try {
        final artwork = await _feralFileService.getArtwork(event.artworkId);
        final seriesId = artwork.seriesID;
        final series = await _feralFileService.getSeries(seriesId);
        final exhibitionId = series.exhibitionID;
        final exhibition = await _feralFileService.getExhibition(exhibitionId);
        emit(FeralfileArtworkDetailsLoadedState(artwork.copyWith(
          series: series.copyWith(exhibition: exhibition),
        )));
      } catch (e) {
        emit(FeralfileArtworkDetailsErrorState(e.toString()));
      }
    });
  }
}
