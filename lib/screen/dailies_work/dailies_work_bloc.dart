import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/home_widget_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';

class DailyWorkEvent {}

class GetDailyAssetTokenEvent extends DailyWorkEvent {}

class DailyWorkBloc extends Bloc<DailyWorkEvent, DailiesWorkState> {
  final FeralFileService _feralfileService;
  final IndexerService _indexerService;

  DailyWorkBloc(this._feralfileService, this._indexerService)
      : super(DailiesWorkState(dailyInfos: [])) {
    on<GetDailyAssetTokenEvent>((event, emit) async {
      final dailiesToken = await _feralfileService.getCurrentDailiesToken();
      final dailyInfos = dailiesToken == null
          ? <DailyInfo>[]
          : [await getDailyInfo(dailiesToken)];

      emit(DailiesWorkState(dailyInfos: dailyInfos));

      unawaited(injector<HomeWidgetService>().updateDailyTokensToHomeWidget());
    });
  }

  Future<DailyInfo> getDailyInfo(DailyToken daily) async {
    final assetTokens = <AssetToken>[];
    AlumniAccount? currentArtist;
    Exhibition? currentExhibition;
    final tokens = await _indexerService
        .getNftTokens(QueryListTokensRequest(ids: [daily.indexId]));
    assetTokens.addAll(tokens);

    if (assetTokens.isEmpty) {
      return DailyInfo(daily, assetTokens, currentArtist, currentExhibition);
    }

    final token = assetTokens.first;
    if (token.isFeralfile) {
      if (token.artistID != null) {
        currentArtist =
            await _feralfileService.getAlumniDetail(token.artistID!);
      }
      currentExhibition =
          await _feralfileService.getExhibitionFromTokenID(daily!.tokenID);
    }
    return DailyInfo(daily, assetTokens, currentArtist, currentExhibition);
  }
}

class DailyInfo {
  DailyToken daily;
  List<AssetToken> assetTokens;
  AlumniAccount? currentArtist;
  Exhibition? currentExhibition;

  DailyInfo(
      this.daily, this.assetTokens, this.currentArtist, this.currentExhibition);
}
