import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';

abstract class RoyaltyEvent {}

class GetRoyaltyInfoEvent extends RoyaltyEvent {
  final String? exhibitionID;
  final String? artworkID;
  final String contractAddress;

  GetRoyaltyInfoEvent(
      {this.exhibitionID, this.artworkID, this.contractAddress = ''});
}

class RoyaltyState {
  final String? exhibitionID;
  final String? markdownData;

  RoyaltyState({this.exhibitionID, this.markdownData});
}

class RoyaltyBloc extends AuBloc<RoyaltyEvent, RoyaltyState> {
  final FeralFileService _feralFileService;
  final dio = baseDio(BaseOptions(
    baseUrl: 'https://raw.githubusercontent.com',
    connectTimeout: const Duration(seconds: 5),
  ));

  RoyaltyBloc(this._feralFileService) : super(RoyaltyState()) {
    on<GetRoyaltyInfoEvent>((event, emit) async {
      try {
        final String? exhibitionID = event.exhibitionID ??
            (await _feralFileService
                    .getExhibitionFromTokenID(event.artworkID ?? ''))
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
          final partnerName =
              await _feralFileService.getPartnerFullName(exhibitionID);
          final curatorName =
              _feralFileService.getCuratorFullName(exhibitionID);
          final nameMapper = {
            RoyaltyType.platform: 'Feral File',
          };
          if (partnerName != null) {
            nameMapper[RoyaltyType.partner] = partnerName;
          }
          if (curatorName != null) {
            nameMapper[RoyaltyType.curator] = curatorName;
          }

          final revenueSetting = resaleInfo.getRoyaltySetting(nameMapper);
          var data = await dataFuture;
          if (data.statusCode == 200) {
            emit(RoyaltyState(
                markdownData: data.data
                    ?.replaceAll('{{revenue_setting}}', revenueSetting)));
          }
        }
      } catch (e) {
        log.info('Royalty bloc $e');
        emit(RoyaltyState());
      }
    });
  }
}
