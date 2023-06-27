import 'package:autonomy_flutter/util/constants.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../au_bloc.dart';
import '../../../model/ff_account.dart';
import '../../../service/feralfile_service.dart';
import '../../../util/log.dart';

abstract class RoyaltyEvent {}

class GetRoyaltyInfoEvent extends RoyaltyEvent {
  final String? exhibitionID;
  final String? artworkID;
  final String contractAddress;

  GetRoyaltyInfoEvent(
      {this.exhibitionID, this.artworkID, this.contractAddress = ""});
}

class RoyaltyState {
  final String? exhibitionID;
  final String? markdownData;

  RoyaltyState({this.exhibitionID, this.markdownData});
}

class RoyaltyBloc extends AuBloc<RoyaltyEvent, RoyaltyState> {
  final FeralFileService _feralFileService;
  final dio = Dio(BaseOptions(
    baseUrl: "https://raw.githubusercontent.com",
    connectTimeout: 2000,
  ));

  RoyaltyBloc(this._feralFileService) : super(RoyaltyState()) {
    on<GetRoyaltyInfoEvent>((event, emit) async {
      try {
        final String? exhibitionID = event.exhibitionID ??
            (await _feralFileService
                    .getExhibitionFromTokenID(event.artworkID ?? ""))
                ?.id;
        if (exhibitionID != null) {
          if (MOMA_MEMENTO_EXHIBITION_IDS.contains(exhibitionID)) {
            final data = await dio.get<String>(COLLECTOR_RIGHTS_MEMENTO_DOCS);
            if (data.statusCode == 200) {
              emit(RoyaltyState(markdownData: data.data));
            }
            return;
          }

          if (event.contractAddress == MOMA_009_UNSUPERVISED_CONTRACT_ADDRESS) {
            final data = await dio
                .get<String>(COLLECTOR_RIGHTS_MOMA_009_UNSUPERVISED_DOCS);
            if (data.statusCode == 200) {
              emit(RoyaltyState(markdownData: data.data));
            }
            return;
          }
          final dataFuture = dio.get<String>(COLLECTOR_RIGHTS_DEFAULT_DOCS);
          final resaleInfo =
              await _feralFileService.getResaleInfo(exhibitionID);
          final name = await _feralFileService.getPartnerFullName(exhibitionID);
          final revenueSetting =
              _getRevenueSetting(resaleInfo, name ?? "partner".tr());
          var data = await dataFuture;
          if (data.statusCode == 200) {
            emit(RoyaltyState(
                markdownData: data.data
                    ?.replaceAll("{{revenue_setting}}", revenueSetting)));
          }
        }
      } catch (e) {
        log.info("Royalty bloc ${e.toString()}");
        emit(RoyaltyState());
      }
    });
  }

  String _getRevenueSetting(
      FeralFileResaleInfo resaleInfo, String partnerName) {
    final artist = (resaleInfo.artist * 100).toString();
    final platform = (resaleInfo.platform * 100).toString();
    final partner = (resaleInfo.partner * 100).toString();
    if (resaleInfo.partner > 0) {
      return "revenue_setting_with"
          .tr(args: [artist, platform, partnerName, partner]);
    } else {
      return "revenue_setting".tr(args: [artist, platform]);
    }
  }
}
