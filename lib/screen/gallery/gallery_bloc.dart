import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:bloc/bloc.dart';
import 'package:autonomy_flutter/util/string_ext.dart';

part 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  IndexerApi _indexerApi;

  GalleryBloc(this._indexerApi) : super(GalleryState(tokens: null)) {
    on<GetTokensEvent>((event, emit) async {
      final tokens = (await _indexerApi.getNftTokensByOwner(
              event.address, 0, INDEXER_TOKENS_MAXIMUM))
          .map((asset) => AssetToken.fromAsset(asset))
          .toList();

      emit(GalleryState(tokens: tokens));
    });

    on<ReindexIndexerEvent>((event, emit) async {
      final blockchain = event.address.blockchainForAddress;
      if (blockchain == null) return;
      _indexerApi
          .requestIndex({"owner": event.address, "blockchain": blockchain});
    });
  }
}
