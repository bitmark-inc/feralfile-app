import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';

class DailyWorkEvent {}

class GetDailyAssetTokenEvent extends DailyWorkEvent {}

class DailyWorkBloc extends Bloc<DailyWorkEvent, DailiesWorkState> {
  final FeralFileService _feralfileSerivce;
  final IndexerService _indexerService;

  DailyWorkBloc(this._feralfileSerivce, this._indexerService)
      : super(DailiesWorkState(assetTokens: [])) {
    on<GetDailyAssetTokenEvent>((event, emit) async {
      final dailiesToken = await _feralfileSerivce.getCurrentDailiesToken();
      final assetTokens = <AssetToken>[];
      if (dailiesToken != null) {
        final tokens = await _indexerService
            .getNftTokens(QueryListTokensRequest(ids: [dailiesToken.indexId]));
        assetTokens.addAll(tokens);
      }
      emit(DailiesWorkState(assetTokens: assetTokens));
    });
  }
}
