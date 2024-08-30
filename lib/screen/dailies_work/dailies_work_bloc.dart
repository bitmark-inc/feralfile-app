import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
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
      : super(DailiesWorkState(
            assetTokens: [],
            currentDailyToken: null,
            currentArtist: null,
            currentExhibition: null)) {
    on<GetDailyAssetTokenEvent>((event, emit) async {
      final dailiesToken = await _feralfileSerivce.getCurrentDailiesToken();
      final assetTokens = <AssetToken>[];
      FFArtist? currentArtist;
      Exhibition? currentExhibition;
      if (dailiesToken != null) {
        final tokens = await _indexerService
            .getNftTokens(QueryListTokensRequest(ids: [dailiesToken.indexId]));
        assetTokens.addAll(tokens);
      }

      final token = assetTokens.first;
      if (token.isFeralfile) {
        if (token.artistID != null) {
          currentArtist =
              (await _feralfileSerivce.getUser(token.artistID!)).toFFArtist();
        }
        currentExhibition = await _feralfileSerivce
            .getExhibitionFromTokenID(dailiesToken!.tokenID);
      }

      emit(DailiesWorkState(
          assetTokens: assetTokens,
          currentDailyToken: dailiesToken,
          currentArtist: currentArtist,
          currentExhibition: currentExhibition));
    });
  }
}
