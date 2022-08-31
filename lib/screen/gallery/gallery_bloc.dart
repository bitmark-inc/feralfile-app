import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/models/asset_token.dart';

part 'gallery_state.dart';

class GalleryBloc extends AuBloc<GalleryEvent, GalleryState> {
  final IndexerApi _indexerApi;

  GalleryBloc(this._indexerApi)
      : super(GalleryState(
          tokens: null,
          nextPageKey: 0,
          isLastPage: false,
          isLoading: false,
        )) {
    on<GetTokensEvent>((event, emit) async {
      if (state.isLoading || state.isLastPage) return;
      log.info('[GalleryBloc] GetTokensEvent');
      emit(state.copyWith(isLoading: true));

      try {
        final tokens = (await _indexerApi.getNftTokensByOwner(
                event.address, state.nextPageKey, INDEXER_TOKENS_MAXIMUM))
            .map((asset) => AssetToken.fromAsset(asset))
            .toList();
        // reload if tokensLength's 0 because it might be indexing case
        final isLastPage =
            tokens.isEmpty ? false : tokens.length < INDEXER_TOKENS_MAXIMUM;

        List<AssetToken> allTokens = (state.tokens ?? []) + tokens;

        emit(GalleryState(
          tokens: allTokens,
          nextPageKey: state.nextPageKey + tokens.length + 1,
          isLastPage: isLastPage,
          isLoading: false,
        ));
      } catch (_) {
        emit(state.copyWith(isLoading: false));
        rethrow;
      }
    });

    on<ReindexIndexerEvent>((event, emit) async {
      final blockchain = event.address.blockchainForAddress;
      if (blockchain == null) return;
      _indexerApi
          .requestIndex({"owner": event.address, "blockchain": blockchain});
    });
  }
}
