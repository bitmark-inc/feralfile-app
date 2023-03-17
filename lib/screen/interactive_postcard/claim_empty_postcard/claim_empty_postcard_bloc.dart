import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:nft_collection/models/models.dart';

import 'claim_empty_postcard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClaimEmptyPostCardBloc
    extends Bloc<ClaimEmptyPostCardEvent, ClaimEmptyPostCardState> {
  final _postcardService = injector.get<PostcardService>();
  ClaimEmptyPostCardBloc() : super(ClaimEmptyPostCardState()) {
    on<GetTokenEvent>((event, emit) async {
      //test mock api
      try {
        await _postcardService.claimEmptyPostcard();
        // ignore: empty_catches
      } catch (e) {}

      final token = AssetToken(
        asset: Asset.init(
          artistName: 'MoMa',
          maxEdition: 1,
          mimeType: 'image/png',
          title: 'Postcard 001',
          thumbnailURL: 'https://picsum.photos/350/250',
        ),
        blockchain: "tezos",
        fungible: false,
        contractType: '',
        tokenId: '1',
        contractAddress: '',
        edition: 0,
        editionName: "",
        id: "tez-",
        balance: 1,
        owner: 'owner',
        lastActivityTime: DateTime.now(),
        lastRefreshedTime: DateTime(1),
        pending: true,
        originTokenInfo: [],
        provenance: [],
        owners: {},
      );
      emit(state.copyWith(assetToken: token));
    });
  }
}
