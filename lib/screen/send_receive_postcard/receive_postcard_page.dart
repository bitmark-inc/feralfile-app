import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';

class ReceivePostcardPageArgs {
  final AssetToken asset;
  final String shareCode;

  ReceivePostcardPageArgs({required this.asset, required this.shareCode});
}

class ReceivePostCardPage extends StatefulWidget {
  final AssetToken asset;
  final String shareCode;

  const ReceivePostCardPage({
    Key? key,
    required this.asset,
    required this.shareCode,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ReceivePostCardPageState();
  }
}

class _ReceivePostCardPageState extends State<ReceivePostCardPage> {
  final metricClient = injector.get<MetricClientService>();
  late bool _isProcessing;

  @override
  void initState() {
    _fetchIdentities();
    super.initState();
    _isProcessing = false;
  }

  void _fetchIdentities() {
    final neededIdentities = [
      widget.asset.artistName ?? '',
    ];
    neededIdentities.removeWhere((element) => element == '');

    if (neededIdentities.isNotEmpty) {
      context.read<IdentityBloc>().add(GetIdentityEvent(neededIdentities));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    return PostcardExplain(
      payload: PostcardExplainPayload(
        asset,
        PostcardButton(
          text: "continue".tr(),
          fontSize: 18,
          enabled: !(_isProcessing),
          isProcessing: _isProcessing,
          onTap: () async {
            setState(() {
              _isProcessing = true;
            });
            await _receivePostcard(context, asset);
          },
          color: const Color.fromRGBO(79, 174, 79, 1),
        ),
      ),
    );
  }

  Future<AssetToken?> _receivePostcard(
      BuildContext context, AssetToken asset) async {
    GeoLocation? location;
    try {
      location = await getGeoLocationWithPermission(
          timeout: const Duration(seconds: 5));
      if (location == null) return null;
    } catch (e) {
      log.info("[Postcard] Error getting location: $e");
      if (!mounted) return null;
      await UIHelper.showWeakGPSSignal(context);
      setState(() {
        _isProcessing = false;
      });
      return null;
    }

    final accountService = injector<AccountService>();
    final addresses = await accountService.getAddress(asset.blockchain);
    String? address;
    if (addresses.isEmpty) {
      final defaultPersona = await accountService.getOrCreateDefaultPersona();
      final walletAddress =
          await defaultPersona.insertNextAddress(WalletType.Tezos);
      address = walletAddress.first.address;
    } else if (addresses.length == 1) {
      address = addresses.first;
    } else {
      if (!mounted) return null;
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
    AssetToken? pendingToken;
    if (address != null) {
      try {
        final response = await injector<PostcardService>().receivePostcard(
            shareCode: widget.shareCode,
            location: location.position,
            address: address);
        var postcardMetadata = asset.postcardMetadata;
        postcardMetadata.locationInformation
            .add(UserLocations(claimedLocation: location.position));
        var newAsset = asset.asset;
        newAsset?.artworkMetadata = jsonEncode(postcardMetadata.toJson());
        pendingToken =
            asset.copyWith(owner: response.owner, asset: newAsset, balance: 1);

        final tokenService = injector<TokensService>();
        await tokenService.setCustomTokens([pendingToken]);
        tokenService.reindexAddresses([address]);
        NftCollectionBloc.eventController.add(
          GetTokensByOwnerEvent(pageKey: PageKey.init()),
        );
        if (!mounted) return null;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.homePage,
          (route) => false,
        );
        Navigator.of(context).pushNamed(AppRouter.designStamp,
            arguments: DesignStampPayload(pendingToken, location));
      } catch (e) {
        if (e is DioException) {
          if (!mounted) return null;
          await UIHelper.showAlreadyClaimedPostcard(
            context,
            e,
          );
          if (!mounted) return null;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.homePage,
            (route) => false,
          );

          // emit(state.copyWith(isReceiving: false, error: e));
        }
      }
    }
    setState(() {
      _isProcessing = false;
    });
    return pendingToken;
  }
}

class ReceivePostcardResponse {
  final String tokenID;
  final String imageCID;
  final String blockchain;
  final String owner;
  final String contractAddress;

  ReceivePostcardResponse(this.tokenID, this.imageCID, this.blockchain,
      this.owner, this.contractAddress);

  factory ReceivePostcardResponse.fromJson(Map<String, dynamic> json) {
    return ReceivePostcardResponse(
      json['tokenID'],
      json['imageCID'],
      json['blockchain'],
      json['owner'],
      json['contractAddress'],
    );
  }

  Map<String, dynamic> toJson() => {
        'tokenID': tokenID,
        'imageCID': imageCID,
        'blockchain': blockchain,
        'owner': owner,
        'contractAddress': contractAddress,
      };
}
