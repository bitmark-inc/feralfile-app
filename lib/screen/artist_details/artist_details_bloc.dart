import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/artist_details/artist_details_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class UserDetailsEvent {}

class ArtistDetailsFetchArtistEvent extends UserDetailsEvent {
  final String artistId;

  ArtistDetailsFetchArtistEvent({required this.artistId});
}

class CurationDetailsFetchCuratorEvent extends UserDetailsEvent {
  final String curatorId;

  CurationDetailsFetchCuratorEvent({required this.curatorId});
}

class UserDetailsBloc extends AuBloc<UserDetailsEvent, UserDetailsState> {
  final FeralFileService _feralFileService = injector<FeralFileService>();

  UserDetailsBloc() : super(UserDetailsState()) {
    on<ArtistDetailsFetchArtistEvent>((event, emit) async {
      final artist = await _feralFileService.getUser(event.artistId);
      final artistId = artist.id;
      final linkedAccountIds =
          artist.linkedAccounts.map((account) => account.id).toList();

      final artworks = await _feralFileService.exploreArtworks(
        artistIds: [artistId, ...linkedAccountIds],
      );
      final exhibitions = await _feralFileService.getAllExhibitions(
        relatedAccountIDs: [artistId, ...linkedAccountIds],
      );
      final post = await _feralFileService.getPosts(
        relatedAccountIds: [artistId, ...linkedAccountIds],
      );
      emit(UserDetailsState(
        artist: artist,
        series: artworks.result,
        exhibitions: exhibitions,
        posts: post,
      ));
    });
  }
}
