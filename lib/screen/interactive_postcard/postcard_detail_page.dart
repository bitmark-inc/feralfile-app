//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/position_utils.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:share/share.dart';
import 'package:social_share/social_share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class ClaimedPostcardDetailPage extends StatefulWidget {
  final ArtworkDetailPayload payload;

  const ClaimedPostcardDetailPage({Key? key, required this.payload})
      : super(key: key);

  @override
  State<ClaimedPostcardDetailPage> createState() =>
      _ClaimedPostcardDetailPageState();
}

class _ClaimedPostcardDetailPageState extends State<ClaimedPostcardDetailPage>
    with AfterLayoutMixin<ClaimedPostcardDetailPage> {
  late ScrollController _scrollController;
  late bool withSharing;

  late Locale locale;
  late DistanceFormatter distanceFormatter;
  bool viewJourney = true;
  PostcardMetadata? postcardMetadata;
  List<TravelInfo> travelInfo = [];

  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;
  final metricClient = injector.get<MetricClientService>();

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
    context.read<ArtworkDetailBloc>().add(ArtworkDetailGetInfoEvent(
        widget.payload.identities[widget.payload.currentIndex]));
    context.read<AccountsBloc>().add(FetchAllAddressesEvent());
    context.read<AccountsBloc>().add(GetAccountsEvent());
    withSharing = widget.payload.twitterCaption != null;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final metricClient = injector.get<MetricClientService>();
    metricClient.timerEvent(
      MixpanelEvent.stayInArtworkDetail,
    );
  }

  void _manualShare(String caption, String url) async {
    final encodeCaption = Uri.encodeQueryComponent(caption);
    final twitterUrl =
        "${SocialApp.twitterPrefix}?url=$url&text=$encodeCaption";
    final twitterUri = Uri.parse(twitterUrl);
    launchUrl(twitterUri, mode: LaunchMode.externalApplication);
  }

  void _shareTwitter(AssetToken token) {
    final prefix = Environment.tokenWebviewPrefix;
    final url = '$prefix/token/${token.id}';
    final caption = widget.payload.twitterCaption ?? "";
    SocialShare.checkInstalledAppsForShare().then((data) {
      if (data?[SocialApp.twitter]) {
        SocialShare.shareTwitter(caption, url: url);
      } else {
        _manualShare(caption, url);
      }
    });
    metricClient.addEvent(MixpanelEvent.share, data: {
      "id": token.id,
      "to": "Twitter",
      "caption": caption,
      "title": token.title,
      "artistID": token.artistID,
    });
  }

  Future<void> _socialShare(BuildContext context, AssetToken asset) {
    final theme = Theme.of(context);
    final tags = [
      'autonomy',
      'digitalartwallet',
      'NFT',
    ];
    final tagsText = tags.map((e) => '#$e').join(" ");
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "congratulations_new_NFT".tr(),
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 12),
        Text(tagsText, style: theme.textTheme.ppMori400Grey14),
        const SizedBox(height: 24),
        PrimaryButton(
          text: "share_on_".tr(),
          onTap: () {
            _shareTwitter(asset);
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 8),
        OutlineButton(
          text: "close".tr(),
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
    return UIHelper.showDialog(context, "share_the_new".tr(), content);
  }

  @override
  void dispose() {
    final artworkId =
        jsonEncode(widget.payload.identities[widget.payload.currentIndex]);
    metricClient.addEvent(
      MixpanelEvent.stayInArtworkDetail,
      data: {
        "id": artworkId,
      },
    );
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    locale = Localizations.localeOf(context);
    distanceFormatter = DistanceFormatter(locale: locale);
    final hasKeyboard = currentAsset?.medium == "software" ||
        currentAsset?.medium == "other" ||
        currentAsset?.medium == null;
    return BlocConsumer<ArtworkDetailBloc, ArtworkDetailState>(
        listener: (context, state) async {
      final identitiesList = state.provenances.map((e) => e.owner).toList();
      if (state.assetToken?.artistName != null &&
          state.assetToken!.artistName!.length > 20) {
        identitiesList.add(state.assetToken!.artistName!);
      }

      //////////
      /*
      final a = PostcardMetadata(
          lastOwner: "d",
          isStamped: false,
          locationInformation: [
            LocationInformation(
                claimedLocation: Location(lat: 16.045479, lon: 108.220218),
                stampedLocation: Location(lat: 16.045479, lon: 108.220218)),
            LocationInformation(
                claimedLocation: Location(lat: 22.980525, lon: 120.220683),
                stampedLocation: Location(lat: 22.980525, lon: 120.220683)),
            LocationInformation(
                claimedLocation: Location(lat: 42.699094, lon: -75.856003),)
          ]);

      postcardMetadata = PostcardMetadata.fromJson(a.toJson());

       */
      postcardMetadata = PostcardMetadata.fromJson(
          jsonDecode(state.assetToken!.asset!.artworkMetadata!));
      await _getTravelInfo();
      setState(() {
        currentAsset = state.assetToken;
      });
      if (!mounted) return;
      if (withSharing && state.assetToken != null) {
        _socialShare(context, state.assetToken!);
        setState(() {
          withSharing = false;
        });
      }
      context.read<IdentityBloc>().add(GetIdentityEvent(identitiesList));
    }, builder: (context, state) {
      if (state.assetToken != null) {
        final identityState = context.watch<IdentityBloc>().state;
        final asset = state.assetToken!;

        final artistName =
            asset.artistName?.toIdentityOrMask(identityState.identityMap);

        var subTitle = "";
        if (artistName != null && artistName.isNotEmpty) {
          subTitle = "by".tr(args: [artistName]);
        }

        return Scaffold(
          backgroundColor: theme.colorScheme.primary,
          resizeToAvoidBottomInset: !hasKeyboard,
          appBar: AppBar(
            leadingWidth: 0,
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.title ?? '',
                  style: theme.textTheme.ppMori400White16,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subTitle,
                  style: theme.textTheme.ppMori400White14,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              Semantics(
                label: 'artworkDotIcon',
                child: IconButton(
                  onPressed: () => _showArtworkOptionsDialog(asset),
                  constraints: const BoxConstraints(
                    maxWidth: 44,
                    maxHeight: 44,
                  ),
                  icon: SvgPicture.asset(
                    'assets/images/more_circle.svg',
                    width: 22,
                  ),
                ),
              ),
              Semantics(
                label: 'close_icon',
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(
                    maxWidth: 44,
                    maxHeight: 44,
                  ),
                  icon: Icon(
                    AuIcon.close,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
              )
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 40,
                      ),
                      Hero(
                        tag: "detail_${asset.id}",
                        child: ArtworkView(
                          payload: widget.payload,
                          token: asset,
                        ),
                      ),
                      Visibility(
                        visible: CHECK_WEB3_CONTRACT_ADDRESS
                            .contains(asset.contractAddress),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16.0, top: 40),
                            child: OutlineButton(
                              color: Colors.transparent,
                              text: "web3_glossary".tr(),
                              onTap: () {
                                Navigator.pushNamed(
                                    context, AppRouter.previewPrimerPage,
                                    arguments: asset);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Padding(
                        padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                        child: _tabBar(),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      viewJourney
                          ? travelInfoWidget()
                          : _artworkInfo(asset, state, artistName),
                    ],
                  ),
                ),
              ),
              Visibility(visible: viewJourney, child: _postcardAction(asset)),
            ],
          ),
        );
      } else {
        return const SizedBox();
      }
    });
  }

  Widget _postcardAction(AssetToken asset) {
    final isStamped = postcardMetadata?.isStamped ?? false;
    if (_canShare(asset)) {
      if (!isStamped) {
        return Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
          child: PrimaryButton(
            text: "stamp_postcard".tr(),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.postcardExplain,
                  arguments: PostcardExplainPayload(asset));
            },
          ),
        );
      } else {
        return Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
          child: PrimaryButton(
            text: "invite_to_collaborate".tr(),
            onTap: () {
              _sharePostcard(asset);
            },
          ),
        );
      }
    } else {
      return const SizedBox();
    }
  }

  Future<void> _sharePostcard(AssetToken asset) async {
    final tezosService = injector<TezosService>();
    final owner = await asset.getOwnerWallet();
    final ownerWallet = owner?.first;
    final addressIndex = owner?.second;
    if (ownerWallet == null) {
      return;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final message = Uint8List.fromList(utf8.encode(timestamp));
    final signature =
        await tezosService.signMessage(ownerWallet, addressIndex!, message);

    final sharePostcardResponse =
        await injector<PostcardService>().sharePostcard(asset, signature);
    if (sharePostcardResponse.url?.isNotEmpty ?? false) {
      Share.share(sharePostcardResponse.url!);
    }
  }

  Widget _artworkInfo(
      AssetToken asset, ArtworkDetailState state, String? artistName) {
    final theme = Theme.of(context);
    final editionSubTitle = getEditionSubTitle(asset);
    return Column(
      children: [
        const SizedBox(height: 20),
        Visibility(
          visible: editionSubTitle.isNotEmpty,
          child: Padding(
            padding: ResponsiveLayout.getPadding,
            child: Text(
              editionSubTitle,
              style: theme.textTheme.ppMori400Grey14,
            ),
          ),
        ),
        debugInfoWidget(context, currentAsset),
        const SizedBox(height: 16.0),
        Padding(
          padding: ResponsiveLayout.getPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Desc',
                child: HtmlWidget(
                  asset.description ?? "",
                  textStyle: theme.textTheme.ppMori400White14,
                ),
              ),
              const SizedBox(height: 40.0),
              artworkDetailsMetadataSection(context, asset, artistName),
              if (asset.fungible == true) ...[
                BlocBuilder<AccountsBloc, AccountsState>(
                  builder: (context, state) {
                    final addresses = state.addresses;
                    return tokenOwnership(context, asset, addresses);
                  },
                ),
              ] else ...[
                state.provenances.isNotEmpty
                    ? _provenanceView(context, state.provenances)
                    : const SizedBox()
              ],
              artworkDetailsRightSection(context, asset),
              const SizedBox(height: 80.0),
            ],
          ),
        )
      ],
    );
  }

  Widget _tabBar() {
    return Row(
      children: [
        _tab("journey".tr(), viewJourney),
        const SizedBox(width: 10),
        _tab("info".tr(), !viewJourney),
      ],
    );
  }

  Widget _tab(String text, bool isSelected) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            setState(() {
              viewJourney = !viewJourney;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  width: 2,
                  color:
                      isSelected ? AppColor.auSuperTeal : AppColor.greyMedium),
            ),
          ),
          child: Text(
            text,
            style: theme.textTheme.ppMori400White14
                .copyWith(color: isSelected ? null : AppColor.greyMedium),
          ),
        ),
      ),
    );
  }

  Widget _provenanceView(BuildContext context, List<Provenance> provenances) {
    return BlocBuilder<IdentityBloc, IdentityState>(
      builder: (context, identityState) =>
          BlocBuilder<AccountsBloc, AccountsState>(
              builder: (context, accountsState) {
        final event = accountsState.event;
        if (event != null && event is FetchAllAddressesSuccessEvent) {
          _accountNumberHash = HashSet.of(event.addresses);
        }

        return artworkDetailsProvenanceSectionNotEmpty(context, provenances,
            _accountNumberHash, identityState.identityMap);
      }),
    );
  }

  bool _isHidden(AssetToken token) {
    return injector<ConfigurationService>()
        .getTempStorageHiddenTokenIDs()
        .contains(token.id);
  }

  Future _showArtworkOptionsDialog(AssetToken asset) async {
    final owner = await asset.getOwnerWallet();
    final ownerWallet = owner?.first;
    final addressIndex = owner?.second;

    if (!mounted) return;
    final isHidden = _isHidden(asset);
    UIHelper.showDrawerAction(
      context,
      options: [
        OptionItem(
          title: isHidden ? 'unhide_aw'.tr() : 'hide_aw'.tr(),
          icon: const Icon(AuIcon.hidden_artwork),
          onTap: () async {
            await injector<ConfigurationService>()
                .updateTempStorageHiddenTokenIDs([asset.id], !isHidden);
            injector<SettingsDataService>().backup();

            if (!mounted) return;
            NftCollectionBloc.eventController.add(ReloadEvent());
            Navigator.of(context).pop();
            UIHelper.showHideArtworkResultDialog(context, !isHidden, onOK: () {
              Navigator.of(context).popUntil((route) =>
                  route.settings.name == AppRouter.homePage ||
                  route.settings.name == AppRouter.homePageNoTransition);
            });
          },
        ),
        if (ownerWallet != null) ...[
          OptionItem(
            title: "send_artwork".tr(),
            icon: const Icon(AuIcon.send),
            onTap: () async {
              final payload = await Navigator.of(context).popAndPushNamed(
                  AppRouter.sendArtworkPage,
                  arguments: SendArtworkPayload(
                      asset,
                      ownerWallet,
                      addressIndex!,
                      ownerWallet.getOwnedQuantity(asset))) as Map?;
              if (payload == null) {
                return;
              }

              final isSentAll = payload['isSentAll'] as bool;
              if (isSentAll) {
                injector<ConfigurationService>().updateRecentlySentToken(
                    [SentArtwork(asset.id, asset.owner, DateTime.now())]);
                if (isHidden) {
                  await injector<ConfigurationService>()
                      .updateTempStorageHiddenTokenIDs([asset.id], false);
                  injector<SettingsDataService>().backup();
                }
              }
              if (!mounted) return;

              if (!payload["isTezos"]) {
                if (isSentAll) {
                  Navigator.of(context).popAndPushNamed(AppRouter.homePage);
                }
                return;
              }

              final tx = payload['tx'] as TZKTOperation;

              if (!mounted) return;
              UIHelper.showMessageAction(
                context,
                'success'.tr(),
                'send_success_des'.tr(),
                onAction: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(
                    AppRouter.tezosTXDetailPage,
                    arguments: {
                      "current_address": tx.sender?.address,
                      "tx": tx,
                      "isBackHome": isSentAll,
                    },
                  );
                },
                actionButton: 'see_transaction_detail'.tr(),
                closeButton: "close".tr(),
                onClose: () => isSentAll
                    ? Navigator.of(context).popAndPushNamed(
                        AppRouter.homePage,
                      )
                    : null,
              );
            },
          ),
        ],
        OptionItem(
          title: 'report_nft_rendering_issues'.tr(),
          icon: const Icon(AuIcon.help_us),
          onTap: () => showReportIssueDialog(context, asset),
        ),
      ],
    );
  }

  bool _canShare(AssetToken asset) {
    return asset.owner == postcardMetadata!.lastOwner;
  }

  Widget travelInfoWidget() {
    final theme = Theme.of(context);
    return Padding(
      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // travel distance row
          Row(
            children: [
              Text(
                "travel_distance".tr(),
                style: theme.textTheme.ppMori700White14,
              ),
              const Spacer(),
              Text(
                distanceFormatter.format(
                    distance: _getTotalDistance(travelInfo)),
                style: theme.textTheme.ppMori700White14,
              ),
            ],
          ),
          addDivider(height: 30, color: AppColor.auGreyBackground),
          ...travelInfo.map((e) => travelWidget(e)).toList(),
        ],
      ),
    );
  }

  Widget travelWidget(TravelInfo travelInfo) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(travelInfo.index.toString(),
                  style: theme.textTheme.ppMori400White12
                      .copyWith(color: AppColor.auQuickSilver)),
              Text(
                travelInfo.sentLocation ?? "",
                style: theme.textTheme.ppMori400White14,
              ),
              Row(
                children: [
                  SvgPicture.asset("assets/images/arrow_3.svg"),
                  const SizedBox(width: 6),
                  Text(
                    travelInfo.receivedLocation ?? "",
                    style: theme.textTheme.ppMori400White14,
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            distanceFormatter.format(distance: travelInfo.getDistance()),
            style: theme.textTheme.ppMori400White14,
          ),
        ]),
        addDivider(height: 30, color: AppColor.auGreyBackground),
      ],
    );
  }

  Future<void> _getTravelInfo() async {
    final stamps = postcardMetadata!.locationInformation;

    final travelInfo = <TravelInfo>[];
    for (int i = 0; i < stamps.length - 1; i++) {
      travelInfo.add(TravelInfo(stamps[i], stamps[i + 1], i));
    }

    if (stamps[stamps.length - 1].stampedLocation != null) {
      travelInfo
          .add(TravelInfo(stamps[stamps.length - 1], null, stamps.length - 1));
    }

    await Future.wait(travelInfo.map((e) async {
      await e.getLocationName();
    }));

    if (travelInfo.length > 44) {
      travelInfo.removeLast();
    }
    setState(() {
      this.travelInfo = travelInfo;
    });
  }

  double _getTotalDistance(List<TravelInfo> travelInfos) {
    double totalDistance = 0;
    for (var travelInfo in travelInfos) {
      totalDistance += travelInfo.getDistance() ?? 0;
    }
    return totalDistance;
  }
}

