import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/entity/followee.dart';
import 'package:autonomy_flutter/service/followee_service.dart';
import 'package:collection/collection.dart';

abstract class FollowArtistEvent {}

class FollowArtistFetchEvent extends FollowArtistEvent {
  final List<String> artists;

  FollowArtistFetchEvent(this.artists);
}

class FollowEvent extends FollowArtistEvent {
  final String artist;

  FollowEvent(this.artist);
}

class UnfollowEvent extends FollowArtistEvent {
  final String artist;

  UnfollowEvent(this.artist);
}

class FollowArtistState {
  final List<ArtistFollowStatus> followStatus;

  FollowArtistState({required this.followStatus});

  FollowArtistState copyWith({
    List<ArtistFollowStatus>? followStatus,
  }) {
    return FollowArtistState(
      followStatus: followStatus ?? this.followStatus,
    );
  }
}

enum FollowStatus { followed, unfollowed, invalid }

class ArtistFollowStatus {
  final String artistID;
  final Followee? followee;
  final FollowStatus status;

  ArtistFollowStatus(this.artistID, this.followee, this.status);

  // copyWith method
  ArtistFollowStatus copyWith({
    Followee? followee,
    FollowStatus? status,
  }) {
    return ArtistFollowStatus(
      artistID,
      followee ?? this.followee,
      status ?? this.status,
    );
  }
}

class FollowArtistBloc extends AuBloc<FollowArtistEvent, FollowArtistState> {
  final FolloweeService _followeeService;

  FollowArtistBloc(
    this._followeeService,
  ) : super(FollowArtistState(followStatus: [])) {
    on<FollowArtistFetchEvent>((event, emit) async {
      final followees = await _followeeService.getFromAddresses(event.artists);
      final followStatus = event.artists.map((e) {
        final followee =
            followees.firstWhereOrNull((element) => element.address == e);
        if (followee == null || followee.isFollowed == false) {
          return ArtistFollowStatus(e, followee, FollowStatus.unfollowed);
        } else if (followee.canRemove) {
          return ArtistFollowStatus(e, followee, FollowStatus.followed);
        } else {
          return ArtistFollowStatus(e, followee, FollowStatus.invalid);
        }
      }).toList();
      emit(FollowArtistState(followStatus: followStatus));
    });

    on<FollowEvent>((event, emit) async {
      ArtistFollowStatus? artist = state.followStatus
          .firstWhereOrNull((element) => element.artistID == event.artist);
      if (artist != null) {
        final followee = await _followeeService.addArtistManual(event.artist);
        final newArtist =
            artist.copyWith(status: FollowStatus.followed, followee: followee);
        state.followStatus[state.followStatus.indexOf(artist)] = newArtist;
        emit(FollowArtistState(followStatus: state.followStatus));
      }
    });

    on<UnfollowEvent>((event, emit) async {
      ArtistFollowStatus? artist = state.followStatus
          .firstWhereOrNull((element) => element.artistID == event.artist);
      if (artist != null && artist.followee != null) {
        await _followeeService.unfollowArtistManual(artist.followee!);
        final newArtist = artist.copyWith(status: FollowStatus.unfollowed);
        state.followStatus[state.followStatus.indexOf(artist)] = newArtist;
        emit(FollowArtistState(followStatus: state.followStatus));
      }
    });
  }
}
