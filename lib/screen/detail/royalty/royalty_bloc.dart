import '../../../au_bloc.dart';
import '../../../model/ff_account.dart';
import '../../../service/feralfile_service.dart';
import '../../../util/log.dart';

abstract class RoyaltyEvent {}

class GetRoyaltyInfoEvent extends RoyaltyEvent {
  final String? exhibitionID;
  final String? editionID;

  GetRoyaltyInfoEvent({this.exhibitionID, this.editionID});
}

class RoyaltyState {
  final FeralFileResaleInfo? resaleInfo;
  final String? partnerName;
  final String? exhibitionID;

  RoyaltyState({this.resaleInfo, this.partnerName, this.exhibitionID});
}

class RoyaltyBloc extends AuBloc<RoyaltyEvent, RoyaltyState> {
  final FeralFileService _feralFileService;

  RoyaltyBloc(this._feralFileService) : super(RoyaltyState()) {
    on<GetRoyaltyInfoEvent>((event, emit) async {
      try {
        final String? exhibitionID = event.exhibitionID ??
            await _feralFileService
                .getExhibitionIdFromTokenID(event.editionID ?? "");
        if (exhibitionID != null) {
          final resaleInfo = await _feralFileService.getResaleInfo(exhibitionID);
          final name = await _feralFileService.getPartnerFullName(exhibitionID);
          emit(RoyaltyState(resaleInfo: resaleInfo, partnerName: name, exhibitionID: exhibitionID));
        }
      } catch (e) {
        log.info("Royalty bloc ${e.toString()}");
        emit(RoyaltyState());
      }

    });
  }
}
