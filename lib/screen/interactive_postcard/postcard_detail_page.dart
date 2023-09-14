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
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_start_stamping.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/trip_detail/trip_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
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
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/share_helper.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/dot_loading_indicator.dart';
import 'package:autonomy_flutter/view/external_link.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';
import 'package:share/share.dart';

class PostcardDetailPagePayload extends ArtworkDetailPayload {
  final bool isFromLeaderboard;

  PostcardDetailPagePayload(
    List<ArtworkIdentity> identities,
    int currentIndex, {
    Key? key,
    PlayControlModel? playControl,
    String? twitterCaption,
    this.isFromLeaderboard = false,
    bool useIndexer = false,
  }) : super(
          key: key,
          identities,
          currentIndex,
          playControl: playControl,
          twitterCaption: twitterCaption,
          useIndexer: useIndexer,
        );
}

class ClaimedPostcardDetailPage extends StatefulWidget {
  final PostcardDetailPagePayload payload;

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
  late bool isViewOnly;

  late DistanceFormatter distanceFormatter;
  bool viewJourney = true;
  Timer? timer;
  bool isUpdating = false;
  bool canceling = false;
  final numberFormatter = NumberFormat("00");

  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;
  final _metricClient = injector.get<MetricClientService>();
  final _configurationService = injector<ConfigurationService>();
  final _postcardService = injector<PostcardService>();
  late bool _sharingPostcard;

  @override
  void initState() {
    _scrollController = ScrollController();
    _sharingPostcard = false;
    isViewOnly = widget.payload.isFromLeaderboard;
    super.initState();
    context.read<PostcardDetailBloc>().add(
          PostcardDetailGetInfoEvent(
              widget.payload.identities[widget.payload.currentIndex],
              useIndexer: widget.payload.isFromLeaderboard ||
                  widget.payload.useIndexer),
        );
    context.read<PostcardDetailBloc>().add(FetchLeaderboardEvent());
    context.read<AccountsBloc>().add(FetchAllAddressesEvent());
    withSharing = widget.payload.twitterCaption != null;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _metricClient.timerEvent(
      MixpanelEvent.stayInArtworkDetail,
    );
  }

  void _shareTwitter(AssetToken token) {
    shareToTwitter(token: token, twitterCaption: widget.payload.twitterCaption);
  }