class TravelInfo {
  final LocationInformation from;
  final LocationInformation? to;
  final int index;
  String? sentLocation;
  String? receivedLocation;

  TravelInfo(this.from, this.to, this.index,
      {this.sentLocation, this.receivedLocation});

  double? getDistance() {
    if (to == null) {
      return null;
    }
    return _getDistanceFromLatLonInKm(
        from.stampedLocation!.lat,
        from.stampedLocation!.lon,
        to!.claimedLocation!.lat,
        to!.claimedLocation!.lon);
  }

  // get distance from longitude and latitude
  double _getDistanceFromLatLonInKm(
      double lat1, double lon1, double lat2, double lon2) {
    var R = 6371; // Radius of the earth in km
    var dLat = deg2rad(lat2 - lat1); // deg2rad below
    var dLon = deg2rad(lon2 - lon1);
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    var d = R * c; // Distance in km
    return d;
  }

  // convert degree to radian
  double deg2rad(double deg) {
    return deg * (pi / 180);
  }

  Future<void> _getSentLocation() async {
    if (from.stampedLocation != null) {
      sentLocation = await getLocationNameFromCoordinates(
          from.stampedLocation!.lat, from.stampedLocation!.lon);
    }
  }

  Future<void> _getReceivedLocation() async {
    if (to == null) {
      receivedLocation = "not_sent".tr();
    } else {
      receivedLocation = await getLocationNameFromCoordinates(
          to!.claimedLocation!.lat, to!.claimedLocation!.lon);
    }
  }

