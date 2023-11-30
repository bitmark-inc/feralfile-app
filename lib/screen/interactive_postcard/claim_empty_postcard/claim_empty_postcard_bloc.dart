import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/tokens_service.dart';

// ignore: always_use_package_imports
import 'claim_empty_postcard_state.dart';

class ClaimEmptyPostCardBloc
    extends Bloc<ClaimEmptyPostCardEvent, ClaimEmptyPostCardState> {
  final _postcardService = injector.get<PostcardService>();
  final configService = injector<ConfigurationService>();
  final accountService = injector<AccountService>();
  final navigationService = injector.get<NavigationService>();
  final _tokensService = injector.get<TokensService>();

  ClaimEmptyPostCardBloc() : super(ClaimEmptyPostCardState()) {
    on<GetTokenEvent>((event, emit) async {
      if (event.claimRequest is PayToMintRequest) {
        final payToMintRequest = event.claimRequest as PayToMintRequest;
        final indexId = payToMintRequest.tokenId;
        final tokenId = 'tez-${Environment.postcardContractAddress}-$indexId';
        log.info('[Pay to mint] tokenId: $tokenId');
        final token = AssetToken(
          asset: Asset.init(
            indexID: tokenId,
            artistName: 'MoMa',
            maxEdition: 1,
            mimeType: 'image/png',
            title: event.claimRequest.name,
            medium: 'software',
            previewURL: event.claimRequest.previewURL,
            artworkMetadata: event.createMetadata
                ? jsonEncode(PostcardMetadata(
                    prompt: payToMintRequest.prompt,
                    locationInformation: [],
                  ).toJson())
                : null,
          ),
          blockchain: 'tezos',
          fungible: true,
          contractType: 'fa2',
          tokenId: indexId,
          contractAddress: Environment.postcardContractAddress,
          edition: 0,
          editionName: '',
          id: tokenId,
          balance: 1,
          owner: payToMintRequest.address,
          lastActivityTime: DateTime.now(),
          lastRefreshedTime: DateTime(1),
          pending: true,
          originTokenInfo: [],
          provenance: [],
          owners: {
            payToMintRequest.address: 1,
          },
        );
        await _tokensService.setCustomTokens([token]);
        unawaited(_tokensService.reindexAddresses([payToMintRequest.address]));
        await injector
            .get<ConfigurationService>()
            .setListPostcardMint([tokenId]);
        NftCollectionBloc.eventController.add(
          GetTokensByOwnerEvent(pageKey: PageKey.init()),
        );
        emit(state.copyWith(assetToken: token));
      } else {
        final token = AssetToken(
          asset: Asset.init(
            artistName: 'MoMa',
            maxEdition: 1,
            mimeType: 'image/png',
            title: event.claimRequest.name,
            medium: 'software',
            previewURL: event.claimRequest.previewURL,
            artworkMetadata: event.createMetadata
                ? jsonEncode(PostcardMetadata(
                    locationInformation: [],
                  ).toJson())
                : null,
          ),
          blockchain: 'tezos',
          fungible: true,
          contractType: 'fa2',
          tokenId: '1',
          contractAddress: Environment.postcardContractAddress,
          edition: 0,
          editionName: '',
          id: 'tez-',
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
      }
    });

    on<AcceptGiftEvent>((event, emit) async {
      emit(state.copyWith(isClaiming: true));
      String? address;
      final addresses = await accountService.getAddress('Tezos');
      if (addresses.isEmpty) {
        final defaultPersona = await accountService.getOrCreateDefaultPersona();
        await configService.setDoneOnboarding(true);
        await configService.setPendingSettings(true);
        await injector<MetricClientService>()
            .mixPanelClient
            .initIfDefaultAccount();

        final walletAddress =
            await defaultPersona.insertNextAddress(WalletType.Tezos);
        address = walletAddress.first.address;
      } else if (addresses.length == 1) {
        address = addresses.first;
      } else {
        address = await navigationService.navigateTo(
          AppRouter.selectAddressScreen,
          arguments: {
            'blockchain': 'Tezos',
            'onConfirm': (String address) async {
              navigationService.goBack(result: address);
            },
            'withLinked': false,
          },
        );
      }
      try {
        if (address != null) {
          final token = await _postcardService.claimEmptyPostcardToAddress(
              address: address, requestPostcardResponse: event.claimRequest);
          emit(state.copyWith(
              isClaiming: false, isClaimed: true, assetToken: token));
        } else {
          emit(state.copyWith(isClaiming: false, isClaimed: false));
        }
      } on DioException catch (e) {
        emit(
          state.copyWith(
            isClaiming: false,
            isClaimed: false,
            error: e,
          ),
        );
      }
    });
  }
}
