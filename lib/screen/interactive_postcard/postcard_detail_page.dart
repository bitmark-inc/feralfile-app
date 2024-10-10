//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/prompt.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
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
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_page.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/feral_file_custom_tab.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/util/share_helper.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/postcard_chat.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/prompt_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension/moma_sans.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
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
    super.identity, {
    super.key,
    super.playlist,
    super.twitterCaption,
    this.isFromLeaderboard = false,
    super.useIndexer,
  });
}

class ClaimedPostcardDetailPage extends StatefulWidget {
  final PostcardDetailPagePayload payload;

  const ClaimedPostcardDetailPage({required this.payload, super.key});

  @override
  State<ClaimedPostcardDetailPage> createState() =>
      ClaimedPostcardDetailPageState();
}

class ClaimedPostcardDetailPageState extends State<ClaimedPostcardDetailPage>
    with AfterLayoutMixin<ClaimedPostcardDetailPage> {
  late ScrollController _scrollController;
  late bool withSharing;
  late bool isNotOwner;
  late bool isSending;
  late bool alreadyShowPopup;
  late bool isProcessingStampPostcard;
  late bool isAutoStampIfNeed;

  late DistanceFormatter distanceFormatter;
  Timer? timer;

  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;
  final _configurationService = injector<ConfigurationService>();
  final _postcardService = injector<PostcardService>();
  final _remoteConfig = injector<RemoteConfigService>();
  Prompt? _prompt;
  final _browser = FeralFileBrowser();

  @override
  void initState() {
    _scrollController = ScrollController();
    isNotOwner = widget.payload.isFromLeaderboard;
    isSending = false;
    alreadyShowPopup = false;
    isProcessingStampPostcard = false;
    isAutoStampIfNeed = true;
    super.initState();
    context.read<PostcardDetailBloc>().add(
          PostcardDetailGetInfoEvent(widget.payload.identity,
              useIndexer: widget.payload.useIndexer ||
                  widget.payload.isFromLeaderboard),
        );
    context.read<PostcardDetailBloc>().add(FetchLeaderboardEvent());
    context.read<AccountsBloc>().add(FetchAllAddressesEvent());
    withSharing = widget.payload.twitterCaption != null;
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  Future<void> _showSharingExpired(BuildContext context) async {
    await UIHelper.showPostcardDrawerAction(context, options: [
      OptionItem(
        builder: (context, _) => Row(
          children: [
            const SizedBox(width: 15),
            SizedBox(
              width: 30,
              child: SvgPicture.asset(
                'assets/images/restart.svg',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                'you_need_resend'.tr(),
                style: Theme.of(context).textTheme.moMASans700Black18,
              ),
            ),
          ],
        ),
      ),
      OptionItem(
        builder: (context, _) => Row(
          children: [
            const SizedBox(width: 15),
            SvgPicture.asset(
              'assets/images/arrow_right.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                'no_one_received'.tr(),
                style: Theme.of(context).textTheme.moMASans700AuGrey18,
              ),
            ),
          ],
        ),
      ),
      OptionItem(
        builder: (context, _) => Row(
          children: [
            const SizedBox(width: 15),
            SvgPicture.asset(
              'assets/images/cross.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                'resend_new_link'.tr(),
                style: Theme.of(context).textTheme.moMASans700AuGrey18,
              ),
            ),
          ],
        ),
      ),
    ]);
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
    unawaited(_configurationService.setListPostcardAlreadyShowYouDidIt(
        [PostcardIdentity(id: asset.id, owner: asset.owner)]));
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
    final tagsText = tags.map((e) => '#$e').join(' ');
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'congratulations_new_NFT'.tr(),
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 12),
        Text(tagsText, style: theme.textTheme.ppMori400Grey14),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'share_on_'.tr(),
          onTap: () {
            _shareTwitter(asset);
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 8),
        OutlineButton(
          text: 'close'.tr(),
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
    return UIHelper.showDialog(context, 'share_the_new'.tr(), content);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    timer?.cancel();
    unawaited(injector<ChatService>().dispose());
    super.dispose();
  }

  Future<void> gotoChatThread(BuildContext context) async {
    final state = context.read<PostcardDetailBloc>().state;
    final asset = state.assetToken;
    if (asset == null) {
      return;
    }
    final wallet = await asset.getOwnerWallet();
    if (wallet == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).pushNamed(
      AppRouter.chatThreadPage,
      arguments: ChatThreadPagePayload(
          token: asset,
          wallet: wallet,
          address: asset.owner,
          cryptoType:
              asset.blockchain == 'ethereum' ? CryptoType.ETH : CryptoType.XTZ,
          name: asset.title ?? ''),
    );
  }

  Future<bool?> retryStampPostcardIfNeed(
      final BuildContext context, final AssetToken assetToken) async {
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
      final contractAddress = assetToken.contractAddress ?? '';
      final isStampSuccess = await _postcardService.stampPostcard(
        assetToken.tokenId ?? '',
        walletIndex!.first,
        walletIndex.second,
        imageFile,
        metadataFile,
        location,
        counter,
        contractAddress,
        assetToken.postcardMetadata.prompt,
      );
      if (isStampSuccess != false) {
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
            prompt: assetToken.postcardMetadata.prompt,
          )
        ]);
      }
      setState(() {
        isProcessingStampPostcard = false;
      });
      return isStampSuccess;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    distanceFormatter = DistanceFormatter();
    final hasKeyboard = currentAsset?.medium == 'software' ||
        currentAsset?.medium == 'other' ||
        currentAsset?.medium == null;
    return BlocConsumer<PostcardDetailBloc, PostcardDetailState>(
        listenWhen: (previous, current) {
      if (previous.assetToken?.isCompleted != true &&
          current.assetToken?.isCompleted == true &&
          current.assetToken?.isAlreadyShowYouDidIt == false &&
          !isNotOwner &&
          current.isViewOnly == false) {
        unawaited(_youDidIt(context, current.assetToken!));
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

      if (!mounted) {
        return;
      }
      final assetToken = state.assetToken;

      if (assetToken != null) {
        if (!mounted) {
          return;
        }
        _prompt ??= assetToken.postcardMetadata.prompt;

        if (isAutoStampIfNeed && !isProcessingStampPostcard) {
          isAutoStampIfNeed = false;
          unawaited(
              retryStampPostcardIfNeed(context, assetToken).then((final value) {
            if (context.mounted && value == false) {
              UIHelper.showPostcardStampFailed(context);
            }
          }));
        }
        setState(() {
          currentAsset = state.assetToken;
          isNotOwner = isNotOwner || (state.isViewOnly ?? true);
          isSending = state.assetToken?.isSending ?? false;
        });
        if (isNotOwner) {
          return;
        }
        if (withSharing) {
          unawaited(_socialShare(context, assetToken));
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
          if (!_configurationService.isNotificationEnabled()) {
            if (!mounted) {
              return;
            }
            unawaited(_postcardUpdated(context));
          }
          unawaited(_configurationService.setAlreadyShowPostcardUpdates(
              [PostcardIdentity(id: assetToken.id, owner: assetToken.owner)]));
        }

        if (assetToken.didSendNext) {
          unawaited(_removeShareConfig(assetToken));
        }

        if (assetToken.isShareExpired &&
            (assetToken.isLastOwner && !isNotOwner)) {
          if (!mounted) {
            return;
          }
          unawaited(_showSharingExpired(context));
          unawaited(_removeShareConfig(assetToken));
        }
      }
      if (!mounted) {
        return;
      }
      context.read<IdentityBloc>().add(GetIdentityEvent(identitiesList));
    }, builder: (context, state) {
      if (state.assetToken != null) {
        final asset = state.assetToken!;
        context
            .read<TravelInfoBloc>()
            .add(GetTravelInfoEvent(asset: state.assetToken!));

        final identityState = context.watch<IdentityBloc>().state;
        final artistNames = (asset.getArtists.isEmpty
                ? [Artist(name: 'no_artists'.tr())]
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
                scrolledUnderElevation: 0,
                toolbarHeight: 70,
                centerTitle: false,
                title: Text(
                  asset.displayTitle!,
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
                        onPressed: () => unawaited(
                            _showArtworkOptionsDialog(context, asset)),
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
                            _chatMessage(context, asset),
                            if (_prompt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: PromptView(
                                  prompt: _prompt!,
                                  onTap: () async {
                                    await UIHelper.showCenterEmptySheet(context,
                                        content: PromptView(
                                          key: const Key('prompt_view_full'),
                                          prompt: _prompt!,
                                          expandable: true,
                                        ));
                                  },
                                ),
                              ),
                            const SizedBox(height: 15),
                            Hero(
                              tag: 'detail_${asset.id}',
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
                                        unawaited(
                                            Navigator.of(context).pushNamed(
                                          AppRouter.artworkPreviewPage,
                                          arguments: widget.payload,
                                        ));
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_remoteConfig.getBool(ConfigGroup.viewDetail,
                                ConfigKey.actionButton)) ...[
                              _postcardAction(context, asset),
                              const SizedBox(height: 20),
                            ],
                            if (state.showMerch == true) ...[
                              _postcardPhysical(
                                  context, asset, state.enableMerch ?? false),
                              const SizedBox(height: 20),
                            ],
                            _postcardInfo(context, asset),
                            const SizedBox(height: 20),
                            if (_remoteConfig.getBool(ConfigGroup.viewDetail,
                                ConfigKey.leaderBoard)) ...[
                              _postcardLeaderboard(
                                  context, state.leaderboard, asset),
                              const SizedBox(height: 20),
                            ],
                            if (_remoteConfig.getBool(ConfigGroup.viewDetail,
                                ConfigKey.aboutMoma)) ...[
                              _aboutTheProject(context),
                              const SizedBox(height: 20),
                            ],
                            if (_remoteConfig.getBool(ConfigGroup.viewDetail,
                                ConfigKey.glossary)) ...[
                              _web3Glossary(context, asset),
                              const SizedBox(height: 20),
                            ],
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

  AssetToken? getCurrentAssetToken() =>
      context.read<PostcardDetailBloc>().state.assetToken;

  void _refreshPostcard() {
    log.info('Refresh postcard');
    context.read<PostcardDetailBloc>().add(PostcardDetailGetInfoEvent(
          widget.payload.identity,
          useIndexer: true,
        ));
  }

  Widget _chatMessage(BuildContext context, AssetToken assetToken) {
    if (assetToken.pending == true ||
        !_remoteConfig.getBool(ConfigGroup.viewDetail, ConfigKey.chat)) {
      return const SizedBox();
    } else {
      return FutureBuilder<Pair<WalletStorage, int>?>(
          // ignore: discarded_futures
          future: assetToken.getOwnerWallet(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final wallet = snapshot.data;
              if (wallet == null) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 15),
                child: MessagePreview(
                    payload: MessagePreviewPayload(
                  asset: assetToken,
                  wallet: wallet,
                  getAssetToken: getCurrentAssetToken,
                )),
              );
            }
            return const SizedBox();
          });
    }
  }

  Widget _postcardAction(final BuildContext context, final AssetToken asset) {
    final theme = Theme.of(context);
    if (asset.isCompleted || isNotOwner || !asset.isLastOwner) {
      return const SizedBox();
    }
    if (isProcessingStampPostcard ||
        (_remoteConfig.getBool(
                ConfigGroup.postcardAction, ConfigKey.waitConfirmedToSend) &&
            asset.isStamping)) {
      return PostcardButton(
        text: 'confirming_on_blockchain'.tr(),
        isProcessing: true,
      );
    }
    if (!(asset.isStamping || asset.isStamped || asset.isProcessingStamp)) {
      return PostcardAsyncButton(
        text: 'stamp_postcard'.tr(),
        onTap: () async {
          if (asset.numberOwners > 1) {
            final button = PostcardAsyncButton(
              text: 'continue'.tr(),
              fontSize: 18,
              onTap: () async {
                await injector<NavigationService>().popAndPushNamed(
                    AppRouter.designStamp,
                    arguments: DesignStampPayload(asset, false, null));
              },
              color: AppColor.momaGreen,
            );
            final page = _postcardPreview(context, asset);
            await Navigator.of(context).pushNamed(
              AppRouter.postcardExplain,
              arguments: PostcardExplainPayload(asset, button, pages: [page]),
            );
          } else {
            await injector<NavigationService>()
                .selectPromptsThenStamp(context, asset, null);
          }
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
          'send_postcard_to_someone_else'.tr(),
          style: theme.textTheme.moMASans400Black12,
        ),
      ),
    ];
    if (!asset.isFinal) {
      if (!isSending) {
        timer?.cancel();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
              builder: (final context) => PostcardAsyncButton(
                    text: 'invite_to_collaborate'.tr(),
                    color: MoMAColors.moMA8,
                    onTap: () async {
                      final isSuccess =
                          await retryStampPostcardIfNeed(context, asset);
                      if (context.mounted && isSuccess == false) {
                        await UIHelper.showPostcardStampFailed(context);
                        return;
                      }
                      if (!context.mounted) {
                        return;
                      }
                      final box = context.findRenderObject() as RenderBox?;
                      await asset.sharePostcard(
                        onSuccess: () {
                          setState(() {
                            isSending = asset.isSending;
                          });
                        },
                        onFailed: (e) {
                          if (e is DioException) {
                            if (mounted) {
                              UIHelper.showSharePostcardFailed(context, e);
                            }
                          }
                        },
                        sharePositionOrigin: box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size,
                      );
                    },
                  )),
          ...sendPostcardExplain,
        ],
      );
    }
    return const SizedBox();
  }

  Widget _postcardPhysical(
          BuildContext context, AssetToken assetToken, bool isEnable) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostcardButton(
            text: 'buy_merch'.tr(),
            enabled: isEnable,
            icon: SvgPicture.asset(
              isEnable
                  ? 'assets/images/unlock_icon.svg'
                  : 'assets/images/lock_icon.svg',
            ),
            onTap: () async {
              final indexId = assetToken.id;
              final jwtToken =
                  (await injector<AuthService>().getAuthToken())!.jwtToken;
              final userIndex = assetToken.stampIndex;
              log.info('?indexId=$indexId&userIndex=$userIndex');
              if (!context.mounted) {
                return;
              }
              final url = '${Environment.merchandiseBaseUrl}'
                  '?indexId=$indexId'
                  '&token=$jwtToken'
                  '&userIndex=$userIndex';
              await Navigator.of(context).pushNamed(AppRouter.irlWebView,
                  arguments: IRLWebScreenPayload(url,
                      statusBarColor: const Color.fromRGBO(242, 242, 242, 1),
                      isDarkStatusBar: false,
                      isPlainUI: true,
                      localStorageItems: {'token': jwtToken}));
            },
          ),
          if (!isEnable) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 15),
              child: Text(
                'must_complete_to_unlock'.tr(),
                style: Theme.of(context).textTheme.moMASans400Black12,
              ),
            ),
          ]
        ],
      );

  Widget _postcardInfo(BuildContext context, AssetToken asset) =>
      PostcardContainer(
        child: _travelInfoWidget(asset),
      );

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
                  'leaderboard'.tr(),
                  style:
                      theme.textTheme.moMASans700Black16.copyWith(fontSize: 18),
                ),
                const Spacer(),
                if (item != null)
                  Text(
                    '# ${item.rank}',
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
          unawaited(
              Navigator.of(context).pushNamed(AppRouter.postcardLeaderboardPage,
                  arguments: PostcardLeaderboardPagePayload(
                    assetToken: assetToken,
                  )));
        },
      ),
    );
  }

  Widget _aboutTheProject(BuildContext context) => Column(
        children: [
          PostcardContainer(
            child: GestureDetector(
              child: Text(
                'about_the_project'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .moMASans700Black16
                    .copyWith(fontSize: 18),
              ),
              onTap: () async {
                await _browser.openUrl(POSTCARD_ABOUT_THE_PROJECT);
              },
            ),
          ),
        ],
      );

  Widget _web3Glossary(BuildContext context, AssetToken asset) => Column(
        children: [
          PostcardContainer(
            child: GestureDetector(
              child: Text(
                'web3_glossary'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .moMASans700Black16
                    .copyWith(fontSize: 18),
              ),
              onTap: () {
                unawaited(Navigator.pushNamed(
                    context, AppRouter.previewPrimerPage,
                    arguments: asset));
              },
            ),
          ),
        ],
      );

  Widget _artworkInfo(
          BuildContext context,
          AssetToken asset,
          List<Provenance> provenances,
          List<String?> artistNames,
          Map<String, int> owners) =>
      Column(
        children: [
          debugInfoWidget(context, currentAsset),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_remoteConfig.getBool(
                  ConfigGroup.viewDetail, ConfigKey.metadata)) ...[
                PostcardContainer(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: postcardDetailsMetadataSection(
                      context, asset, artistNames),
                ),
                const SizedBox(height: 20),
              ],
              if (asset.fungible &&
                  _remoteConfig.getBool(
                      ConfigGroup.viewDetail, ConfigKey.tokenOwnership)) ...[
                BlocBuilder<AccountsBloc, AccountsState>(
                  builder: (context, state) => PostcardContainer(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: postcardOwnership(context, asset, owners),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                if (provenances.isNotEmpty)
                  PostcardContainer(
                      child: _provenanceView(context, provenances))
                else
                  const SizedBox(),
                const SizedBox(height: 20),
              ],
              if (_remoteConfig.getBool(
                  ConfigGroup.viewDetail, ConfigKey.rights)) ...[
                PostcardContainer(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 22),
                    child: artworkDetailsRightSection(context, asset)),
                const SizedBox(height: 40),
              ],
            ],
          )
        ],
      );

  Widget _provenanceView(BuildContext context, List<Provenance> provenances) =>
      BlocBuilder<IdentityBloc, IdentityState>(
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

  Future _showArtworkOptionsDialog(
      BuildContext context, AssetToken asset) async {
    final theme = Theme.of(context);

    final owner = await asset.getOwnerWallet();
    final ownerWallet = owner?.first;
    final addressIndex = owner?.second;
    const isHidden = false;
    final isStamped = asset.isStamped;
    if (!context.mounted) {
      return;
    }
    await UIHelper.showPostcardDrawerAction(
      context,
      options: [
        OptionItem(
          title: 'view_on_secondary_market'.tr(),
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
        if (!isNotOwner) ...[
          if (_remoteConfig.getBool(
              ConfigGroup.feature, ConfigKey.downloadStamp))
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
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  await UIHelper.showPostcardStampSaved(context);
                } catch (e) {
                  log.info('Download stamp failed: error $e');
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  switch (e.runtimeType) {
                    case MediaPermissionException _:
                      await UIHelper.showPostcardStampPhotoAccessFailed(
                          context);
                    default:
                      if (!mounted) {
                        return;
                      }
                      await UIHelper.showPostcardStampSavedFailed(context);
                  }
                }
              },
            ),
          if (_remoteConfig.getBool(
              ConfigGroup.feature, ConfigKey.downloadPostcard))
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
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  await UIHelper.showPostcardSaved(context);
                } catch (e) {
                  log.info('Download postcard failed: error $e');
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  switch (e.runtimeType) {
                    case MediaPermissionException _:
                      await UIHelper.showPostcardPhotoAccessFailed(context);
                    default:
                      if (!mounted) {
                        return;
                      }
                      await UIHelper.showPostcardSavedFailed(context);
                  }
                }
              },
            ),
        ],
        if (ownerWallet != null &&
            asset.isTransferable &&
            asset.isCompleted) ...[
          OptionItem(
            title: 'send_artwork'.tr(),
            icon: SvgPicture.asset('assets/images/send_postcard.svg'),
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

              final sentQuantity = payload['sentQuantity'] as int;
              final isSentAll = payload['isSentAll'] as bool;
              unawaited(injector<ConfigurationService>()
                  .updateRecentlySentToken([
                SentArtwork(asset.id, asset.owner, DateTime.now(), sentQuantity,
                    isSentAll)
              ]));
              if (!context.mounted) {
                return;
              }
              setState(() {});
              if (!payload['isTezos']) {
                if (isSentAll) {
                  unawaited(Navigator.of(context)
                      .popAndPushNamed(AppRouter.homePage));
                }
                return;
              }
              unawaited(UIHelper.showMessageAction(
                context,
                'success'.tr(),
                'send_success_des'.tr(),
                closeButton: 'close'.tr(),
                onClose: () => isSentAll
                    ? Navigator.of(context).popAndPushNamed(
                        AppRouter.homePage,
                      )
                    : null,
              ));
            },
          ),
        ],
        OptionItem(
          title: 'hide'.tr(),
          titleStyle: theme.textTheme.moMASans700Black16
              .copyWith(fontSize: 18, color: MoMAColors.moMA3),
          titleStyleOnPrecessing: theme.textTheme.moMASans700Black16.copyWith(
              fontSize: 18, color: const Color.fromRGBO(245, 177, 177, 1)),
          icon: SvgPicture.asset(
            'assets/images/postcard_hide.svg',
            colorFilter:
                const ColorFilter.mode(MoMAColors.moMA3, BlendMode.srcIn),
          ),
          iconOnProcessing: SvgPicture.asset(
            'assets/images/postcard_hide.svg',
            colorFilter: const ColorFilter.mode(
                Color.fromRGBO(245, 177, 177, 1), BlendMode.srcIn),
          ),
          onTap: () async {
            await _configurationService
                .updateTempStorageHiddenTokenIDs([asset.id], !isHidden);
            await injector<SettingsDataService>().backupUserSettings();

            if (!context.mounted) {
              return;
            }
            NftCollectionBloc.eventController.add(ReloadEvent());
            Navigator.of(context).pop();
            unawaited(UIHelper.showHideArtworkResultDialog(context, !isHidden,
                onOK: () {
              Navigator.of(context).popUntil((route) =>
                  route.settings.name == AppRouter.homePage ||
                  route.settings.name == AppRouter.homePageNoTransition);
            }));
          },
        ),
      ],
    );
  }

  Widget _travelInfoWidget(AssetToken asset) =>
      BlocConsumer<TravelInfoBloc, TravelInfoState>(
        listener: (context, state) {},
        builder: (context, state) {
          final travelInfo = state.listTravelInfo;
          if (travelInfo == null) {
            return const SizedBox();
          }
          return PostcardTravelInfo(
            assetToken: asset,
            listTravelInfo: travelInfo,
          );
        },
      );

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
                'this_is_your_group_postcard'.tr(),
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

  static PostcardIdentity fromJson(Map<String, dynamic> json) =>
      PostcardIdentity(
        id: json['id'],
        owner: json['owner'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner,
      };
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
    required this.child,
    super.key,
    this.width = double.infinity,
    this.height,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 15, 22),
    this.margin,
    this.color = AppColor.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) => Container(
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
