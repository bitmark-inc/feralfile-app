import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_select_account_page.dart';
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
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nft_collection/models/asset_token.dart';

class ReceivePostcardPageArgs {
  final AssetToken asset;
  final String sharedId;
  final int counter;

  ReceivePostcardPageArgs(
      {required this.asset, required this.sharedId, required this.counter});
}

class ReceivePostCardPage extends StatefulWidget {
  final AssetToken asset;
  final String sharedId;
  final int counter;

  const ReceivePostCardPage({
    Key? key,
    required this.asset,
    required this.sharedId,
    required this.counter,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ReceivePostCardPageState();
  }
}

class _ReceivePostCardPageState extends State<ReceivePostCardPage> {
  bool _processing = false;
  final metricClient = injector.get<MetricClientService>();

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
    final asset = widget.asset;
    final artworkThumbnail = asset.thumbnailURL!;
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Container(
        padding: ResponsiveLayout.pageEdgeInsetsWithSubmitButton
            .copyWith(left: 0, right: 0, top: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NotificationListener<OverscrollIndicatorNotification>(
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
                                        ?.toIdentityOrMask(state.identityMap);
                                    return Text(
                                      "by $artistName",
                                      style: theme.textTheme.ppMori400White14,
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
                                "address":
                                    asset.lastOwner.toIdentityOrMask({}) ??
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
                        enabled: !_processing,
                        isProcessing: _processing,
                        onTap: () async {
                          setState(() {
                            _processing = true;
                          });
                          final isReceived = await injector<PostcardService>()
                              .isReceived(asset.tokenId ?? "");
                          if (isReceived) {
                            if (!mounted) return;
                            await UIHelper.showAlreadyDelivered(context);
                            if (!mounted) return;
                            Navigator.pop(context);
                            return;
                          }
                          Position? location;
                          final permissions = await checkLocationPermissions();
                          if (!permissions) {
                            if (!mounted) return;
                            await UIHelper.showDeclinedGeolocalization(context);
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
                          final accountService = injector<AccountService>();
                          final addresses =
                              await accountService.getAddress(asset.blockchain);
                          String? address;
                          if (addresses.isEmpty) {
                            final defaultAccount =
                                await accountService.getDefaultAccount();
                            address = blockchain == CryptoType.XTZ.source
                                ? await defaultAccount.getTezosAddress()
                                : await defaultAccount.getETHEip55Address();
                          } else if (addresses.length == 1) {
                            address = addresses.first;
                          } else {
                            if (!mounted) return;
                            await Navigator.of(context).pushNamed(
                              AppRouter.receivePostcardSelectAccountPage,
                              arguments: ReceivePostcardSelectAccountPageArgs(
                                  blockchain, asset, location),
                            );
                            return;
                          }
                          if (address != null && location != null && mounted) {
                            _receivePostcard(context, "", address, location);
                          } else {
                            setState(() {
                              _processing = false;
                            });
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
                enabled: !_processing,
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
  }

  Future _receivePostcard(BuildContext context, String shareId,
      String receiveAddress, Position location) async {
    final postcardService = injector<PostcardService>();
    postcardService.receivePostcard(
        shareId: shareId, location: location, address: receiveAddress);
    await UIHelper.showReceivePostcardSuccess(context);
    setState(() {
      _processing = false;
    });
    if (mounted) {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homePage,
        (route) => false,
      );
    }
  }
}
