import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/tokens_service.dart';

import 'claim_empty_postcard_state.dart';

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
          title: event.claimRequest.name,
          medium: 'software',
          previewURL: event.claimRequest.previewURL,
        ),
        blockchain: "tezos",
        fungible: true,
        contractType: 'fa2',
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
        final defaultPersona = await accountService.getOrCreateDefaultPersona();
        final configService = injector<ConfigurationService>();
        await configService.setDoneOnboarding(true);
        injector<MetricClientService>().mixPanelClient.initIfDefaultAccount();

        final walletAddress =
            await defaultPersona.insertAddress(WalletType.Tezos);
        address = walletAddress.first.address;
      } else if (addresses.length == 1) {
        address = addresses.first;
      } else {
        final navigationService = injector.get<NavigationService>();
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
          final tezosService = injector.get<TezosService>();
          final timestamp =
              (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
          final account = await accountService.getAccountByAddress(
            chain: 'tezos',
            address: address,
          );
          final signature = await tezosService.signMessage(account.wallet,
              account.index, Uint8List.fromList(utf8.encode(timestamp)));
          final publicKey =
              await account.wallet.getTezosPublicKey(index: account.index);
          final claimRequest = ClaimPostCardRequest(
            address: address,
            claimID: event.claimRequest.claimID,
            timestamp: timestamp,
            publicKey: publicKey,
            signature: signature,
            location: [
              moMAGeoLocation.position.lat,
              moMAGeoLocation.position.lon
            ],
          );
          final result =
              await _postcardService.claimEmptyPostcard(claimRequest);
          final tokenID = 'tez-${result.contractAddress}-${result.tokenID}';
          final postcardMetadata = PostcardMetadata(
            locationInformation: [
              UserLocations(
                claimedLocation: Location(
                  lat: -73.978271,
                  lon: 40.761509,
                ),
              )
            ],
          );
          final token = AssetToken(
            asset: Asset.init(
              indexID: tokenID,
              artistName: 'MoMa',
              maxEdition: 1,
              mimeType: 'image/png',
              title: event.claimRequest.name,
              previewURL: event.claimRequest.previewURL,
              source: 'postcard',
              artworkMetadata: jsonEncode(postcardMetadata.toJson()),
              medium: 'software',
            ),
            blockchain: "tezos",
            fungible: false,
            contractType: 'fa2',
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
          _tokenService.reindexAddresses([address]);
          injector.get<ConfigurationService>().setListPostcardMint([tokenID]);
          NftCollectionBloc.eventController.add(
            GetTokensByOwnerEvent(pageKey: PageKey.init()),
          );
          emit(state.copyWith(
              isClaiming: false, isClaimed: true, assetToken: token));
        } else {
          emit(state.copyWith(isClaimed: false, isClaiming: false));
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
