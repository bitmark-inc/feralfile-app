import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_state.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

class ReceivePostcardBloc
    extends Bloc<ReceivePostcardEvent, ReceivePostcardState> {
  final _postcardService = injector.get<PostcardService>();
  final _navigationService = injector.get<NavigationService>();

  ReceivePostcardBloc() : super(ReceivePostcardState()) {
    on<AcceptPostcardEvent>((event, emit) async {
      emit(state.copyWith(isReceiving: true));
      try {
        final response = await _postcardService.receivePostcard(
            shareCode: event.shareCode,
            location: event.location,
            address: event.address);
      } catch (e) {
        if (e is DioError) {
          emit(state.copyWith(isReceiving: false, error: e));
        }
      }

      emit(state.copyWith(isReceiving: false));
    });

    on<GetPostcardEvent>((event, emit) async {
      try {
        final sharedPostcardInfor =
            await _postcardService.getSharedPostcardInfor(event.shareCode);
        final contractAddress = "KT1MeB8Wntrx4fjksZkCWUwmGDQTGs6DsMwp";
        final tokenId = 'tez-$contractAddress-${sharedPostcardInfor.tokenID}';
        final postcard = await _postcardService.getPostcard(tokenId);
        // emit(state.copyWith(postcard: postcard));
      } catch (e) {
        if (e is DioError) {
          emit(state.copyWith(error: e));
        }
      }
    });

    on<GetLocationEvent>((event, emit) async {
      Position? location;
      final permissions = await checkLocationPermissions();
      if (!permissions) {
        emit(state.copyWith(locationAllowed: false));
      } else {
        try {
          location = await getGeoLocation(timeout: const Duration(seconds: 2));
          emit(state.copyWith(locationAllowed: true, location: location));
        } catch (e) {
          emit(state.copyWith(locationAllowed: true));
        }
      }
    });
  }
}
