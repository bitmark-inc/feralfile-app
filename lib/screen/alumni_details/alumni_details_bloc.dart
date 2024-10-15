import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/alumni_details/alumni_details_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class AlumniDetailsEvent {}

class AlumniDetailsFetchAlumniEvent extends AlumniDetailsEvent {
  final String alumniId;

  AlumniDetailsFetchAlumniEvent({required this.alumniId});
}

class AlumniDetailsBloc extends AuBloc<AlumniDetailsEvent, AlumniDetailsState> {
  final FeralFileService _feralFileService = injector<FeralFileService>();

  AlumniDetailsBloc() : super(AlumniDetailsState()) {
    on<AlumniDetailsFetchAlumniEvent>((event, emit) async {
      final alumni = await _feralFileService.getAlumni(event.alumniId);
      final alumniId = alumni.id;
      final linkedAccountIds = alumni.associatedAddresses ?? [];

      final artworks = await _feralFileService.exploreArtworks(
        artistIds: [alumniId, ...linkedAccountIds],
      );
      final exhibitions = await _feralFileService.getAllExhibitions(
        relatedAccountIDs: [alumniId, ...linkedAccountIds],
      );
      final post = await _feralFileService.getPosts(
        relatedAccountIds: [alumniId, ...linkedAccountIds],
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
