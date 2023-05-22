import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class ReceivePostcardEvent {}

class ReceivePostcardState {
  final bool? isReceiving;
  final bool? locationAllowed;
  final Position? location;
  final DioError? error;

  ReceivePostcardState({
    this.isReceiving,
    this.locationAllowed,
    this.location,
    this.error,
  });

  ReceivePostcardState copyWith({
    bool? isReceiving,
    bool? locationAllowed,
    Position? location,
    DioError? error,
  }) {
    return ReceivePostcardState(
      isReceiving: isReceiving ?? this.isReceiving,
      locationAllowed: locationAllowed ?? this.locationAllowed,
      location: location ?? this.location,
      error: error ?? this.error,
    );
  }
}

class AcceptPostcardEvent extends ReceivePostcardEvent {
  final String address;
  final String shareCode;
  final Position location;

  AcceptPostcardEvent(this.address, this.shareCode, this.location);
}

class GetLocationEvent extends ReceivePostcardEvent {}

class GetPostcardEvent extends ReceivePostcardEvent {
  final String shareCode;

  GetPostcardEvent(this.shareCode);
}
