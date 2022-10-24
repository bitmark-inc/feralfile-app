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
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:metric_client/metric_client.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_collection/nft_collection.dart';

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
  void afterFirstLayout(BuildContext context) async {
    final metricClient = injector.get<MetricClientService>();
    await metricClient.addEvent(
      "view_artwork_detail",
      data: {
        "id":
        jsonEncode(widget.payload.identities[widget.payload.currentIndex]),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          appBar: getBackAppBar(context,
              onBack: () => Navigator.of(context).pop(),
              action: () {
                if (currentAsset == null) return;
                _showArtworkOptionsDialog(currentAsset!);
              }),
          body: BlocConsumer<ArtworkDetailBloc, ArtworkDetailState>(
              listener: (context, state) {
                final identitiesList =
                state.provenances.map((e) => e.owner).toList();
                if (state.asset?.artistName != null &&
                    state.asset!.artistName!.length > 20) {
                  identitiesList.add(state.asset!.artistName!);
                }
                setState(() {
                  currentAsset = state.asset;
                });

                context.read<IdentityBloc>().add(
                    GetIdentityEvent(identitiesList));
              }, builder: (context, state) {
            if (state.asset != null) {
              final identityState = context
                  .watch<IdentityBloc>()
                  .state;
              final asset = state.asset!;

              final artistName =
              asset.artistName?.toIdentityOrMask(identityState.identityMap);

              var subTitle = "";
              if (artistName != null && artistName.isNotEmpty) {
                subTitle = "by".tr(args: [artistName]);
              }

              return SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16.0),
                    Padding(
                      padding: ResponsiveLayout.getPadding,
                      child: Semantics(
                        label: 'Title',
                        child: Text(
                          asset.title,
                          style: theme.textTheme.headline1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: ResponsiveLayout.getPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              subTitle,
                              style: theme.textTheme.headline3?.copyWith(
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            getEditionSubTitle(asset),
                            style: theme.textTheme.headline5?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    GestureDetector(
                        child: TokenThumbnailWidget(
                          token: asset,
                          onHideArtwork: () {
                            _showArtworkOptionsDialog(asset);
                          },
                        ),
                        onTap: () {
                          if (injector<ConfigurationService>()
                              .isImmediateInfoViewEnabled()) {
                            Navigator.of(context).pushNamed(
                                AppRouter.artworkPreviewPage,
                                arguments: widget.payload);
                          } else {
                            Navigator.of(context).pop();
                          }
                        }),
                    debugInfoWidget(context, currentAsset),
                    const SizedBox(height: 16.0),
                    Padding(
                      padding: ResponsiveLayout.getPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 165,
                            height: 48,
                            child: AuOutlinedButton(
                              text: "view_artwork".tr(),
                              onPress: () {
                                if (injector<ConfigurationService>()
                                    .isImmediateInfoViewEnabled()) {
                                  Navigator.of(context).pushNamed(
                                      AppRouter.artworkPreviewPage,
                                      arguments: widget.payload);
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 40.0),
                          Semantics(
                            label: 'Desc',
                            child: Text(
                              unescape.convert(asset.desc ?? ""),
                              style: theme.textTheme.bodyText1,
                            ),
                          ),
                          artworkDetailsRightSection(context, asset),
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
                          ] else
                            ...[
                              state.provenances.isNotEmpty
                                  ? _provenanceView(context, state.provenances)
                                  : const SizedBox()
                            ],
                          const SizedBox(height: 80.0),
                        ],
                      ),
                    )
                  ],
                ),
              );
            } else {
              return const SizedBox();
            }
          }),
        ),
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

                return artworkDetailsProvenanceSectionNotEmpty(
                    context, provenances,
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
    final theme = Theme.of(context);

    Widget optionRow({required String title, Function()? onTap}) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.primaryTextTheme.headline4),
              Icon(Icons.navigate_next, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      );
    }

    final ownerWallet = await asset.getOwnerWallet();

    if (!mounted) return;
    final isHidden = _isHidden(asset);
    UIHelper.showDialog(
      context,
      "Options",
      Column(
        children: [
          optionRow(
            title: isHidden ? 'unhide_aw'.tr() : 'hide_aw'.tr(),
            onTap: () async {
              await injector<ConfigurationService>()
                  .updateTempStorageHiddenTokenIDs([asset.id], !isHidden);
              injector<SettingsDataService>().backup();

              if (!mounted) return;

              context.read<NftCollectionBloc>().add(RefreshNftCollection());
              Navigator.of(context).pop();
              UIHelper.showHideArtworkResultDialog(context, !isHidden,
                  onOK: () {
                    Navigator.of(context).popUntil((route) =>
                    route.settings.name == AppRouter.homePage ||
                        route.settings.name == AppRouter.homePageNoTransition);
                  });
            },
          ),
          if (ownerWallet != null) ...[
            Divider(
              color: theme.colorScheme.secondary,
              height: 1,
              thickness: 1,
            ),
            optionRow(
              title: "send_artwork".tr(),
              onTap: () async {
                final payload = await Navigator.of(context).popAndPushNamed(
                    AppRouter.sendArtworkPage,
                    arguments: SendArtworkPayload(asset, ownerWallet,
                        await ownerWallet.getOwnedQuantity(asset))) as Map?;
                if (payload == null || !payload["isTezos"]) {
                  return;
                }

                if (!mounted) return;
                final tx = payload['tx'] as TZKTOperation;
                final isSentAll = payload['isSentAll'] as bool;
                if (isSentAll) {
                  injector<ConfigurationService>().updateRecentlySentToken([
                    SentArtwork(asset.id, asset.ownerAddress, DateTime.now())
                  ]);
                }
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
                  onClose: () =>
                  isSentAll
                      ? Navigator.of(context).popAndPushNamed(
                    AppRouter.homePage,)
                      : null,
                );
              },
            ),
            const SizedBox(
              height: 18,
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "cancel".tr(),
                style: theme.primaryTextTheme.caption,
              ),
            ),
          ],
        ],
      ),
      isDismissible: true,
    );
  }
}

class ArtworkDetailPayload {
  final List<ArtworkIdentity> identities;
  final int currentIndex;

  ArtworkDetailPayload(this.identities, this.currentIndex);

  ArtworkDetailPayload copyWith({
    List<ArtworkIdentity>? ids,
    int? currentIndex,
  }) {
    return ArtworkDetailPayload(
      ids ?? this.identities,
      currentIndex ?? this.currentIndex,
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