  Future<void> _youDidIt(BuildContext context, AssetToken asset) async {
    final listTravelInfo =
        asset.postcardMetadata.listTravelInfoWithoutLocationName;
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
          current.assetToken?.isAlreadyShowYouDidIt == false &&
          isViewOnly == false) {
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
        final viewOnly = isViewOnly || (await assetToken.isViewOnly());
        if (!mounted) return;
        setState(() {
          currentAsset = state.assetToken;
          isViewOnly = viewOnly;
        });
        if (viewOnly) {
          return;
        }
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
              backgroundColor: POSTCARD_BACKGROUND_COLOR,
              resizeToAvoidBottomInset: !hasKeyboard,
              appBar: AppBar(
                leadingWidth: 0,
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: POSTCARD_BACKGROUND_COLOR,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
                toolbarHeight: 70,
                centerTitle: false,
                title: Text(
                  asset.title!,
                  style: theme.textTheme.moMASans400Black12,
                  overflow: TextOverflow.ellipsis,
                ),
                automaticallyImplyLeading: false,
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
                              AppColor.primaryBlack, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'externalLink',
                    child: const ExternalLink(
                      color: AppColor.primaryBlack,
                      disableColor: AppColor.disabledColor,
                    ),
                  ),
                  Visibility(
                    visible: !widget.payload.isFromLeaderboard,
                    child: Semantics(
                      label: 'artworkDotIcon',
                      child: IconButton(
                        onPressed: () =>
                            _showArtworkOptionsDialog(context, asset),
                        constraints: const BoxConstraints(
                          maxWidth: 44,
                          maxHeight: 44,
                        ),
                        icon: SvgPicture.asset('assets/images/more_circle.svg',
                            width: 22,
                            colorFilter: const ColorFilter.mode(
                                AppColor.primaryBlack, BlendMode.srcIn)),
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
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  )
                ],
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
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
                            const SizedBox(
                              height: 20,
                            ),
                            if (!isViewOnly) ...[
                              _postcardAction(context, state),
                              const SizedBox(
                                height: 20,
                              ),
                            ],
                            _postcardInfo(context, state),
                            const SizedBox(
                              height: 20,
                            ),
                            _postcardLeaderboard(context, state),
                            const SizedBox(
                              height: 20,
                            ),
                            _aboutTheProject(context),
                            const SizedBox(
                              height: 20,
                            ),
                            _web3Glossary(context, asset),
                            const SizedBox(
                              height: 20,
                            ),
                            _artworkInfo(context, asset,
                                state.toArtworkDetailState(), artistNames),
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

  Widget _postcardAction(BuildContext context, PostcardDetailState state) {
    final asset = state.assetToken!;
    final theme = Theme.of(context);
    if (asset.postcardMetadata.isCompleted ||
        !state.isLastOwner ||
        !state.postcardValueLoaded ||
        isViewOnly != false) {
      return const SizedBox();
    }
    if (state.isPostcardUpdatingOnBlockchain || state.isPostcardUpdating) {
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
        enabled: !_sharingPostcard,
        isProcessing: _sharingPostcard,
        onTap: () {
          withDebounce(() async {
            await _sharePostcard(context, asset);
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

  Future<void> _sharePostcard(BuildContext context, AssetToken asset) async {
    try {
      setState(() {
        _sharingPostcard = true;
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
      _sharingPostcard = false;
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
    return PostcardContainer(
      child: _travelInfoWidget(state),
    );
  }

  Widget _postcardLeaderboard(BuildContext context, PostcardDetailState state) {
    final theme = Theme.of(context);
    final item = state.leaderboard?.items
        .firstWhereOrNull((element) => element.id == state.assetToken?.tokenId);
    return PostcardContainer(
      child: GestureDetector(
        child: Stack(
          children: [
            Row(
              children: [
                Text(
                  "leaderboard".tr(),
                  style:
                      theme.textTheme.moMASans700Black16.copyWith(fontSize: 18),
                ),
                const Spacer(),
                if (item != null)
                  Text(
                    "# ${item.rank}",
                    style: theme.textTheme.moMASans400Black12
                        .copyWith(color: MoMAColors.moMA12, fontSize: 18),
                  )
              ],
            ),
            Positioned.fill(
                child: Container(
              color: Colors.transparent,
            ))
          ],
        ),
        onTap: () {
          if (widget.payload.isFromLeaderboard) {
            Navigator.of(context).pop();
            return;
          }
          Navigator.of(context).pushNamed(AppRouter.postcardLeaderboardPage,
              arguments: PostcardLeaderboardPagePayload(
                assetToken: state.assetToken,
              ));
        },
      ),
    );
  }

  Widget _aboutTheProject(BuildContext context) {
    return Column(
      children: [
        PostcardContainer(
          child: GestureDetector(
            child: Text(
              "about_the_project".tr(),
              style: Theme.of(context)
                  .textTheme
                  .moMASans700Black16
                  .copyWith(fontSize: 18),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.inappWebviewPage,
                arguments: InAppWebViewPayload(POSTCARD_ABOUT_THE_PROJECT),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _web3Glossary(BuildContext context, AssetToken asset) {
    return Column(
      children: [
        PostcardContainer(
          child: GestureDetector(
            child: Text(
              "web3_glossary".tr(),
              style: Theme.of(context)
                  .textTheme
                  .moMASans700Black16
                  .copyWith(fontSize: 18),
            ),
            onTap: () {
              Navigator.pushNamed(context, AppRouter.previewPrimerPage,
                  arguments: asset);
            },
          ),
        ),
      ],
    );
  }

  Widget _artworkInfo(BuildContext context, AssetToken asset,
      ArtworkDetailState state, List<String?> artistNames) {
    return Column(
      children: [
        debugInfoWidget(context, currentAsset),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostcardContainer(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child:
                  postcardDetailsMetadataSection(context, asset, artistNames),
            ),
            const SizedBox(height: 20.0),
            if (asset.fungible == true) ...[
              BlocBuilder<AccountsBloc, AccountsState>(
                builder: (context, state) {
                  final addresses = state.addresses;
                  return PostcardContainer(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: widget.payload.isFromLeaderboard
                        ? leaderboardPostcardOwnership(
                            context, asset, addresses, artistNames)
                        : postcardOwnership(context, asset, addresses),
                  );
                },
              ),
            ] else ...[
              state.provenances.isNotEmpty
                  ? PostcardContainer(
                      child: _provenanceView(context, state.provenances))
                  : const SizedBox()
            ],
            const SizedBox(height: 20.0),
            PostcardContainer(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 22),
                child: artworkDetailsRightSection(context, asset)),
            const SizedBox(height: 40.0),
          ],
        )
      ],
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

  Future _showArtworkOptionsDialog(
      BuildContext context, AssetToken asset) async {
    final theme = Theme.of(context);
    if (!mounted) return;
    const isHidden = false;
    UIHelper.showPostcardDrawerAction(
      context,
      options: [
        OptionItem(
          title: 'share_on_'.tr(),
          icon: SvgPicture.asset(
            'assets/images/globe.svg',
            width: 24,
            height: 24,
          ),
          iconOnProcessing: SvgPicture.asset(
            'assets/images/globe.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColor.disabledColor,
              BlendMode.srcIn,
            ),
          ),
          onTap: () {
            _shareTwitter(asset);
            Navigator.of(context).pop();
          },
        ),
        if (asset.stampIndex >= 0)
          OptionItem(
            title: 'download_stamp'.tr(),
            icon: SvgPicture.asset(
              'assets/images/download.svg',
              width: 24,
              height: 24,
            ),
            iconOnProcessing: SvgPicture.asset('assets/images/download.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                    AppColor.disabledColor, BlendMode.srcIn)),
            onTap: () async {
              try {
                await _postcardService.downloadStamp(
                    tokenId: asset.tokenId!, stampIndex: asset.stampIndex);
                if (!mounted) return;
                Navigator.of(context).pop();
                await UIHelper.showPostcardStampSaved(context);
              } catch (e) {
                log.info("Download stamp failed: error ${e.toString()}");
                if (!mounted) return;
                Navigator.of(context).pop();
                switch (e.runtimeType) {
                  case MediaPermissionException:
                    await UIHelper.showPostcardStampPhotoAccessFailed(context);
                    break;
                  default:
                    if (!mounted) return;
                    await UIHelper.showPostcardStampSavedFailed(context);
                }
              }
            },
          ),
        OptionItem(
          title: 'hide'.tr(),
          titleStyle: theme.textTheme.moMASans700Black16
              .copyWith(fontSize: 18, color: MoMAColors.moMA3),
          titleStyleOnPrecessing: theme.textTheme.moMASans700Black16.copyWith(
              fontSize: 18, color: const Color.fromRGBO(245, 177, 177, 1)),
          icon: SvgPicture.asset(
            "assets/images/postcard_hide.svg",
            colorFilter:
                const ColorFilter.mode(MoMAColors.moMA3, BlendMode.srcIn),
          ),
          iconOnProcessing: SvgPicture.asset(
            "assets/images/postcard_hide.svg",
            colorFilter: const ColorFilter.mode(
                Color.fromRGBO(245, 177, 177, 1), BlendMode.srcIn),
          ),
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
      ],
    );
  }

  Widget _progressItem(
      BuildContext context, int index, int currentStampNumber) {
    final color =
        index < currentStampNumber ? MoMAColors.moMA12 : AppColor.auLightGrey;
    final borderRadius = index == 0
        ? const BorderRadius.only(
            topLeft: Radius.circular(50),
            bottomLeft: Radius.circular(50),
          )
        : index == MAX_STAMP_IN_POSTCARD - 1
            ? const BorderRadius.only(
                topRight: Radius.circular(50),
                bottomRight: Radius.circular(50),
              )
            : BorderRadius.zero;
    return Container(
      height: 13,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
    );
  }

  Widget _postcardProgress(AssetToken asset) {
    final theme = Theme.of(context);
    final travelInfoWithoutInternetUser =
        asset.postcardMetadata.listTravelInfoWithoutLocationName;
    final currentStampNumber = asset.getArtists.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "total_distance_traveled".tr(),
          style: theme.textTheme.moMASans700Black16.copyWith(fontSize: 18),
        ),
        Text(
            distanceFormatter.format(
                distance: travelInfoWithoutInternetUser.totalDistance),
            style: theme.textTheme.moMASans400Black12
                .copyWith(color: MoMAColors.moMA12)),
        const SizedBox(height: 15),
        Row(
          children: [
            Text(
              "postcard_progress".tr(),
              style: theme.textTheme.moMASans400Grey12,
            ),
            const Spacer(),
            Text(
                "stamps_".tr(namedArgs: {
                  "current": numberFormatter.format(currentStampNumber),
                  "total": MAX_STAMP_IN_POSTCARD.toString(),
                }),
                style: theme.textTheme.moMASans400Grey12)
          ],
        ),
        Row(
          children: [
            ...List.generate(MAX_STAMP_IN_POSTCARD, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: _progressItem(context, index, currentStampNumber),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _travelInfoWidget(PostcardDetailState postcardDetailState) {
    final asset = postcardDetailState.assetToken;
    return BlocConsumer<TravelInfoBloc, TravelInfoState>(
      listener: (context, state) {},
      builder: (context, state) {
        final travelInfo = state.listTravelInfo;
        final lastTravelInfo = state.lastTravelInfo;
        if (travelInfo == null || lastTravelInfo == null) {
          return const SizedBox();
        }
        const emptyDivider = SizedBox(
          height: 20,
        );
        const verticalDivider = SizedBox(
          height: 20,
          child: VerticalDivider(
            color: Colors.black,
            thickness: 1,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _postcardProgress(asset!),
            const SizedBox(
              height: 32,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (postcardDetailState.canDoAction) ...[
                  if (postcardDetailState.isSending())
                    _sendingTripItem(context, asset, lastTravelInfo)
                  else
                    _notSentItem(lastTravelInfo),
                  emptyDivider,
                ],
                ...travelInfo.reversed
                    .mapIndexed((int index, TravelInfo e) {
                      final withDivider = index != travelInfo.length - 1;
                      final divider = withDivider
                          ? (travelInfo.reversed.toList()[index + 1].isInternet
                              ? verticalDivider
                              : emptyDivider)
                          : const SizedBox();
                      final emptyDividerIfNeed =
                          withDivider ? emptyDivider : const SizedBox();
                      if (e.to == null) {
                        if (postcardDetailState.isSending() &&
                            postcardDetailState.isLastOwner) {
                          return [
                            _sendingTripItem(context, asset, lastTravelInfo),
                            emptyDividerIfNeed,
                          ];
                        }
                        return e.from.stampedLocation?.isInternet == true
                            ? [_webCompleteTravelWidget(e), divider]
                            : [_completeTravelWidget(e), emptyDividerIfNeed];
                      }
                      if (e.isInternet) {
                        return [
                          _webTravelWidget(e, onTap: () {
                            _gotoTripDetail(context, e);
                          }),
                          divider,
                        ];
                      }
                      return [
                        _travelWidget(e, onTap: () {
                          _gotoTripDetail(context, e);
                        }),
                        emptyDividerIfNeed
                      ];
                    })
                    .toList()
                    .flattened
                    .toList(),
              ],
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

  Widget _webTravelWidget(TravelInfo travelInfo, {Function()? onTap}) {
    return SizedBox(
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          Row(
            children: [
              const SizedBox(width: 25),
              Expanded(
                child: _travelWidget(travelInfo,
                    onTap: onTap, overrideColor: AppColor.auQuickSilver),
              ),
            ],
          ),
          const Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: VerticalDivider(
                color: Colors.black,
                thickness: 1,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _travelWidget(TravelInfo travelInfo,
      {Function()? onTap, Color? overrideColor}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(numberFormatter.format(travelInfo.index),
                        style: theme.textTheme.moMASans400Black12.copyWith(
                            color: overrideColor ?? AppColor.auQuickSilver)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          travelInfo.sentLocation ?? "",
                          style: theme.textTheme.moMASans400Black12
                              .copyWith(color: overrideColor),
                        ),
                        Row(
                          children: [
                            SvgPicture.asset(
                              "assets/images/arrow_3.svg",
                              colorFilter: ColorFilter.mode(
                                  overrideColor ?? AppColor.primaryBlack,
                                  BlendMode.srcIn),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                travelInfo.receivedLocation ?? "-",
                                style: theme.textTheme.moMASans400Black12
                                    .copyWith(color: overrideColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              distanceFormatter.format(
                                  distance: travelInfo.getDistance()),
                              style: theme.textTheme.moMASans700Black12
                                  .copyWith(
                                      color: overrideColor ??
                                          const Color.fromRGBO(
                                              131, 79, 196, 1)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
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

  Widget _webCompleteTravelWidget(TravelInfo travelInfo) {
    return SizedBox(
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          Row(
            children: [
              const SizedBox(width: 25),
              Expanded(
                child: _completeTravelWidget(travelInfo,
                    overrideColor: AppColor.auQuickSilver),
              ),
            ],
          ),
          const Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: VerticalDivider(
                color: Colors.black,
                thickness: 1,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _completeTravelWidget(TravelInfo travelInfo, {Color? overrideColor}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        _gotoTripDetail(context, travelInfo);
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(numberFormatter.format(travelInfo.index),
                  style: theme.textTheme.moMASans400Black12.copyWith(
                      color: overrideColor ?? AppColor.auQuickSilver)),
              Text(
                travelInfo.sentLocation ?? "",
                style: theme.textTheme.moMASans400Black12
                    .copyWith(color: overrideColor),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numberFormatter.format(sendingTrip.index),
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
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _notSentItem(TravelInfo lastTravelInfo) {
    return _travelWidget(lastTravelInfo, onTap: () {});
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

class PostcardContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final BorderRadiusGeometry borderRadius;
  final BoxBorder? border;
  final BoxShadow? boxShadow;

  const PostcardContainer({
    Key? key,
    required this.child,
    this.width = double.infinity,
    this.height,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 15, 22),
    this.margin,
    this.color = AppColor.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.border,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow != null ? [boxShadow!] : null,
      ),
      child: child,
    );
  }
}
