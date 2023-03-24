import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_bloc.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_select_account_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
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
  final bloc = injector.get<ReceivePostcardBloc>();

  @override
  void initState() {
    _fetchIdentities();
    super.initState();
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
          final artworkThumbnail = asset.thumbnailURL!;
          final theme = Theme.of(context);
          final padding =
              ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
          return Scaffold(
            backgroundColor: theme.colorScheme.primary,
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
                          FittedBox(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: Transform.translate(
                                offset: const Offset(1, 0),
                                child: Container(
                                  color: theme.auQuickSilver,
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 60,
                                          horizontal: 15,
                                        ),
                                        child: Container(
                                          color: Colors.black,
                                          child: CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            imageUrl: artworkThumbnail,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                    context, AppRouter.postcardDetailPage,
                                    arguments: asset);
                              },
                            ),
                          ),
                          Padding(
                            padding: padding.copyWith(top: 15, bottom: 15),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      child: Text(
                                        asset.title ?? "",
                                        style: theme.textTheme.ppMori400White14,
                                      ),
                                      onTap: () {},
                                    ),
                                    BlocConsumer<IdentityBloc, IdentityState>(
                                        listener: (context, state) {},
                                        builder: (context, state) {
                                          final artistName = asset.artistName
                                              ?.toIdentityOrMask(
                                                  state.identityMap);
                                          return Text(
                                            "by $artistName",
                                            style: theme
                                                .textTheme.ppMori400White14,
                                          );
                                        }),
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
                            child: BlocConsumer<IdentityBloc, IdentityState>(
                                listener: (context, state) {},
                                builder: (context, state) {
                                  return Text(
                                    "you_have_received".tr(namedArgs: {
                                      "address": asset.lastOwner
                                              .toIdentityOrMask({}) ??
                                          "Unknow"
                                    }),
                                    style: theme.textTheme.ppMori400White14,
                                  );
                                }),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Padding(
                            padding: padding,
                            child: PrimaryButton(
                              text: "accept_postcard".tr(),
                              enabled: !(state.isReceiving ?? false),
                              isProcessing: state.isReceiving ?? false,
                              onTap: () async {
                                final isReceived =
                                    await injector<PostcardService>()
                                        .isReceived(asset.tokenId ?? "");
                                if (isReceived) {
                                  if (!mounted) return;
                                  await UIHelper.showAlreadyDelivered(context);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  return;
                                }

                                //bloc.add(GetLocationEvent());
                                Position? location;
                                final permissions =
                                    await checkLocationPermissions();
                                if (!permissions) {
                                  if (!mounted) return;
                                  await UIHelper.showDeclinedGeolocalization(
                                      context);
                                  return;
                                } else {
                                  try {
                                    location = await getGeoLocation(
                                        timeout: const Duration(seconds: 2));
                                  } catch (e) {
                                    if (!mounted) return;
                                    await UIHelper.showWeakGPSSignal(context);
                                    return;
                                  }
                                }

                                final blockchain = asset.blockchain;
                                final accountService =
                                    injector<AccountService>();
                                final addresses = await accountService
                                    .getAddress(asset.blockchain);
                                String? address;
                                if (addresses.isEmpty) {
                                  final defaultAccount =
                                      await accountService.getDefaultAccount();
                                  address = blockchain == CryptoType.XTZ.source
                                      ? await defaultAccount.getTezosAddress()
                                      : await defaultAccount
                                          .getETHEip55Address();
                                } else if (addresses.length == 1) {
                                  address = addresses.first;
                                } else {
                                  if (!mounted) return;
                                  final response =
                                      await Navigator.of(context).pushNamed(
                                    AppRouter.receivePostcardSelectAccountPage,
                                    arguments:
                                        ReceivePostcardSelectAccountPageArgs(
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
                                    final response =
                                        await injector<PostcardService>()
                                            .receivePostcard(
                                                shareCode: widget.shareCode,
                                                location: location,
                                                address: address);
                                    final tokenID = response.id;

                                    final pendingToken = AssetToken(
                                      asset: Asset.init(
                                        indexID: tokenID,
                                        artistName: 'MoMa',
                                        maxEdition: 1,
                                        mimeType: 'image/png',
                                        title: 'Postcard 001',
                                        thumbnailURL: "",
                                        previewURL: "",
                                        source: 'postcard',
                                      ),
                                      blockchain: "tezos",
                                      fungible: false,
                                      contractType: '',
                                      tokenId: response.id,
                                      contractAddress: "",
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

                                    await injector<TokensService>()
                                        .setCustomTokens([pendingToken]);
                                    if (!mounted) return;
                                    await UIHelper.showReceivePostcardSuccess(
                                        context);
                                    if (!mounted) return;
                                  } catch (e) {
                                    if (e is DioError) {
                                      if (!mounted) return;
                                      await UIHelper.showReceivePostcardFailed(
                                        context,
                                        e,
                                      );
                                      // emit(state.copyWith(isReceiving: false, error: e));
                                    }
                                  }
                                }
                                if (mounted) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRouter.homePage,
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Padding(
                            padding: padding,
                            child: Text(
                              "accept_ownership_desc".tr(),
                              style: theme.primaryTextTheme.ppMori400White14,
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Padding(
                            padding: padding,
                            child: RichText(
                              text: TextSpan(
                                text: "airdrop_accept_privacy_policy".tr(),
                                style: theme.textTheme.ppMori400Grey12,
                                children: [
                                  TextSpan(
                                      text: "airdrop_privacy_policy".tr(),
                                      style: makeLinkStyle(
                                        theme.textTheme.ppMori400Grey12,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {}),
                                  TextSpan(
                                    text: ".",
                                    style: theme.primaryTextTheme.bodyLarge
                                        ?.copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: padding,
                    child: OutlineButton(
                      text: "decline".tr(),
                      enabled: !(state.isReceiving ?? false),
                      color: theme.colorScheme.primary,
                      onTap: () {
                        memoryValues.airdropFFExhibitionId.value = null;
                        Navigator.of(context).pop(false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        listener: (context, state) {});
  }
}

class ReceivePostcardResponse {
  final String id;
  final String owner;
  final String txRequestID;
  final String txRequest;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReceivePostcardResponse(this.id, this.owner, this.txRequestID, this.txRequest,
      this.createdAt, this.updatedAt);

  factory ReceivePostcardResponse.fromJson(Map<String, dynamic> json) {
    return ReceivePostcardResponse(
      json['id'],
      json['Owner'],
      json['txRequestID'],
      json['TxRequest'],
      DateTime.parse(json['CreatedAt']),
      DateTime.parse(json['UpdatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner,
        'txRequestID': txRequestID,
        'txRequest': txRequest,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
