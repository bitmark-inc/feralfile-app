import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_bloc.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_select_account_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/how_it_works_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
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
  final bloc = injector.get<ReceivePostcardBloc>();
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
    return BlocConsumer<ReceivePostcardBloc, ReceivePostcardState>(
        bloc: bloc,
        builder: (context, state) {
          final asset = widget.asset;
          final theme = Theme.of(context);
          final padding =
              ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
          return Scaffold(
            backgroundColor: theme.colorScheme.primary,
            appBar: AppBar(
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              toolbarHeight: 0,
            ),
            body: Container(
              padding: ResponsiveLayout.pageEdgeInsetsWithSubmitButton
                  .copyWith(left: 0, right: 0, top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                        NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overScroll) {
                        overScroll.disallowIndicator();
                        return false;
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(0),
                        shrinkWrap: true,
                        children: [
                          const SizedBox(
                            height: 24,
                          ),
                          Container(
                            color: theme.auQuickSilver,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 60,
                                    horizontal: 15,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 355 / 265,
                                    child: Stack(
                                      children: [
                                        PostcardViewWidget(
                                          assetToken: asset,
                                        ),
                                        Positioned.fill(
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(context,
                                                  AppRouter.postcardDetailPage,
                                                  arguments: asset);
                                            },
                                            child: Container(
                                              color: Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: padding.copyWith(top: 15, bottom: 15),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "moma_postcard_project_".tr(),
                                      style: theme.textTheme.ppMori400White14,
                                    ),
                                    Text(
                                      asset.title ?? "",
                                      style: theme.textTheme.ppMori400White14,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                SvgPicture.asset(
                                  "assets/images/penrose_moma.svg",
                                  color: theme.colorScheme.secondary,
                                  width: 27,
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Padding(
                            padding: padding,
                            child: HowItWorksView(
                                counter: asset.postcardMetadata.counter),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      color: Colors.transparent,
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          OutlineButton(
                            text: "cancel".tr(),
                            color: theme.colorScheme.primary,
                            onTap: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Expanded(
                              child: PrimaryButton(
                            text: "accept_postcard".tr(),
                            enabled: !(_isProcessing),
                            isProcessing: _isProcessing,
                            onTap: () async {
                              setState(() {
                                _isProcessing = true;
                              });
                              await _receivePostcard(asset);
                            },
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        listener: (context, state) {});
  }

  Future<void> _receivePostcard(AssetToken asset) async {
    final isReceived =
        await injector<PostcardService>().isReceived(asset.tokenId ?? "");
    if (isReceived) {
      if (!mounted) return;
      await UIHelper.showAlreadyDelivered(context);
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    //bloc.add(GetLocationEvent());
    Position? location;
    final permissions = await checkLocationPermissions();
    if (!permissions) {
      if (!mounted) return;
      await UIHelper.showDeclinedGeolocalization(context);
      setState(() {
        _isProcessing = false;
      });
      return;
    } else {
      try {
        location = await getGeoLocation(timeout: const Duration(seconds: 2));
      } catch (e) {
        if (!mounted) return;
        await UIHelper.showWeakGPSSignal(context);
        setState(() {
          _isProcessing = false;
        });
        return;
      }
    }

    final blockchain = asset.blockchain;
    final accountService = injector<AccountService>();
    final addresses = await accountService.getAddress(asset.blockchain);
    String? address;
    if (addresses.isEmpty) {
      final defaultAccount = await accountService.getDefaultAccount();
      address = blockchain == CryptoType.XTZ.source
          ? await defaultAccount.getTezosAddress()
          : await defaultAccount.getETHEip55Address();
    } else if (addresses.length == 1) {
      address = addresses.first;
    } else {
      if (!mounted) return;
      final response = await Navigator.of(context).pushNamed(
        AppRouter.receivePostcardSelectAccountPage,
        arguments: ReceivePostcardSelectAccountPageArgs(
          blockchain,
        ),
      );
      address = response as String?;
    }
    if (address != null) {
      // bloc.add(AcceptPostcardEvent(
      //   address,
      //   widget.sharedCode,
      //   location,
      // ));
      try {
        final response = await injector<PostcardService>().receivePostcard(
            shareCode: widget.shareCode, location: location, address: address);
        var postcardMetadata = asset.postcardMetadata;
        postcardMetadata.locationInformation.add(UserLocations(
            claimedLocation:
                Location(lat: location.latitude, lon: location.longitude)));
        var newAsset = asset.asset;
        newAsset?.artworkMetadata = jsonEncode(postcardMetadata.toJson());
        final pendingToken =
            asset.copyWith(owner: response.owner, asset: newAsset, balance: 1);

        final tokenService = injector<TokensService>();
        await tokenService.setCustomTokens([pendingToken]);
        await tokenService.reindexAddresses([address]);
        NftCollectionBloc.eventController.add(
          GetTokensByOwnerEvent(pageKey: PageKey.init()),
        );
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.homePage,
          (route) => false,
        );
        Navigator.of(context)
            .pushNamed(AppRouter.postcardStartedPage, arguments: pendingToken);
      } catch (e) {
        if (e is DioError) {
          if (!mounted) return;
          await UIHelper.showReceivePostcardFailed(
            context,
            e,
          );
          if (!mounted) return;
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
