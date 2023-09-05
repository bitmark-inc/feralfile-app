import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/tokens_service.dart';

abstract class DiscoverArtEvent {}

class DiscoverArtFetchEvent extends DiscoverArtEvent {}

class DiscoverArtState {
  final List<AssetToken> tokenList;
  final bool isLoading;
  final Map<String, dynamic> artistNames;

  DiscoverArtState({
    required this.tokenList,
    required this.isLoading,
    required this.artistNames,
  });

  DiscoverArtState copyWith(
      {List<AssetToken>? tokenList,
      bool? isLoading,
      Map<String, dynamic>? artistNames}) {
    return DiscoverArtState(
      tokenList: tokenList ?? this.tokenList,
      isLoading: isLoading ?? this.isLoading,
      artistNames: artistNames ?? this.artistNames,
    );
  }
}

class DiscoverArtBloc extends AuBloc<DiscoverArtEvent, DiscoverArtState> {
  final PubdocAPI _pubdocAPI;
  final TokensService _tokensService;

  DiscoverArtBloc(this._pubdocAPI, this._tokensService)
      : super(
            DiscoverArtState(tokenList: [], isLoading: true, artistNames: {})) {
    on<DiscoverArtFetchEvent>((event, emit) async {
      final suggestedArtistList =
          await _pubdocAPI.getSuggestedArtistsFromGithub();
      final List<String> tokenIDs = [];
      final Map<String, List<String>> artistNames = {};
      for (var element in suggestedArtistList) {
        tokenIDs.addAll(element.tokenIDs);
        for (var token in element.tokenIDs) {
          if (artistNames[token] == null) {
            artistNames[token] = [element.name];
          } else {
            artistNames[token]!.add(element.name);
          }
        }
      }
      final tokens = await _tokensService.fetchManualTokens(tokenIDs);
      emit(state.copyWith(
          tokenList: tokens, isLoading: false, artistNames: artistNames));
    });
  }
}
