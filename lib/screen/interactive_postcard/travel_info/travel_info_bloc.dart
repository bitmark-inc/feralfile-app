import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_state.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
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
      final postcardMetadata = event.asset.postcardMetadata;
      final travelInfo = postcardMetadata.listTravelInfoWithoutLocationName;
      await Future.wait(
        travelInfo.map(
          (e) async {
            await e.getLocationName();
          },
        ),
      );
      emit(TravelInfoState(listTravelInfo: travelInfo));
    });
  }
}
