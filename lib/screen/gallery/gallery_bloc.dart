import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';

part 'gallery_state.dart';

class GalleryBloc extends AuBloc<GalleryEvent, GalleryState> {
  final IndexerService _indexerService;
  final IndexerApi _indexerApi;

  GalleryBloc(
    this._indexerApi,
    this._indexerService,
  ) : super(GalleryState(
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
        final request = QueryListTokensRequest(
          owners: [event.address],
          offset: state.nextPageKey,
          // ignore: avoid_redundant_argument_values
          size: INDEXER_TOKENS_MAXIMUM,
        );
        final tokens = (await _indexerService.getNftTokens(request)).toList();
        // reload if tokensLength's 0 because it might be indexing case
        final isLastPage =
            tokens.isEmpty ? false : tokens.length < INDEXER_TOKENS_MAXIMUM;
        final compactedAssetToken =
            tokens.map((e) => CompactedAssetToken.fromAssetToken(e)).toList();

        List<CompactedAssetToken> allTokens =
            (state.tokens ?? []) + compactedAssetToken;

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
