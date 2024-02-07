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
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/file_helper.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/external_link.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_share/social_share.dart';
import 'package:url_launcher/url_launcher.dart';

part 'artwork_detail_page.g.dart';

class ArtworkDetailPage extends StatefulWidget {
  final ArtworkDetailPayload payload;

  const ArtworkDetailPage({required this.payload, super.key});

  @override
  State<ArtworkDetailPage> createState() => _ArtworkDetailPageState();
}

class _ArtworkDetailPageState extends State<ArtworkDetailPage>
    with AfterLayoutMixin<ArtworkDetailPage> {
  late ScrollController _scrollController;
  late bool withSharing;

  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;
  final metricClient = injector.get<MetricClientService>();
  final _airdropService = injector.get<AirdropService>();

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
    context.read<ArtworkDetailBloc>().add(ArtworkDetailGetInfoEvent(
        widget.payload.identities[widget.payload.currentIndex],
        useIndexer: widget.payload.useIndexer));
    context.read<AccountsBloc>().add(FetchAllAddressesEvent());
    context.read<AccountsBloc>().add(GetAccountsEvent());
    withSharing = widget.payload.twitterCaption != null;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    metricClient.timerEvent(
      MixpanelEvent.stayInArtworkDetail,
    );
  }

  Future<void> _manualShare(
      String caption, String url, List<String> hashTags) async {
    final encodeCaption = Uri.encodeQueryComponent(caption);
    final hashTagsString = hashTags.join(',');
    final twitterUrl = '${SocialApp.twitterPrefix}?url=$url&text=$encodeCaption'
        '&hashtags=$hashTagsString';
    final twitterUri = Uri.parse(twitterUrl);
    await launchUrl(twitterUri, mode: LaunchMode.externalApplication);
  }

  void _shareTwitter(AssetToken token) {
    final prefix = Environment.tokenWebviewPrefix;
    final url = '$prefix/token/${token.id}';
    final caption = widget.payload.twitterCaption ?? '';
    final hashTags = getTags(token);
    unawaited(SocialShare.checkInstalledAppsForShare().then((data) {
      if (data?[SocialApp.twitter]) {
        SocialShare.shareTwitter(caption, url: url, hashtags: hashTags);
      } else {
        _manualShare(caption, url, hashTags);
      }
    }));
    unawaited(metricClient.addEvent(MixpanelEvent.share, data: {
      'id': token.id,
      'to': 'Twitter',
      'caption': caption,
      'title': token.title,
      'artistID': token.artistID,
    }));
  }

  List<String> getTags(AssetToken asset) {
    final defaultTags = [
      'feralfile',
      'digitalartwallet',
      'NFT',
    ];
    List<String> tags = defaultTags;
    if (asset.isMoMAMemento) {
      tags = [
        'refikunsupervised',
        'feralfileapp',
      ];
    }
    return tags;
  }

  Future<void> _socialShare(BuildContext context, AssetToken asset) {
    final theme = Theme.of(context);
    final tags = getTags(asset);
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

  Future<void> _shareMemento(BuildContext context, AssetToken asset) async {
    final deeplink = await _airdropService.shareAirdrop(asset);
    if (deeplink == null) {
      if (!mounted) {
        return;
      }
      context
          .read<ArtworkDetailBloc>()
          .add(ArtworkDetailGetAirdropDeeplink(assetToken: asset));
      unawaited(UIHelper.showAirdropCannotShare(context));
      return;
    }
    try {
      final shareMessage = 'memento_6_share_message'.tr(namedArgs: {
        'deeplink': deeplink,
      });
      await Share.share(shareMessage);
    } catch (e) {
      if (e is DioException) {
        if (mounted) {
          unawaited(UIHelper.showSharePostcardFailed(context, e));
        }
      }
    }
  }

  Widget _sendMemento6(BuildContext context, AssetToken asset) {
    final deeplink = context.watch<ArtworkDetailBloc>().state.airdropDeeplink;
    final canSend = deeplink != null && deeplink.isNotEmpty;
    if (!canSend) {
      return const SizedBox();
    }
    return PostcardButton(
      text: 'send_memento'.tr(),
      onTap: () {
        unawaited(_shareMemento(context, asset));
      },
    );
  }

  @override
  void dispose() {
    final artworkId =
        jsonEncode(widget.payload.identities[widget.payload.currentIndex]);
    unawaited(metricClient.addEvent(
      MixpanelEvent.stayInArtworkDetail,
      data: {
        'id': artworkId,
      },
    ));
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKeyboard = currentAsset?.medium == 'software' ||
        currentAsset?.medium == 'other' ||
        currentAsset?.medium == null;
    return BlocConsumer<ArtworkDetailBloc, ArtworkDetailState>(
        listener: (context, state) {
      final identitiesList = state.provenances.map((e) => e.owner).toList();
      if (state.assetToken?.artistName != null &&
          state.assetToken!.artistName!.length > 20) {
        identitiesList.add(state.assetToken!.artistName!);
      }

      identitiesList.add(state.assetToken?.owner ?? '');

      setState(() {
        currentAsset = state.assetToken;
      });
      if (withSharing && state.assetToken != null) {
        unawaited(_socialShare(context, state.assetToken!));
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

        var subTitle = '';
        if (artistName != null && artistName.isNotEmpty) {
          subTitle = artistName;
        }

        final editionSubTitle = getEditionSubTitle(asset);

        return Scaffold(
          backgroundColor: theme.colorScheme.primary,
          resizeToAvoidBottomInset: !hasKeyboard,
          appBar: AppBar(
            systemOverlayStyle: systemUiOverlayDarkStyle,
            leadingWidth: 0,
            centerTitle: false,
            title: ArtworkDetailsHeader(
              title: asset.title ?? '',
              subTitle: subTitle,
              onSubTitleTap: asset.artistID != null
                  ? () => unawaited(
                      Navigator.of(context).pushNamed(AppRouter.galleryPage,
                          arguments: GalleryPagePayload(
                            address: asset.artistID!,
                            artistName: artistName!,
                            artistURL: asset.artistURL,
                          )))
                  : null,
            ),
            actions: [
              Semantics(
                label: 'externalLink',
                child: ExternalLink(
                  link: asset.secondaryMarketURL,
                  color: AppColor.white,
                ),
              ),
              if (widget.payload.useIndexer)
                const SizedBox()
              else
                Semantics(
                  label: 'artworkDotIcon',
                  child: IconButton(
                    onPressed: () =>
                        unawaited(_showArtworkOptionsDialog(asset)),
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
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 40,
                ),
                Hero(
                  tag: 'detail_${asset.id}',
                  child: _ArtworkView(
                    payload: widget.payload,
                    token: asset,
                  ),
                ),
                _sendMemento6(context, asset),
                Visibility(
                  visible:
                      checkWeb3ContractAddress.contains(asset.contractAddress),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 40),
                      child: OutlineButton(
                        color: Colors.transparent,
                        text: 'web3_glossary'.tr(),
                        onTap: () {
                          unawaited(Navigator.pushNamed(
                              context, AppRouter.previewPrimerPage,
                              arguments: asset));
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
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
                const SizedBox(height: 16),
                Padding(
                  padding: ResponsiveLayout.getPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'Desc',
                        child: HtmlWidget(
                          customStylesBuilder: auHtmlStyle,
                          asset.description ?? '',
                          textStyle: theme.textTheme.ppMori400White14,
                        ),
                      ),
                      const SizedBox(height: 40),
                      artworkDetailsMetadataSection(context, asset, artistName),
                      if (asset.fungible) ...[
                        tokenOwnership(context, asset,
                            identityState.identityMap[asset.owner] ?? ''),
                      ] else ...[
                        if (state.provenances.isNotEmpty)
                          _provenanceView(context, state.provenances)
                        else
                          const SizedBox()
                      ],
                      artworkDetailsRightSection(context, asset),
                      const SizedBox(height: 80),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      } else {
        return const SizedBox();
      }
    });
  }

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

  bool _isHidden(AssetToken token) => injector<ConfigurationService>()
      .getTempStorageHiddenTokenIDs()
      .contains(token.id);

  Future<File> _downloadFeralfileArtwork(
    String url,
  ) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;
    final header = response.headers;
    final filename = header['x-amz-meta-filename'] ?? '';
    final file = await FileHelper.saveFileToDownloadDir(bytes, filename);
    return file;
  }

  Future<File?> _downloadArtwork(AssetToken assetToken) async {
    try {
      final artwork = await injector<FeralFileService>()
          .getArtwork(assetToken.tokenId ?? '');
      final message =
          await injector<FeralFileService>().getFeralfileActionMessage(
        address: assetToken.owner,
        action: 'download series',
      );
      final ownerAddress = assetToken.owner;
      final chain = assetToken.blockchain;
      final account = await injector<AccountService>()
          .getAccountByAddress(chain: chain, address: ownerAddress);
      final signature =
          await account.signMessage(chain: chain, message: message);
      final url =
          await injector<FeralFileService>().getFeralfileArtworkDownloadUrl(
        artworkId: artwork.id,
        signature: signature,
        owner: ownerAddress,
      );
      await _downloadFeralfileArtwork(url);
    } catch (e) {
      if (mounted) {
        unawaited(UIHelper.showFeralfileArtworkSavedFailed(context));
      }
    }

    const _url =
        'https://wetmarket-assets-testnet.s3.ap-northeast-1.amazonaws.com/artworks/0c81aae8-5060-4158-81d8-69242aaaf13d/1651131526/origin.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIARG2XGPJ66URHKXOF%2F20240207%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20240207T101843Z&X-Amz-Expires=360000&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3D%22Video%2520art.mp4%22&X-Amz-Signature=3d0dcb88a4c27e5a0fa822219b9088bcec81562d7ecb0905e8ad714c7aea5698';
    // 'https://wetmarket-assets-testnet.s3.ap-northeast-1.amazonaws.com/artworks/32d34de6-c413-426b-b370-025d90105e4d/1705314396/origin.zip?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIARG2XGPJ66URHKXOF%2F20240207%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20240207T101643Z&X-Amz-Expires=360000&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3D%22Tesst%2520AH3.zip%22&X-Amz-Signature=2d3213c30bc60857f45576f7e23abea939be064ee7424a19af57a36b078de07c';
    // 'https://wetmarket-assets-testnet.s3.ap-northeast-1.amazonaws.com/artworks/b695687e-d6ba-4992-a311-43885faa2d75/1704788689/origin/0?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIARG2XGPJ66URHKXOF%2F20240207%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20240207T101745Z&X-Amz-Expires=360000&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3D%22Check%2520time...%2520nu93_artist%22&X-Amz-Signature=4d8ef9c409b7f4eb00b71dca9b766a10f7192e8d39e5b0410c5d71654816dfd1';
    final file = await _downloadFeralfileArtwork(_url);

    return file;
  }

  Future _showArtworkOptionsDialog(AssetToken asset) async {
    final owner = await asset.getOwnerWallet();
    final ownerWallet = owner?.first;
    final addressIndex = owner?.second;

    if (!mounted) {
      return;
    }
    final isHidden = _isHidden(asset);
    unawaited(UIHelper.showDrawerAction(
      context,
      options: [
        if (asset.shouldShowDownloadArtwork)
          OptionItem(
            title: 'download_artwork'.tr(),
            icon: SvgPicture.asset('assets/images/download.svg'),
            onTap: () async {
              await _downloadArtwork(asset);
              if (!mounted) {
                return;
              }
              Navigator.of(context).pop();
              unawaited(UIHelper.showFeralfileArtworkSaved(context));
            },
          ),
        OptionItem(
          title: isHidden ? 'unhide_aw'.tr() : 'hide_aw'.tr(),
          icon: const Icon(AuIcon.hidden_artwork),
          onTap: () async {
            await injector<ConfigurationService>()
                .updateTempStorageHiddenTokenIDs([asset.id], !isHidden);
            unawaited(injector<SettingsDataService>().backup());

            if (!mounted) {
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
        if (ownerWallet != null && asset.isTransferable) ...[
          OptionItem(
            title: 'send_artwork'.tr(),
            icon: SvgPicture.asset('assets/images/Send.svg'),
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
              if (isHidden) {
                await injector<ConfigurationService>()
                    .updateTempStorageHiddenTokenIDs([asset.id], false);
                unawaited(injector<SettingsDataService>().backup());
              }
              if (!mounted) {
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

              if (!mounted) {
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
      ],
    ));
  }
}

class _ArtworkView extends StatelessWidget {
  const _ArtworkView({
    required this.payload,
    required this.token,
  });

  final ArtworkDetailPayload payload;
  final AssetToken token;

  @override
  Widget build(BuildContext context) {
    final mimeType = token.getMimeType;
    switch (mimeType) {
      case 'image':
      case 'gif':
      case 'audio':
      case 'video':
        return Stack(
          children: [
            AbsorbPointer(
              child: Center(
                child: IntrinsicHeight(
                  child: ArtworkPreviewWidget(
                    identity: payload.identities[payload.currentIndex],
                    isMute: true,
                    useIndexer: payload.useIndexer,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  unawaited(Navigator.of(context).pushNamed(
                      AppRouter.artworkPreviewPage,
                      arguments: payload));
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        );

      default:
        return AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              Center(
                child: ArtworkPreviewWidget(
                  identity: payload.identities[payload.currentIndex],
                  isMute: true,
                  useIndexer: payload.useIndexer,
                ),
              ),
              GestureDetector(
                onTap: () {
                  unawaited(Navigator.of(context).pushNamed(
                      AppRouter.artworkPreviewPage,
                      arguments: payload));
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class ArtworkDetailPayload {
  final Key? key;
  final List<ArtworkIdentity> identities;
  final int currentIndex;
  final PlayControlModel? playControl;
  final String? twitterCaption;
  final bool useIndexer; // set true when navigate from discover/gallery page

  ArtworkDetailPayload(
    this.identities,
    this.currentIndex, {
    this.twitterCaption,
    this.playControl,
    this.useIndexer = false,
    this.key,
  });

  ArtworkDetailPayload copyWith(
          {List<ArtworkIdentity>? ids,
          int? currentIndex,
          PlayControlModel? playControl,
          String? twitterCaption,
          bool? useIndexer}) =>
      ArtworkDetailPayload(
        ids ?? identities,
        currentIndex ?? this.currentIndex,
        twitterCaption: twitterCaption ?? this.twitterCaption,
        playControl: playControl ?? this.playControl,
        useIndexer: useIndexer ?? this.useIndexer,
      );
}

@JsonSerializable()
class ArtworkIdentity {
  final String id;
  final String owner;

  ArtworkIdentity(this.id, this.owner);

  factory ArtworkIdentity.fromJson(Map<String, dynamic> json) =>
      _$ArtworkIdentityFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkIdentityToJson(this);

  String get key => '$id||$owner';
}