  Future<void> getLocationName() async {
    await _getSentLocation();
    await _getReceivedLocation();
  }
}

class PostcardMetadata {
  final String lastOwner;
  final bool isStamped;
  final List<LocationInformation> locationInformation;

  //constructor
  PostcardMetadata(
      {required this.lastOwner,
      required this.isStamped,
      required this.locationInformation});

  // factory constructor
  factory PostcardMetadata.fromJson(Map<String, dynamic> json) {
    return PostcardMetadata(
      lastOwner: json['lastOwner'] as String,
      isStamped: json['isStamped'] as bool,
      locationInformation: (json['locationInformation'] as List<dynamic>)
          .map((e) => LocationInformation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'lastOwner': lastOwner,
      'isStamped': isStamped,
      'locationInformation':
          locationInformation.map((e) => e.toJson()).toList(),
    };
  }
}

class Location {
  final double lat;
  final double lon;

  // constructor
  Location({required this.lat, required this.lon});

  // factory constructor
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(lat: json['lat'] as double, lon: json['lon'] as double);
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }
}

class LocationInformation {
  final Location? claimedLocation;
  final Location? stampedLocation;

  // constructor
  LocationInformation({this.claimedLocation, this.stampedLocation});

  // factory constructor
  factory LocationInformation.fromJson(Map<String, dynamic> json) {
    return LocationInformation(
      claimedLocation: json['claimedLocation'] == null
          ? null
          : Location.fromJson(json['claimedLocation'] as Map<String, dynamic>),
      stampedLocation: json['stampedLocation'] == null
          ? null
          : Location.fromJson(json['stampedLocation'] as Map<String, dynamic>),
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'claimedLocation': claimedLocation?.toJson(),
      'stampedLocation': stampedLocation?.toJson(),
    };
  }
}
