import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/alumni_details/alumni_details_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class AlumniDetailsEvent {}

class AlumniDetailsFetchAlumniEvent extends AlumniDetailsEvent {
  final String alumniID;

  AlumniDetailsFetchAlumniEvent({required this.alumniID});
}

class AlumniDetailsBloc extends AuBloc<AlumniDetailsEvent, AlumniDetailsState> {
  final FeralFileService _feralFileService = injector<FeralFileService>();

  AlumniDetailsBloc() : super(AlumniDetailsState()) {
    on<AlumniDetailsFetchAlumniEvent>((event, emit) async {
      final alumni = await _feralFileService.getAlumniDetail(event.alumniID);
      final alumniID = alumni.id;
      final linkedAddresses = alumni.associatedAddresses ?? [];

      final artworks = await _feralFileService.exploreArtworks(
        artistIds: [alumniID, ...linkedAddresses],
      );
      final exhibitions = await _feralFileService.getAllExhibitions(
        relatedAlumniAccountIDs: [alumniID, ...linkedAddresses],
      );
      final post = await _feralFileService.getPosts(
        relatedAlumniAccountIDs: [alumniID, ...linkedAddresses],
      );
      emit(AlumniDetailsState(
        alumni: alumni,
        series: artworks.result,
        exhibitions: exhibitions,
        posts: post,
      ));
    });
  }
}
