import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_state.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';

class TravelInfoEvent {}

class GetTravelInfoEvent extends TravelInfoEvent {
  final AssetToken asset;
  GetTravelInfoEvent({required this.asset});
}

class TravelInfoBloc extends Bloc<TravelInfoEvent, TravelInfoState> {
  TravelInfoBloc() : super(TravelInfoState()) {
    on<GetTravelInfoEvent>((event, emit) async {
      final asset = event.asset;
      final stamps = asset.postcardMetadata.locationInformation;

      final travelInfo = <TravelInfo>[];

      for (int i = 0; i < stamps.length - 1; i++) {
        travelInfo.add(TravelInfo(stamps[i], stamps[i + 1], i));
      }

      if (stamps[stamps.length - 1].stampedLocation != null) {
        travelInfo.add(
            TravelInfo(stamps[stamps.length - 1], null, stamps.length - 1));
      }

      await Future.wait(travelInfo.map((e) async {
        await e.getLocationName();
      }));

      if (travelInfo.length > 44) {
        travelInfo.removeLast();
      }
      emit(TravelInfoState(listTravelInfo: travelInfo));
    });
  }
}
