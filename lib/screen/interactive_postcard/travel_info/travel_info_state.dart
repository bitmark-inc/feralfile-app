import 'package:autonomy_flutter/model/travel_infor.dart';

class TravelInfoState {
  final List<TravelInfo>? listTravelInfo;
  final TravelInfo? lastTravelInfo;

  TravelInfoState({this.listTravelInfo, this.lastTravelInfo});
}
