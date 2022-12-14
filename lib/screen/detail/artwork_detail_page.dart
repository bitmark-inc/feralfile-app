//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:collection';
import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_collection/nft_collection.dart';

import '../../service/mixPanel_client_service.dart';

part 'artwork_detail_page.g.dart';

class ArtworkDetailPage extends StatefulWidget {
  final ArtworkDetailPayload payload;

  const ArtworkDetailPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<ArtworkDetailPage> createState() => _ArtworkDetailPageState();
}

class _ArtworkDetailPageState extends State<ArtworkDetailPage>
    with AfterLayoutMixin<ArtworkDetailPage> {
  late ScrollController _scrollController;
  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;
  final mixPanelClient = injector.get<MixPanelClientService>();

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
    context.read<ArtworkDetailBloc>().add(ArtworkDetailGetInfoEvent(
        widget.payload.identities[widget.payload.currentIndex]));
    context.read<AccountsBloc>().add(FetchAllAddressesEvent());
    context.read<AccountsBloc>().add(GetAccountsEvent());
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final artworkId =
        jsonEncode(widget.payload.identities[widget.payload.currentIndex]);
    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent(
      "view_artwork_detail",
      data: {
        "id": artworkId,
      },
    );

    mixPanelClient.trackEvent(
      MixpanelEvent.viewArtwork,
      data: {
        "id": artworkId,
      },
    );
    mixPanelClient.timerEvent(
      MixpanelEvent.aliveInArtworkDetail,
    );
  }

  @override
  void dispose() {
    final artworkId =
        jsonEncode(widget.payload.identities[widget.payload.currentIndex]);
    mixPanelClient.trackEvent(
      MixpanelEvent.aliveInArtworkDetail,
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
    final hasKeyboard = currentAsset?.medium == "software" ||
        currentAsset?.medium == "other" ||
        currentAsset?.medium == null;
    return BlocConsumer<ArtworkDetailBloc, ArtworkDetailState>(
        listener: (context, state) {
      final identitiesList = state.provenances.map((e) => e.owner).toList();
      if (state.asset?.artistName != null &&
          state.asset!.artistName!.length > 20) {
        identitiesList.add(state.asset!.artistName!);
      }
      setState(() {
        currentAsset = state.asset;
      });

      context.read<IdentityBloc>().add(GetIdentityEvent(identitiesList));
    }, builder: (context, state) {
      if (state.asset != null) {
        final identityState = context.watch<IdentityBloc>().state;
        final asset = state.asset!;

        final artistName =
            asset.artistName?.toIdentityOrMask(identityState.identityMap);

        var subTitle = "";
        if (artistName != null && artistName.isNotEmpty) {
          subTitle = "by".tr(args: [artistName]);
        }

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
                        asset.title,
                        style: theme.textTheme.ppMori400White12,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subTitle,
                        style: theme.textTheme.ppMori400White12,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => _showArtworkOptionsDialog(asset),
                      icon: SvgPicture.asset(
                        'assets/images/more_circle.svg',
                        width: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        AuIcon.close,
                        color: theme.colorScheme.secondary,
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
                        tag: asset.id,
                        child: _ArtworkView(
                          payload: widget.payload,
                          token: asset,
                        ),
                      ),
                      Visibility(
                        visible: asset.assetURL == CHECK_WEB3_PRIMER_URL,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: 165,
                              height: 48,
                              child: AuOutlinedButton(
                                text: "web3_primer".tr(),
                                onPress: () {
                                  Navigator.pushNamed(
                                      context, AppRouter.previewPrimerPage,
                                      arguments: asset);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      Padding(
                        padding: ResponsiveLayout.getPadding,
                        child: Text(
                          getEditionSubTitle(asset),
                          style: theme.textTheme.ppMori400Grey12,
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
                                asset.desc ?? "",
                                textStyle: theme.textTheme.ppMori400White12,
                              ),
                            ),
                            const SizedBox(height: 40.0),
                            artworkDetailsMetadataSection(
                                context, asset, artistName),
                            if (asset.fungible == true) ...[
                              const SizedBox(height: 40.0),
                              BlocBuilder<AccountsBloc, AccountsState>(
                                builder: (context, state) {
                                  final addresses = state.addresses;
                                  return tokenOwnership(
                                      context, asset, addresses);
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
                  ),
                )),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ReportButton(
                token: currentAsset,
                scrollController: _scrollController,
              ),
            ),
          ],
        );
      } else {
        return const SizedBox();
      }
    });
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
    final ownerWallet = await asset.getOwnerWallet();

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

            context.read<NftCollectionBloc>().add(RefreshNftCollection());
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
                  arguments: SendArtworkPayload(asset, ownerWallet,
                      await ownerWallet.getOwnedQuantity(asset))) as Map?;
              if (payload == null) {
                return;
              }

              final isSentAll = payload['isSentAll'] as bool;
              if (isSentAll) {
                injector<ConfigurationService>().updateRecentlySentToken([
                  SentArtwork(asset.id, asset.ownerAddress, DateTime.now())
                ]);
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
                actionButton: 'see_transaction_detail'.tr().toUpperCase(),
                closeButton: "close".tr().toUpperCase(),
                onClose: () => isSentAll
                    ? Navigator.of(context).popAndPushNamed(
                        AppRouter.homePage,
                      )
                    : null,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ArtworkView extends StatelessWidget {
  const _ArtworkView({
    Key? key,
    required this.payload,
    required this.token,
  }) : super(key: key);

  final ArtworkDetailPayload payload;
  final AssetToken token;

  @override
  Widget build(BuildContext context) {
    final mimeType = token.getMimeType;
    switch (mimeType) {
      case "image":
      case "svg":
      case 'gif':
      case "audio":
      case "video":
        return Stack(
          children: [
            AbsorbPointer(
              child: Center(
                child: IntrinsicHeight(
                  child: ArtworkPreviewWidget(
                    identity: payload.identities[payload.currentIndex],
                    isMute: true,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.artworkPreviewPage,
                      arguments: payload);
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
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.artworkPreviewPage,
                      arguments: payload);
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
  final List<ArtworkIdentity> identities;
  final int currentIndex;
  final bool isPlaylist;

  ArtworkDetailPayload(this.identities, this.currentIndex,
      {this.isPlaylist = false});

  ArtworkDetailPayload copyWith(
      {List<ArtworkIdentity>? ids, int? currentIndex, bool? isPlaylist}) {
    return ArtworkDetailPayload(
      ids ?? identities,
      currentIndex ?? this.currentIndex,
      isPlaylist: isPlaylist ?? this.isPlaylist,
    );
  }
}

@JsonSerializable()
class ArtworkIdentity {
  final String id;
  final String owner;

  ArtworkIdentity(this.id, this.owner);

  factory ArtworkIdentity.fromJson(Map<String, dynamic> json) =>
      _$ArtworkIdentityFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkIdentityToJson(this);
}
