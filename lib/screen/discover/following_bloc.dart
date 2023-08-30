import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/entity/followee.dart';
import 'package:autonomy_flutter/service/followee_service.dart';

abstract class FollowingEvent {}

class GetFolloweeEvent extends FollowingEvent {}

class FollowingState {
  List<Followee> followees;

  FollowingState({
    required this.followees,
  });
}

class FollowingBloc extends AuBloc<FollowingEvent, FollowingState> {
  final FolloweeService _followingService;

  FollowingBloc(
    this._followingService,
  ) : super(FollowingState(followees: [])) {
    on<GetFolloweeEvent>((event, emit) async {
      final followees = await _followingService.getFollowees();
      emit(
        FollowingState(followees: followees),
      );
    });
  }
}
