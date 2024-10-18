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
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
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

  const ReceivePostCardPage(
      {required this.asset, required this.shareCode, super.key});

  @override
  State<StatefulWidget> createState() => _ReceivePostCardPageState();
}

class _ReceivePostCardPageState extends State<ReceivePostCardPage> {
  final metricClient = injector.get<MetricClientService>();
  final tokenService = injector.get<TokensService>();
  final accountService = injector<AccountService>();
  final postcardService = injector<PostcardService>();
  late bool _isProcessing;
  late bool _isConfirming;
  late AssetToken assetToken;

  @override
  void initState() {
    _fetchIdentities();
    super.initState();
    _isProcessing = false;
    _isConfirming = !widget.asset.isStamped;
    assetToken = widget.asset;
    unawaited(_waitUntilPostcardConfirm());
  }

  void _fetchIdentities() {
    final neededIdentities = [
      widget.asset.artistName ?? '',
    ]..removeWhere((element) => element == '');

    if (neededIdentities.isNotEmpty) {
      context.read<IdentityBloc>().add(GetIdentityEvent(neededIdentities));
    }
  }

  @override
  Widget build(BuildContext context) => PostcardExplain(
        payload: PostcardExplainPayload(
          assetToken,
          PostcardButton(
            text: _isConfirming
                ? 'confirming_on_blockchain_'.tr()
                : 'continue'.tr(),
            fontSize: 18,
            enabled: !(_isProcessing || _isConfirming),
            isProcessing: _isProcessing,
            onTap: () async {
              setState(() {
                _isProcessing = true;
              });
              await _receivePostcard(context, assetToken);
            },
            color: POSTCARD_GREEN_BUTTON_COLOR,
          ),
        ),
      );

  Future<AssetToken> _waitUntilPostcardConfirm() async {
    final tokenId = widget.asset.id;
    bool isExit = false;
    while (!isExit) {
      final postcard = await injector<PostcardService>().getPostcard(tokenId);
      if (postcard.isStamped) {
        setState(() {
          _isConfirming = false;
          assetToken = postcard;
        });
        return postcard;
      }
    }
  }

  Future<String?> _getAddress(String blockchain) async {
    final addresses = await accountService.getAddress(blockchain);
    String? address;
    if (addresses.isEmpty) {
      final walletAddress =
          await accountService.insertNextAddress(WalletType.Tezos);
      address = walletAddress.first.address;
    } else if (addresses.length == 1) {
      address = addresses.first;
    } else {
      if (!mounted) {
        return null;
      }
      final navigationService = injector.get<NavigationService>();
      address = await navigationService.navigateTo(
        AppRouter.postcardSelectAddressScreen,
        arguments: {
          'blockchain': 'Tezos',
          'onConfirm': (String address) async {
            navigationService.goBack(result: address);
          },
          'withLinked': false,
        },
      );
    }
    return address;
  }

  Future<AssetToken?> _receivePostcard(
      BuildContext context, AssetToken asset) async {
    AssetToken? pendingToken;
    final address = await _getAddress(asset.blockchain);
    if (address != null) {
      pendingToken = postcardService.getPendingTokenAfterClaimShare(
        address: address,
        assetToken: asset,
      );
      if (!context.mounted) {
        return null;
      }
      unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homePage,
        (route) => false,
      ));
      unawaited(Navigator.of(context).pushNamed(AppRouter.designStamp,
          arguments:
              DesignStampPayload(pendingToken, false, widget.shareCode)));
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

  factory ReceivePostcardResponse.fromJson(Map<String, dynamic> json) =>
      ReceivePostcardResponse(
        json['tokenID'],
        json['imageCID'],
        json['blockchain'],
        json['owner'],
        json['contractAddress'],
      );

  Map<String, dynamic> toJson() => {
        'tokenID': tokenID,
        'imageCID': imageCID,
        'blockchain': blockchain,
        'owner': owner,
        'contractAddress': contractAddress,
      };
}
