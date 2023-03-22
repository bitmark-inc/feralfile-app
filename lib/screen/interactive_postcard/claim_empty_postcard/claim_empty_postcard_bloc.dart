import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:dio/dio.dart';
import 'package:nft_collection/models/models.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/tokens_service.dart';

import 'claim_empty_postcard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClaimEmptyPostCardBloc
    extends Bloc<ClaimEmptyPostCardEvent, ClaimEmptyPostCardState> {
  final _postcardService = injector.get<PostcardService>();
  final _tokenService = injector.get<TokensService>();

  ClaimEmptyPostCardBloc() : super(ClaimEmptyPostCardState()) {
    on<GetTokenEvent>((event, emit) async {
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

    on<AcceptGiftEvent>((event, emit) async {
      emit(state.copyWith(isClaiming: true));
      String? address;
      final accountService = injector<AccountService>();
      final addresses = await accountService.getAddress('Tezos');
      if (addresses.isEmpty) {
        final defaultAccount = await accountService.getDefaultAccount();
        final configService = injector<ConfigurationService>();
        await configService.setDoneOnboarding(true);
        injector<MetricClientService>().mixPanelClient.initIfDefaultAccount();
        await configService.setPendingSettings(true);
        address = await defaultAccount.getTezosAddress();
      } else if (addresses.length == 1) {
        address = addresses.first;
      } else {
        final navigationService = injector.get<NavigationService>();
        address = await navigationService.navigateTo(
          AppRouter.selectAddressScreen,
          arguments: {
            'blockchain': 'Tezos',
          },
        );
      }
      try {
        if (address != null) {
          final result = await _postcardService.claimEmptyPostcard(
            address: address,
            id: 'postcard',
          );
          final tokenID = 'tez-${result.contractAddress}-${result.tokenID}';
          final token = AssetToken(
            asset: Asset.init(
              artistName: 'MoMa',
              maxEdition: 1,
              mimeType: 'image/png',
              title: 'Postcard 001',
              thumbnailURL: result.imageCID,
              previewURL: result.imageCID,
            ),
            blockchain: "tezos",
            fungible: false,
            contractType: '',
            tokenId: result.tokenID,
            contractAddress: result.contractAddress,
            edition: 0,
            editionName: "",
            id: tokenID,
            balance: 1,
            owner: address,
            lastActivityTime: DateTime.now(),
            lastRefreshedTime: DateTime(1),
            pending: true,
            originTokenInfo: [],
            provenance: [],
            owners: {},
          );
          await _tokenService.setCustomTokens([token]);
          await _tokenService.reindexAddresses([address]);
          NftCollectionBloc.eventController.add(
            GetTokensByOwnerEvent(pageKey: PageKey.init()),
          );
          emit(state.copyWith(isClaiming: false, isClaimed: true));
        }
      } on DioError catch (e) {
        emit(
          state.copyWith(
            isClaiming: false,
            isClaimed: false,
            error: e.response?.data["message"],
          ),
        );
      }
    });
  }
}
