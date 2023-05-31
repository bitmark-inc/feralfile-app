//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:dio/dio.dart';
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
  Timer? timer;
  bool isUpdating = false;

  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;
  final _metricClient = injector.get<MetricClientService>();
  final _configurationService = injector<ConfigurationService>();
  final _postcardService = injector<PostcardService>();

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
    context.read<PostcardDetailBloc>().add(PostcardDetailGetInfoEvent(
        widget.payload.identities[widget.payload.currentIndex]));
    context.read<AccountsBloc>().add(FetchAllAddressesEvent());
    context.read<AccountsBloc>().add(GetAccountsEvent());
    withSharing = widget.payload.twitterCaption != null;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _metricClient.timerEvent(
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
    final caption = widget.payload.twitterCaption ?? token.twitterCaption;
    SocialShare.checkInstalledAppsForShare().then((data) {
      if (data?[SocialApp.twitter]) {
        SocialShare.shareTwitter(caption, url: url);
      } else {
        _manualShare(caption, url);
      }
    });
    _metricClient.addEvent(MixpanelEvent.share, data: {
      "id": token.id,
      "to": "Twitter",
      "caption": caption,
      "title": token.title,
      "artistID": token.artistID,
    });
  }

  Future<void> _youDidIt(BuildContext context, AssetToken asset) async {
    final listTravelInfo =
        asset.postcardMetadata.listTravelInfoWithoutLocationName;
    final totalDistance = listTravelInfo.totalDistance;
    final theme = Theme.of(context);
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "your_postcard_completed".tr(namedArgs: {
            'distance': distanceFormatter.format(
                distance: totalDistance, withFullName: true),
          }),
          style: theme.textTheme.moMASans400Grey14,
        ),
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
    _configurationService.setListPostcardAlreadyShowYouDidIt(
        [AlreadyShowYouDidItPostcard(id: asset.id, owner: asset.owner)]);
    return UIHelper.showDialogWithConfetti(context, "you_did_it".tr(), content);
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
    _metricClient.addEvent(
      MixpanelEvent.stayInArtworkDetail,
      data: {
        "id": artworkId,
      },
    );
    _scrollController.dispose();
    timer?.cancel();
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
    return BlocConsumer<PostcardDetailBloc, PostcardDetailState>(
        listenWhen: (previous, current) {
      if (previous.assetToken?.postcardMetadata.isCompleted != true &&
              current.assetToken?.postcardMetadata.isCompleted == true ||
          current.assetToken?.isAlreadyShowYouDidIt == false) {
        _youDidIt(context, current.assetToken!);
      }
      return true;
    }, listener: (context, state) async {
      final identitiesList = state.provenances.map((e) => e.owner).toList();
      if (state.assetToken?.artistName != null &&
          state.assetToken!.artistName!.length > 20) {
        identitiesList.add(state.assetToken!.artistName!);
      }
      if (state.assetToken?.artists != null) {
        identitiesList.addAll(state.assetToken!.getArtists.map((e) => e.name));
      }
      setState(() {
        currentAsset = state.assetToken;
      });
      if (!mounted) return;
      if (state.assetToken != null) {
        if (withSharing) {
          _socialShare(context, state.assetToken!);
          setState(() {
            withSharing = false;
          });
        }

        if (state.isPostcardUpdating) {
          const duration = Duration(seconds: 10);
          timer?.cancel();
          timer = Timer.periodic(duration, (timer) {
            if (mounted) {
              _refreshPostcard();
            }
          });
        } else {
          timer?.cancel();
        }
      }

      context.read<IdentityBloc>().add(GetIdentityEvent(identitiesList));
    }, builder: (context, state) {
      if (state.assetToken != null) {
        context
            .read<TravelInfoBloc>()
            .add(GetTravelInfoEvent(asset: state.assetToken!));

        final identityState = context.watch<IdentityBloc>().state;
        final asset = state.assetToken!;

        final artistNames = asset.getArtists
            .map((e) => e.name)
            .map((e) => e.toIdentityOrMask(identityState.identityMap))
            .toList();
        return Stack(
          children: [
            Scaffold(
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                actions: [
                  Semantics(
                    label: 'chat',
                    child: IconButton(
                      onPressed: () async {
                        final wallet = await asset.getOwnerWallet();
                        if (wallet == null || !mounted) return;
                        Navigator.of(context).pushNamed(
                          ChatThreadPage.tag,
                          arguments: ChatThreadPagePayload(
                              tokenId: asset.id,
                              wallet: wallet.first,
                              address: asset.owner,
                              index: wallet.second,
                              cryptoType: asset.blockchain == "ethereum"
                                  ? CryptoType.ETH
                                  : CryptoType.XTZ,
                              name: asset.title ?? ''),
                        );
                      },
                      constraints: const BoxConstraints(
                        maxWidth: 44,
                        maxHeight: 44,
                      ),
                      icon: SvgPicture.asset(
                        'assets/images/icon_chat.svg',
                        width: 22,
                        color: AppColor.white,
                      ),
                    ),
                  ),
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
                    child: Padding(
                      padding: ResponsiveLayout.getPadding,
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
                              child: Stack(
                                children: [
                                  PostcardRatio(
                                    key: ValueKey(state.imagePath),
                                    assetToken: state.assetToken!,
                                    imagePath: state.imagePath,
                                    jsonPath: state.metadataPath,
                                  ),
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          AppRouter.artworkPreviewPage,
                                          arguments: widget.payload,
                                        );
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _postcardAction(state),
                            const SizedBox(
                              height: 10,
                            ),
                            _postcardInfo(state),
                            _artworkInfo(asset, state.toArtworkDetailState(),
                                artistNames),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      } else {
        return const SizedBox();
      }
    });
  }

  void _refreshPostcard() {
    log.info("Refresh postcard");
    context.read<PostcardDetailBloc>().add(PostcardDetailGetInfoEvent(
          widget.payload.identities[widget.payload.currentIndex],
          useIndexer: true,
        ));
  }

  Widget _postcardAction(PostcardDetailState state) {
    final asset = state.assetToken!;
    if (asset.postcardMetadata.isCompleted || !state.isLastOwner) {
      return const SizedBox();
    }
    if (state.isPostcardUpdating) {
      return PostcardButton(
        text: "updating_token".tr(),
        enabled: false,
      );
    }
    if (!state.isStamped) {
      return PostcardButton(
        text: "stamp_postcard".tr(),
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.postcardExplain,
              arguments: PostcardExplainPayload(asset));
        },
      );
    }
    if (!state.isSending()) {
      timer?.cancel();
      return PostcardButton(
        text: "invite_to_collaborate".tr(),
        onTap: () async {
          await _sharePostcard(asset);
          setState(() {});
        },
      );
    }

    return const SizedBox();
  }

  Future<void> _sharePostcard(AssetToken asset) async {
    try {
      final sharePostcardResponse = await _postcardService.sharePostcard(asset);
      if (sharePostcardResponse.deeplink?.isNotEmpty ?? false) {
        final shareMessage = "postcard_share_message".tr(namedArgs: {
          'deeplink': sharePostcardResponse.deeplink!,
        });
        Share.share(shareMessage);
      }
      _configurationService
          .updateSharedPostcard([SharedPostcard(asset.id, asset.owner)]);
    } catch (e) {
      if (e is DioError) {
        if (mounted) {
          UIHelper.showSharePostcardFailed(context, e);
        }
      }
    }
  }

  Widget _postcardInfo(PostcardDetailState state) {
    return Container(
      color: AppColor.white,
      child: Column(
        children: [
          //TODO: remove IF
          if (!viewJourney) _tabBar(),
          const SizedBox(
            height: 10,
          ),
          viewJourney ? _travelInfoWidget(state) : _leaderboard(state),
        ],
      ),
    );
  }

  Widget _artworkInfo(
      AssetToken asset, ArtworkDetailState state, List<String?> artistNames) {
    final theme = Theme.of(context);
    final editionSubTitle = getEditionSubTitle(asset);
    return Column(
      children: [
        const SizedBox(height: 20),
        Visibility(
          visible: editionSubTitle.isNotEmpty,
          child: Text(
            editionSubTitle,
            style: theme.textTheme.ppMori400Grey14,
          ),
        ),
        debugInfoWidget(context, currentAsset),
        const SizedBox(height: 16.0),
        Column(
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
            postcardDetailsMetadataSection(context, asset, artistNames),
            if (asset.fungible == true) ...[
              BlocBuilder<AccountsBloc, AccountsState>(
                builder: (context, state) {
                  final addresses = state.addresses;
                  return postcardOwnership(context, asset, addresses);
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
        )
      ],
    );
  }

  Widget _tabBar() {
    return Row(
      children: [
        _tab("journey".tr(), viewJourney),
        _tab("leaderboard".tr(), !viewJourney),
      ],
    );
  }

  Widget _tab(String text, bool isSelected) {
    const activeBackground = Color.fromRGBO(240, 148, 62, 1);
    return Expanded(
        child: PostcardButton(
            color: isSelected ? activeBackground : AppColor.auGreyBackground,
            textColor: isSelected ? null : AppColor.white,
            text: text,
            onTap: () {
              if (!isSelected) {
                setState(() {
                  viewJourney = !viewJourney;
                });
              }
            }));
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
    return _configurationService
        .getTempStorageHiddenTokenIDs()
        .contains(token.id);
  }

  Future _showArtworkOptionsDialog(AssetToken asset) async {
    if (!mounted) return;
    final isHidden = _isHidden(asset);
    UIHelper.showDrawerAction(
      context,
      options: [
        OptionItem(
          title: isHidden ? 'unhide_aw'.tr() : 'hide_aw'.tr(),
          icon: const Icon(AuIcon.hidden_artwork),
          onTap: () async {
            await _configurationService
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
        OptionItem(
          title: 'share_on_'.tr(),
          icon: SvgPicture.asset(
            'assets/images/Share.svg',
            width: 24,
            height: 24,
          ),
          onTap: () async {
            _shareTwitter(asset);
            Navigator.of(context).pop();
          },
        ),
        OptionItem(
          title: 'report_nft_rendering_issues'.tr(),
          icon: const Icon(AuIcon.help_us),
          onTap: () => showReportIssueDialog(context, asset),
        ),
      ],
    );
  }

  Widget _travelInfoWidget(PostcardDetailState postcardDetailState) {
    final theme = Theme.of(context);
    final asset = postcardDetailState.assetToken;
    return BlocConsumer<TravelInfoBloc, TravelInfoState>(
      listener: (context, state) {},
      builder: (context, state) {
        final travelInfo = state.listTravelInfo;

        if (travelInfo == null) {
          return const SizedBox();
        }
        return Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // travel distance row
              Row(
                children: [
                  Text(
                    "total_distance_traveled".tr(),
                    style: theme.textTheme.moMASans700Black14,
                  ),
                  const Spacer(),
                  Text(
                    distanceFormatter.format(
                        distance: travelInfo.totalDistance),
                    style: theme.textTheme.moMASans700Black14,
                  ),
                ],
              ),
              addDivider(height: 30, color: AppColor.auGreyBackground),
              if (postcardDetailState.canDoAction)
                if (postcardDetailState.isSending())
                  _sendingTripItem(context, asset!, travelInfo)
                else
                  _notSentItem(travelInfo),

              ...travelInfo.reversed.map((TravelInfo e) {
                if (e.to == null) {
                  if (postcardDetailState.isSending() &&
                      postcardDetailState.isLastOwner) {
                    return _sendingTripItem(context, asset!, travelInfo);
                  }
                  return _completeTravelWidget(e);
                }
                return _travelWidget(e);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _travelWidget(TravelInfo travelInfo) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatter.format(travelInfo.index),
                    style: theme.textTheme.moMASans400Black12
                        .copyWith(color: AppColor.auQuickSilver)),
                AutoSizeText(
                  travelInfo.sentLocation ?? "",
                  style: theme.textTheme.moMASans400Black14,
                  maxLines: 2,
                  minFontSize: 14,
                ),
                Row(
                  children: [
                    SvgPicture.asset(
                      "assets/images/arrow_3.svg",
                      color: AppColor.primaryBlack,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AutoSizeText(
                        travelInfo.receivedLocation ?? "Not sent",
                        style: theme.textTheme.moMASans400Black14,
                        maxLines: 2,
                        minFontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            distanceFormatter.format(distance: travelInfo.getDistance()),
            style: theme.textTheme.moMASans400Black12
                .copyWith(color: const Color.fromRGBO(131, 79, 196, 1)),
          ),
        ]),
        addDivider(height: 30, color: AppColor.auGreyBackground),
      ],
    );
  }

  Widget _completeTravelWidget(TravelInfo travelInfo) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatter.format(travelInfo.index),
                style: theme.textTheme.moMASans400Black12
                    .copyWith(color: AppColor.auQuickSilver)),
            Text(
              travelInfo.sentLocation ?? "",
              style: theme.textTheme.moMASans400Black14,
            ),
            addDivider(height: 30, color: AppColor.auGreyBackground),
          ],
        ),
      ],
    );
  }

  Widget _sendingTripItem(
      BuildContext context, AssetToken asset, List<TravelInfo> travelInfo) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");
    final sendingTrip = travelInfo.sendingTravelInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatter.format(sendingTrip.index),
          style: theme.textTheme.moMASans400Grey12,
        ),
        Row(
          children: [
            Text(
              sendingTrip.sentLocation ?? "",
              style: theme.textTheme.moMASans400Black14,
            ),
          ],
        ),
        Row(
          children: [
            SvgPicture.asset(
              "assets/images/arrow_3.svg",
              color: AppColor.primaryBlack,
            ),
            const SizedBox(width: 6),
            Text(
              "waiting_for_recipient".tr(),
              style: theme.textTheme.moMASans400Black14
                  .copyWith(color: AppColor.auQuickSilver),
            ),
            const Spacer(),
            OutlineButton(
              text: "share".tr(),
              color: AppColor.auSuperTeal,
              textColor: AppColor.primaryBlack,
              padding: const EdgeInsets.symmetric(vertical: 4),
              onTap: () {
                _sharePostcard(asset);
              },
            ),
          ],
        ),
        addDivider(height: 30, color: AppColor.auGreyBackground),
      ],
    );
  }

  Widget _notSentItem(List<TravelInfo> listTravelInfo) {
    final notSentTravelInfo = listTravelInfo.notSentTravelInfo;
    return _travelWidget(notSentTravelInfo);
  }

  Widget _leaderboard(PostcardDetailState state) {
    return const Text("Here is leader board");
  }
}

class AlreadyShowYouDidItPostcard {
  String id;
  String owner;

  AlreadyShowYouDidItPostcard({required this.id, required this.owner});

  static AlreadyShowYouDidItPostcard fromJson(Map<String, dynamic> json) {
    return AlreadyShowYouDidItPostcard(
      id: json['id'],
      owner: json['owner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "owner": owner,
    };
  }
}
