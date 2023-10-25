import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/services/tokens_service.dart';

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
  final tokenService = injector.get<TokensService>();
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
            final assetToken = await _waitUntilPostcardConfirm();
            if (assetToken != null && mounted) {
              await _receivePostcard(context, assetToken);
            }
          },
          color: const Color.fromRGBO(79, 174, 79, 1),
        ),
      ),
    );
  }

  Future<AssetToken?> _waitUntilPostcardConfirm() async {
    final tokenId = widget.asset.id;
    bool isExit = false;
    while (!isExit) {
      final postcard = await injector<PostcardService>().getPostcard(tokenId);
      if (postcard.isStamped) {
        return postcard;
      }
    }
  }

  Future<AssetToken?> _receivePostcard(
      BuildContext context, AssetToken asset) async {
    final geoLocation = internetUserGeoLocation;
    final accountService = injector<AccountService>();
    final addresses = await accountService.getAddress(asset.blockchain);
    String? address;
    AssetToken? pendingToken;
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
    if (address != null) {
      try {
        pendingToken =
            await injector.get<PostcardService>().claimSharedPostcardToAddress(
                  address: address,
                  assetToken: asset,
                  location: geoLocation.position,
                  shareCode: widget.shareCode,
                );
        if (!mounted) return null;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.homePage,
          (route) => false,
        );
        Navigator.of(context).pushNamed(AppRouter.designStamp,
            arguments: DesignStampPayload(pendingToken));
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
