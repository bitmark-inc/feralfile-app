//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/postcard_travel_info.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/travel_info/travel_info_state.dart';
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/util/share_helper.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/postcard_chat.dart';
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
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';

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
  late bool isSending;
  late bool alreadyShowPopup;
  late bool isProcessingStampPostcard;

  late DistanceFormatter distanceFormatter;
  Timer? timer;

  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;
  final _metricClient = injector.get<MetricClientService>();
  final _configurationService = injector<ConfigurationService>();
  final _postcardService = injector<PostcardService>();

  @override
  void initState() {
    _scrollController = ScrollController();
    isViewOnly = widget.payload.isFromLeaderboard;
    isSending = false;
    alreadyShowPopup = false;
    isProcessingStampPostcard = false;
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

  Future<void> _removeShareConfig(AssetToken assetToken) async {
    await _configurationService.removeSharedPostcardWhere(
        (p) => p.owner == assetToken.owner && p.tokenID == assetToken.id);
  }

  void _shareTwitter(AssetToken token) {
    shareToTwitter(token: token, twitterCaption: widget.payload.twitterCaption);
  }

  Future<void> _youDidIt(BuildContext context, AssetToken asset) async {
    final totalDistance = asset.totalDistance;
    _configurationService.setListPostcardAlreadyShowYouDidIt(
        [PostcardIdentity(id: asset.id, owner: asset.owner)]);
    return UIHelper.showPostcardFinish15Stamps(context,
        distanceFormatter.format(distance: totalDistance, withFullName: true),
        onShareTap: () {
      _shareTwitter(asset);
      Navigator.pop(context);
    });
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
    injector<ChatService>().dispose();
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
          token: asset,
          wallet: wallet,
          address: asset.owner,
          cryptoType:
              asset.blockchain == "ethereum" ? CryptoType.ETH : CryptoType.XTZ,
          name: asset.title ?? ''),
    );
  }

  Future<void> retryStampPostcardIfNeed(
      BuildContext context, AssetToken assetToken) async {
    final processingStampPostcard = assetToken.processingStampPostcard;
    if (processingStampPostcard != null) {
      setState(() {
        isProcessingStampPostcard = true;
      });
      final walletIndex = await assetToken.getOwnerWallet();
      final imageFile = File(processingStampPostcard.imagePath);
      final metadataFile = File(processingStampPostcard.metadataPath);
      final location = processingStampPostcard.location;
      final counter = processingStampPostcard.counter;
      final contractAddress = assetToken.contractAddress ?? "";
      final isStampSuccess = await _postcardService.stampPostcardUntilSuccess(
          assetToken.tokenId ?? "",
          walletIndex!.first,
          walletIndex.second,
          imageFile,
          metadataFile,
          location,
          counter,
          contractAddress, () {
        return Navigator.of(context).mounted &&
            assetToken.processingStampPostcard != null;
      });
      if (isStampSuccess == true) {
        await _configurationService.setProcessingStampPostcard(
            [processingStampPostcard],
            isRemove: true);
        await _postcardService.updateStampingPostcard([
          StampingPostcard(
            indexId: assetToken.id,
            address: processingStampPostcard.address,
            imagePath: processingStampPostcard.imagePath,
            metadataPath: processingStampPostcard.metadataPath,
            counter: counter,
          )
        ]);
      }
      setState(() {
        isProcessingStampPostcard = false;
      });
    }
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
      if (previous.assetToken?.isCompleted != true &&
          current.assetToken?.isCompleted == true &&
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
        if (!isProcessingStampPostcard) {
          retryStampPostcardIfNeed(context, assetToken);
        }
        setState(() {
          currentAsset = state.assetToken;
          isViewOnly = viewOnly;
          isSending = state.assetToken?.isSending ?? false;
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

        if (!assetToken.isStamped) {
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
        if (!alreadyShowPostcardUpdate) {
          if (_configurationService.isNotificationEnabled() != true) {
            _postcardUpdated(context);
          }
          _configurationService.setAlreadyShowPostcardUpdates(
              [PostcardIdentity(id: assetToken.id, owner: assetToken.owner)]);
        }

        if (assetToken.didSendNext) {
          _removeShareConfig(assetToken);
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
        final artistNames = (asset.getArtists.isEmpty
                ? [Artist(name: "no_artists".tr())]
                : asset.getArtists)
            .map((e) => e.name)
            .map((e) => e.toIdentityOrMask(identityState.identityMap))
            .toList();
        final owners = asset.owners.map((key, value) => MapEntry(
            key.toIdentityOrMask(identityState.identityMap) ?? key, value));
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
                            state.assetToken == null ||
                                    state.assetToken?.pending == true
                                ? const SizedBox()
                                : FutureBuilder<Pair<WalletStorage, int>?>(
                                    future: state.assetToken!.getOwnerWallet(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final wallet = snapshot.data;
                                        if (wallet == null) {
                                          return const SizedBox();
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15),
                                          child: MessagePreview(
                                              payload: MessagePreviewPayload(
                                            asset: state.assetToken!,
                                            wallet: wallet,
                                            getAssetToken: getCurrentAssetToken,
                                          )),
                                        );
                                      }
                                      return const SizedBox();
                                    }),
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
                              _postcardAction(context, asset),
                              const SizedBox(
                                height: 20,
                              ),
                            ],
                            _postcardInfo(context, asset),
                            const SizedBox(
                              height: 20,
                            ),
                            _postcardLeaderboard(
                                context, state.leaderboard, asset),
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
                            _artworkInfo(context, asset, state.provenances,
                                artistNames, owners),
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

  AssetToken? getCurrentAssetToken() {
    return context.read<PostcardDetailBloc>().state.assetToken;
  }

  void _refreshPostcard() {
    log.info("Refresh postcard");
    context.read<PostcardDetailBloc>().add(PostcardDetailGetInfoEvent(
          widget.payload.identities[widget.payload.currentIndex],
          useIndexer: true,
        ));
  }

  Widget _postcardAction(BuildContext context, AssetToken asset) {
    final theme = Theme.of(context);
    if (asset.isCompleted || !asset.isLastOwner || isViewOnly != false) {
      return const SizedBox();
    }
    if (asset.isProcessingStamp) {
      return PostcardButton(
        text: "minting_stamp".tr(),
        isProcessing: true,
      );
    }
    if (!(asset.isStamping || asset.isStamped)) {
      final button = PostcardAsyncButton(
        text: "continue".tr(),
        fontSize: 18,
        onTap: () async {
          injector<NavigationService>().popAndPushNamed(AppRouter.designStamp,
              arguments: DesignStampPayload(asset));
        },
        color: AppColor.momaGreen,
      );
      final page = _postcardPreview(context, asset);
      return PostcardButton(
        text: "stamp_postcard".tr(),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.postcardExplain,
            arguments: PostcardExplainPayload(asset, button, pages: [page]),
          );
        },
        color: MoMAColors.moMA8,
      );
    }

    final sendPostcardExplain = [
      const SizedBox(
        height: 20,
      ),
      Padding(
        padding: const EdgeInsets.only(left: 16, right: 15),
        child: Text(
          "send_postcard_to_someone_else".tr(),
          style: theme.textTheme.moMASans400Black12,
        ),
      ),
    ];
    if (!isSending) {
      timer?.cancel();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostcardAsyncButton(
            text: "invite_to_collaborate".tr(),
            color: MoMAColors.moMA8,
            onTap: () async {
              await asset.sharePostcard(onSuccess: () {
                setState(() {
                  isSending = asset.isSending;
                });
              }, onFailed: (e) {
                if (e is DioException) {
                  if (mounted) {
                    UIHelper.showSharePostcardFailed(context, e);
                  }
                }
              });
            },
          ),
          ...sendPostcardExplain,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostcardButton(
            text: "postcard_sent".tr(),
            disabledColor: AppColor.momaGreen,
            enabled: false,
          ),
          ...sendPostcardExplain,
        ],
      );
    }
  }

  Widget _postcardInfo(BuildContext context, AssetToken asset) {
    return PostcardContainer(
      child: _travelInfoWidget(asset),
    );
  }

  Widget _postcardLeaderboard(BuildContext context,
      PostcardLeaderboard? leaderboard, AssetToken assetToken) {
    final theme = Theme.of(context);
    final item = leaderboard?.items
        .firstWhereOrNull((element) => element.id == assetToken.tokenId);
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
                assetToken: assetToken,
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

  Widget _artworkInfo(
      BuildContext context,
      AssetToken asset,
      List<Provenance> provenances,
      List<String?> artistNames,
      Map<String, int> owners) {
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
                  return PostcardContainer(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: postcardOwnership(context, asset, owners),
                  );
                },
              ),
            ] else ...[
              provenances.isNotEmpty
                  ? PostcardContainer(
                      child: _provenanceView(context, provenances))
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
    final isViewOnly = await asset.isViewOnly();
    if (!mounted) return;
    const isHidden = false;
    final isStamped = asset.isStamped;
    UIHelper.showPostcardDrawerAction(
      context,
      options: [
        OptionItem(
          title: "view_on_secondary_market".tr(),
          icon: SvgPicture.asset(
            'assets/images/search_bold.svg',
            width: 24,
            height: 24,
          ),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRouter.irlWebView,
                arguments: IRLWebScreenPayload(asset.secondaryMarketURL));
          },
        ),
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
        if (!isViewOnly)
          OptionItem(
            title: 'download_stamp'.tr(),
            isEnable: isStamped,
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
            iconOnDisable: SvgPicture.asset('assets/images/download.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                    AppColor.disabledColor, BlendMode.srcIn)),
            onTap: () async {
              try {
                await _postcardService.downloadStamp(
                    tokenId: asset.tokenId!,
                    stampIndex: asset.stampIndexWithStamping);
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
        if (!isViewOnly)
          OptionItem(
            title: 'download_postcard'.tr(),
            isEnable: isStamped,
            icon: SvgPicture.asset(
              'assets/images/download.svg',
              width: 24,
              height: 24,
            ),
            iconOnProcessing: SvgPicture.asset(
              'assets/images/download.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                  AppColor.disabledColor, BlendMode.srcIn),
            ),
            iconOnDisable: SvgPicture.asset(
              'assets/images/download.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                  AppColor.disabledColor, BlendMode.srcIn),
            ),
            onTap: () async {
              try {
                await _postcardService.downloadPostcard(asset.tokenId!);
                if (!mounted) return;
                Navigator.of(context).pop();
                await UIHelper.showPostcardSaved(context);
              } catch (e) {
                log.info("Download postcard failed: error ${e.toString()}");
                if (!mounted) return;
                Navigator.of(context).pop();
                switch (e.runtimeType) {
                  case MediaPermissionException:
                    await UIHelper.showPostcardPhotoAccessFailed(context);
                    break;
                  default:
                    if (!mounted) return;
                    await UIHelper.showPostcardSavedFailed(context);
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

  Widget _travelInfoWidget(AssetToken asset) {
    return BlocConsumer<TravelInfoBloc, TravelInfoState>(
      listener: (context, state) {},
      builder: (context, state) {
        final travelInfo = state.listTravelInfo;
        if (travelInfo == null) {
          return const SizedBox();
        }
        return PostcardTravelInfo(
          assetToken: asset,
          listTravelInfo: travelInfo,
          onCancelShare: () {
            setState(() {
              isSending = asset.isSending;
            });
          },
        );
      },
    );
  }

  Widget _postcardPreview(BuildContext context, AssetToken asset) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 265,
            child: Stack(
              children: [
                PostcardViewWidget(
                  assetToken: asset,
                  withPreviewStamp: true,
                ),
                Positioned.fill(child: Container(color: Colors.transparent)),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "this_is_your_group_postcard".tr(),
                style:
                    theme.textTheme.moMASans400Black14.copyWith(fontSize: 18),
              ),
            ],
          )
        ],
      ),
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
