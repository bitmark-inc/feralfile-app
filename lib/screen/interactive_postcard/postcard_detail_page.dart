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
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard_view.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_start_stamping.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/trip_detail/trip_detail_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/dot_loading_indicator.dart';
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
      ClaimedPostcardDetailPageState();
}

class ClaimedPostcardDetailPageState extends State<ClaimedPostcardDetailPage>
    with AfterLayoutMixin<ClaimedPostcardDetailPage> {
  late ScrollController _scrollController;
  late bool withSharing;

  late DistanceFormatter distanceFormatter;
  bool viewJourney = true;
  Timer? timer;
  bool isUpdating = false;
  bool canceling = false;
  NumberFormat numberFormatter = NumberFormat("00");

  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;
  bool? isViewOnly;
  final _metricClient = injector.get<MetricClientService>();
  final _configurationService = injector<ConfigurationService>();
  final _postcardService = injector<PostcardService>();
  late Timer _leaderboardTimer;
  late bool sharingPostcard;

  @override
  void initState() {
    _scrollController = ScrollController();
    sharingPostcard = false;
    super.initState();
    context.read<PostcardDetailBloc>().add(PostcardDetailGetInfoEvent(
        widget.payload.identities[widget.payload.currentIndex]));
    context.read<PostcardDetailBloc>().add(FetchLeaderboardEvent());
    context.read<AccountsBloc>().add(FetchAllAddressesEvent());
    context.read<AccountsBloc>().add(GetAccountsEvent());
    withSharing = widget.payload.twitterCaption != null;
    _setTimer();
  }

  void _setTimer() {
    _leaderboardTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      context.read<PostcardDetailBloc>().add(FetchLeaderboardEvent());
    });
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
        asset.postcardMetadata.listTravelInfoWithoutInternetUser;
    final totalDistance = listTravelInfo.totalDistance;
    final theme = Theme.of(context);
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
            text: TextSpan(children: [
          TextSpan(text: "your_postcard_has_traveled".tr()),
          TextSpan(
              text: distanceFormatter.format(
                  distance: totalDistance, withFullName: true),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: "tag_your_postcard_collaborators".tr()),
        ], style: theme.textTheme.moMASans400White14)),
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
        [PostcardIdentity(id: asset.id, owner: asset.owner)]);
    return UIHelper.showDialogWithConfetti(context, "you_did_it".tr(), content);
  }

  Future<void> _postcardUpdated(BuildContext context) async {
    await UIHelper.showPostcardUpdates(context);
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
    _leaderboardTimer.cancel();
    super.dispose();
  }

  Future<void> gotoChatThread(BuildContext context) async {
    final state = context.read<PostcardDetailBloc>().state;
    final asset = state.assetToken;
    if (asset == null) return;
    final wallet = await asset.getOwnerWallet();
    if (wallet == null) return;
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      ChatThreadPage.tag,
      arguments: ChatThreadPagePayload(
          tokenId: asset.id,
          wallet: wallet.first,
          address: asset.owner,
          index: wallet.second,
          cryptoType:
              asset.blockchain == "ethereum" ? CryptoType.ETH : CryptoType.XTZ,
          name: asset.title ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    distanceFormatter = DistanceFormatter();
    final hasKeyboard = currentAsset?.medium == "software" ||
        currentAsset?.medium == "other" ||
        currentAsset?.medium == null;
    return BlocConsumer<PostcardDetailBloc, PostcardDetailState>(
        listenWhen: (previous, current) {
      if (previous.assetToken?.postcardMetadata.isCompleted != true &&
          current.assetToken?.postcardMetadata.isCompleted == true &&
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

      if (!mounted) return;
      final assetToken = state.assetToken;
      if (assetToken != null) {
        final viewOnly = await assetToken.isViewOnly();
        if (!mounted) return;
        setState(() {
          currentAsset = state.assetToken;
          isViewOnly = viewOnly;
        });
        if (withSharing) {
          _socialShare(context, assetToken);
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

        final alreadyShowPostcardUpdate = _configurationService
            .getAlreadyShowPostcardUpdates()
            .any((element) =>
                element.id == assetToken.id &&
                element.owner == assetToken.owner);
        if (!state.isPostcardUpdating &&
            !state.isPostcardUpdatingOnBlockchain &&
            state.isStamped &&
            !alreadyShowPostcardUpdate) {
          if (_configurationService.isNotificationEnabled() != true) {
            _postcardUpdated(context);
          }
          _configurationService.setAlreadyShowPostcardUpdates(
              [PostcardIdentity(id: assetToken.id, owner: assetToken.owner)]);
        }

        if (!state.isSending()) {
          _configurationService.removeSharedPostcardWhere((element) =>
              element.tokenID == assetToken.id &&
              element.owner == assetToken.owner);
        }
      }
      if (!mounted) return;
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
                systemOverlayStyle: systemUiOverlayDarkStyle,
                leadingWidth: 0,
                centerTitle: false,
                title: ArtworkDetailsHeader(
                  title: asset.title ?? '',
                  subTitle: '',
                  hideArtist: true,
                ),
                actions: [
                  Visibility(
                    visible: isViewOnly == false,
                    child: Semantics(
                      label: 'chat',
                      child: IconButton(
                        onPressed: () async {
                          gotoChatThread(context);
                        },
                        constraints: const BoxConstraints(
                          maxWidth: 44,
                          maxHeight: 44,
                        ),
                        icon: SvgPicture.asset(
                          'assets/images/icon_chat.svg',
                          width: 22,
                          colorFilter: const ColorFilter.mode(
                              AppColor.white, BlendMode.srcIn),
                        ),
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
                              height: 30,
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
                              height: 32,
                            ),
                            _postcardInfo(context, state),
                            Align(
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
    final theme = Theme.of(context);
    if (asset.postcardMetadata.isCompleted ||
        !state.isLastOwner ||
        !state.postcardValueLoaded ||
        isViewOnly != false) {
      return const SizedBox();
    }
    if (state.isPostcardUpdatingOnBlockchain) {
      return PostcardCustomButton(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "confirming_on_blockchain".tr(),
              style: theme.textTheme.moMASans700Black14,
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: DotsLoading(),
            ),
          ],
        ),
      );
    }
    if (state.isPostcardUpdating) {
      return PostcardCustomButton(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "updating_token".tr(),
              style: theme.textTheme.moMASans700Black14,
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: DotsLoading(),
            ),
          ],
        ),
      );
    }
    if (!state.isStamped) {
      return PostcardButton(
        text: "stamp_postcard".tr(),
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.startStampingPostcardPage,
              arguments: StartStampingPostCardPagePayload(asset: asset));
        },
      );
    }
    if (!state.isSending()) {
      timer?.cancel();
      return PostcardButton(
        text: "invite_to_collaborate".tr(),
        enabled: !sharingPostcard,
        isProcessing: sharingPostcard,
        onTap: () {
          withDebounce(() async {
            await _sharePostcard(asset);
            setState(() {});
          });
        },
      );
    } else {
      return PostcardButton(
        text: "postcard_sent".tr(),
        disabledColor: const Color.fromRGBO(79, 174, 79, 1),
        enabled: false,
      );
    }
  }

  Future<void> _sharePostcard(AssetToken asset) async {
    try {
      setState(() {
        sharingPostcard = true;
      });
      final sharePostcardResponse = await _postcardService.sharePostcard(asset);
      if (sharePostcardResponse.deeplink?.isNotEmpty ?? false) {
        final shareMessage = "postcard_share_message".tr(namedArgs: {
          'deeplink': sharePostcardResponse.deeplink!,
        });
        Share.share(shareMessage);
      }
      _configurationService.updateSharedPostcard(
          [SharedPostcard(asset.id, asset.owner, DateTime.now())]);
    } catch (e) {
      if (e is DioException) {
        if (mounted) {
          UIHelper.showSharePostcardFailed(context, e);
        }
      }
    }
    setState(() {
      sharingPostcard = false;
    });
  }

  Future<void> cancelShare(AssetToken asset) async {
    try {
      await _postcardService.cancelSharePostcard(asset);
      await _configurationService.removeSharedPostcardWhere((sharedPostcard) =>
          sharedPostcard.tokenID == asset.id &&
          sharedPostcard.owner == asset.owner);
      setState(() {});
    } catch (error) {
      log.info("Cancel share postcard failed: error ${error.toString()}");
    }
  }

  Widget _postcardInfo(BuildContext context, PostcardDetailState state) {
    return Column(
      children: [
        _tabBar(context),
        const SizedBox(
          height: 24,
        ),
        Container(
          color: AppColor.white,
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: viewJourney
                ? _travelInfoWidget(state)
                : _leaderboard(context, state),
          ),
        ),
      ],
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

  Widget _tabBar(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tab(context, "journey".tr(), viewJourney)),
        const SizedBox(width: 15),
        Expanded(child: _tab(context, "leaderboard".tr(), !viewJourney)),
      ],
    );
  }

  Widget _tab(BuildContext context, String text, bool isSelected) {
    final theme = Theme.of(context);
    const selectedColor = Color.fromRGBO(247, 207, 70, 1);
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            viewJourney = !viewJourney;
          });
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: theme.textTheme.moMASans700Black12.copyWith(
                    color: isSelected ? selectedColor : AppColor.auGrey),
              ),
              const SizedBox(height: 12),
              addOnlyDivider(color: AppColor.auGrey),
            ],
          ),
          Positioned.fill(
              child: Container(
            color: Colors.transparent,
          )),
        ],
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
      ],
    );
  }

  Widget _postcardProgress(AssetToken asset) {
    final theme = Theme.of(context);
    final travelInfoWithoutInternetUser =
        asset.postcardMetadata.listTravelInfoWithoutInternetUser;
    final currentStampNumber = asset.postcardMetadata.numberOfStamp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "postcard_progress".tr(),
          style: theme.textTheme.moMASans700Black12,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            ...List.generate(MAX_STAMP_IN_POSTCARD, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    height: 25,
                    color: index < currentStampNumber
                        ? Colors.amber
                        : AppColor.auLightGrey,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
                "stamps_".tr(namedArgs: {
                  "current": numberFormatter.format(currentStampNumber),
                  "total": MAX_STAMP_IN_POSTCARD.toString(),
                }),
                style: theme.textTheme.moMASans400Black12),
            const Spacer(),
            Text(
                "total_distance".tr(namedArgs: {
                  "distance": distanceFormatter.format(
                      distance: travelInfoWithoutInternetUser.totalDistance)
                }),
                style: theme.textTheme.moMASans400Black12)
          ],
        )
      ],
    );
  }

  Widget _travelInfoWidget(PostcardDetailState postcardDetailState) {
    final asset = postcardDetailState.assetToken;
    final padding = ResponsiveLayout.pageHorizontalEdgeInsets;
    return BlocConsumer<TravelInfoBloc, TravelInfoState>(
      listener: (context, state) {},
      builder: (context, state) {
        final travelInfo = state.listTravelInfo;
        final lastTravelInfo = state.lastTravelInfo;
        if (travelInfo == null || lastTravelInfo == null) {
          return const SizedBox();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: padding,
              child: _postcardProgress(asset!),
            ),
            addDivider(color: AppColor.primaryBlack),
            Padding(
              padding: padding,
              child: Column(
                children: [
                  if (postcardDetailState.canDoAction) ...[
                    if (postcardDetailState.isSending())
                      _sendingTripItem(context, asset, lastTravelInfo)
                    else
                      _notSentItem(lastTravelInfo)
                  ],
                  ...travelInfo.reversed.map((TravelInfo e) {
                    if (e.to == null) {
                      if (postcardDetailState.isSending() &&
                          postcardDetailState.isLastOwner) {
                        return _sendingTripItem(context, asset, lastTravelInfo);
                      }
                      return _completeTravelWidget(e);
                    }
                    return _travelWidget(e, onTap: () {
                      _gotoTripDetail(context, e);
                    });
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  _gotoTripDetail(BuildContext context, TravelInfo travelInfo) {
    final travelsInfo = context.read<TravelInfoBloc>().state.listTravelInfo;
    Navigator.of(context).pushNamed(AppRouter.tripDetailPage,
        arguments: TripDetailPayload(
          stampIndex: travelInfo.index - 1,
          travelsInfo: travelsInfo!,
          assetToken: currentAsset!,
        ));
  }

  Widget _travelWidget(TravelInfo travelInfo, {Function()? onTap}) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Column(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            travelInfo.sentLocation ?? "",
                            style: theme.textTheme.moMASans400Black12,
                          ),
                          Row(
                            children: [
                              SvgPicture.asset(
                                "assets/images/arrow_3.svg",
                                colorFilter: const ColorFilter.mode(
                                    AppColor.primaryBlack, BlendMode.srcIn),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  travelInfo.receivedLocation ?? "-",
                                  style: theme.textTheme.moMASans400Black12,
                                ),
                              ),
                            ],
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
              addDivider(height: 30, color: AppColor.auLightGrey),
            ],
          ),
          Positioned.fill(
              child: Container(
            color: Colors.transparent,
          ))
        ],
      ),
    );
  }

  Widget _completeTravelWidget(TravelInfo travelInfo) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");
    return GestureDetector(
      onTap: () {
        _gotoTripDetail(context, travelInfo);
      },
      child: Stack(
        children: [
          Column(
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
                    style: theme.textTheme.moMASans400Black12,
                  ),
                  addDivider(height: 30, color: AppColor.auGreyBackground),
                ],
              ),
            ],
          ),
          Positioned.fill(
              child: Container(
            color: Colors.transparent,
          ))
        ],
      ),
    );
  }

  Widget _sendingTripItem(
      BuildContext context, AssetToken asset, TravelInfo sendingTrip) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");
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
              style: theme.textTheme.moMASans400Black12,
            ),
          ],
        ),
        Row(
          children: [
            SvgPicture.asset(
              "assets/images/arrow_3.svg",
              colorFilter: const ColorFilter.mode(
                  AppColor.primaryBlack, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Text(
              "waiting_for_recipient".tr(),
              style: theme.textTheme.moMASans400Black12
                  .copyWith(color: AppColor.auQuickSilver),
            ),
            const Spacer(),
            GestureDetector(
              child: Text(
                "cancel".tr(),
                style: theme.textTheme.moMASans400Grey12
                    .copyWith(color: const Color.fromRGBO(131, 79, 196, 1)),
              ),
              onTap: () {
                UIHelper.showDialog(context, "cancel_invitation".tr(),
                    StatefulBuilder(builder: (context, setState) {
                  return Column(
                    children: [
                      Text(
                        "cancel_invitation_desc".tr(),
                        style: Theme.of(context).textTheme.ppMori400White14,
                      ),
                      const SizedBox(height: 40),
                      PrimaryButton(
                        text: "cancel".tr(),
                        isProcessing: canceling,
                        enabled: !canceling,
                        onTap: () async {
                          setState(() {
                            canceling = true;
                          });
                          await cancelShare(asset);
                          setState(() {
                            canceling = false;
                          });
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
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
                }), isDismissible: true);
              },
            ),
          ],
        ),
        addDivider(height: 30, color: AppColor.auGreyBackground),
      ],
    );
  }

  Widget _notSentItem(TravelInfo lastTravelInfo) {
    return _travelWidget(lastTravelInfo, onTap: () {});
  }

  Widget _leaderboard(BuildContext context, PostcardDetailState state) {
    return PostcardLeaderboardView(
      leaderboard: state.leaderboard,
      assetToken: state.assetToken,
    );
  }
}

class PostcardIdentity {
  String id;
  String owner;

  PostcardIdentity({required this.id, required this.owner});

  static PostcardIdentity fromJson(Map<String, dynamic> json) {
    return PostcardIdentity(
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

class PostcardLeaderboardItem {
  String id;
  int rank;
  String title;
  double totalDistance;

  PostcardLeaderboardItem({
    required this.id,
    required this.rank,
    required this.title,
    required this.totalDistance,
  });

  static PostcardLeaderboardItem fromJson(Map<String, dynamic> json) {
    return PostcardLeaderboardItem(
      id: json['token_id'],
      rank: json['rank'],
      title: json['title'] ?? "",
      totalDistance: json['mileage'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "rank": rank,
      "title": title,
      "totalDistance": totalDistance,
    };
  }
}

class PostcardLeaderboard {
  List<PostcardLeaderboardItem> items;
  DateTime lastUpdated;

  PostcardLeaderboard({
    required this.items,
    required this.lastUpdated,
  });

  static PostcardLeaderboard fromJson(Map<String, dynamic> json) {
    return PostcardLeaderboard(
      items: json['items']
          .map<PostcardLeaderboardItem>(
              (item) => PostcardLeaderboardItem.fromJson(item))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "items": items.map((item) => item.toJson()).toList(),
      "lastUpdated": lastUpdated.toIso8601String(),
    };
  }
}
