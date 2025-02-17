//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:collection';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_state.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/keyboard_control_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/feral_file_custom_tab.dart';
import 'package:autonomy_flutter/util/metric_helper.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/webview_controller_text_field.dart';
import 'package:backdrop/backdrop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:shake/shake.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

part 'artwork_detail_page.g.dart';

class ArtworkDetailPage extends StatefulWidget {
  const ArtworkDetailPage({required this.payload, super.key});

  final ArtworkDetailPayload payload;

  @override
  State<ArtworkDetailPage> createState() => _ArtworkDetailPageState();
}

class _ArtworkDetailPageState extends State<ArtworkDetailPage>
    with
        AfterLayoutMixin<ArtworkDetailPage>,
        RouteAware,
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver {
  ScrollController? _scrollController;
  ValueNotifier<double> downloadProgress = ValueNotifier(0);

  HashSet<String> _accountNumberHash = HashSet.identity();
  AssetToken? currentAsset;
  final _focusNode = FocusNode();
  final _textController = TextEditingController();
  WebViewController? _webViewController;
  bool _isInfoExpand = false;
  static const _infoShrinkPosition = 0.001;
  static const _infoExpandPosition = 0.29;
  late ArtworkDetailBloc _bloc;
  late CanvasDeviceBloc _canvasDeviceBloc;
  late AnimationController _animationController;
  double? _appBarBottomDy;
  bool _isFullScreen = false;
  ShakeDetector? _detector;

  final FocusNode _selectTextFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
      value: _infoShrinkPosition,
      upperBound: _infoExpandPosition,
    );
    _infoShrink();
    _bloc = context.read<ArtworkDetailBloc>();
    _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
    _bloc.add(
      ArtworkDetailGetInfoEvent(
        widget.payload.identity,
        useIndexer: widget.payload.useIndexer,
      ),
    );
    context.read<AccountsBloc>().add(FetchAllAddressesEvent());
    context.read<AccountsBloc>().add(GetAccountsEvent());
  }

  @override
  void afterFirstLayout(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    _appBarBottomDy ??= MediaQuery.of(context).padding.top + kToolbarHeight;
    _detector = ShakeDetector.autoStart(
      onPhoneShake: () async {
        await _exitFullScreen();
      },
    );
    _sendMetricPlaylistView();
  }

  void _sendMetricPlaylistView() {
    final data = {
      MetricParameter.tokenId: widget.payload.identity.id,
    };
    unawaited(
      injector<MetricClientService>()
          .addEvent(MetricEventName.playlistView, data: data),
    );
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  List<String> getTags(AssetToken asset) {
    final defaultTags = [
      'feralfile',
      'digitalartwallet',
      'NFT',
    ];
    var tags = defaultTags;
    if (asset.isMoMAMemento) {
      tags = [
        'refikunsupervised',
        'feralfileapp',
      ];
    }
    return tags;
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    _textController.dispose();
    unawaited(disableLandscapeMode());
    unawaited(WakelockPlus.disable());
    _detector?.stopListening();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    super.dispose();
  }

  void _infoShrink() {
    setState(() {
      _isInfoExpand = false;
    });
    _selectTextFocusNode.unfocus();
    _animationController.animateTo(_infoShrinkPosition);
  }

  void _infoExpand() {
    _scrollController?.jumpTo(0);
    if (_scrollController == null) {
      _initScrollController();
    }
    setState(() {
      _isInfoExpand = true;
    });
    _animationController.animateTo(_infoExpandPosition);
  }

  void _initScrollController() {
    _scrollController = ScrollController();
    _scrollController!.addListener(() {
      if (_scrollController!.position.pixels < -20 && _isInfoExpand) {
        _infoShrink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        context.read<IdentityBloc>().add(GetIdentityEvent(identitiesList));
      },
      builder: (context, state) {
        if (state.assetToken == null) {
          return const LoadingWidget();
        }
        final identityState = context.watch<IdentityBloc>().state;
        final asset = state.assetToken!;
        final artistName =
            asset.artistName?.toIdentityOrMask(identityState.identityMap);

        return BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
          bloc: _canvasDeviceBloc,
          builder: (context, canvasState) => Stack(
            children: [
              BackdropScaffold(
                backgroundColor: AppColor.primaryBlack,
                resizeToAvoidBottomInset: !hasKeyboard,
                frontLayerElevation: _isFullScreen ? 0 : 1,
                appBar: _isFullScreen
                    ? null
                    : PreferredSize(
                        preferredSize: const Size.fromHeight(kToolbarHeight),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: AppBar(
                            systemOverlayStyle: systemUiOverlayDarkStyle,
                            leading: Semantics(
                              label: 'BACK',
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                constraints: const BoxConstraints(
                                  maxWidth: 44,
                                  maxHeight: 44,
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                icon: Padding(
                                  padding: EdgeInsets.zero,
                                  child: SvgPicture.asset(
                                    'assets/images/ff_back_dark.svg',
                                    width: 28,
                                    height: 28,
                                  ),
                                ),
                              ),
                            ),
                            centerTitle: false,
                            backgroundColor: Colors.transparent,
                            actions: [
                              FFCastButton(
                                displayKey: _getDisplayKey(asset),
                                onDeviceSelected: (device) async {
                                  final artwork = PlayArtworkV2(
                                    token: CastAssetToken(id: asset.id),
                                    duration: 0,
                                  );
                                  final completer = Completer<void>();
                                  _canvasDeviceBloc.add(
                                    CanvasDeviceCastListArtworkEvent(
                                        device, [artwork],
                                        completer: completer),
                                  );
                                  await completer.future;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                backLayer: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ArtworkPreviewWidget(
                        useIndexer: widget.payload.useIndexer,
                        identity: widget.payload.identity,
                        onLoaded: _onLoaded,
                      ),
                    ),
                    if (!_isFullScreen)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: ArtworkDetailsHeader(
                          title: 'I',
                          subTitle: 'I',
                          color: Colors.transparent,
                        ),
                      ),
                  ],
                ),
                reverseAnimationCurve: Curves.ease,
                frontLayer: _isFullScreen
                    ? const SizedBox()
                    : _infoContent(context, identityState, state, artistName),
                frontLayerBackgroundColor:
                    _isFullScreen ? Colors.transparent : AppColor.primaryBlack,
                backLayerBackgroundColor: AppColor.primaryBlack,
                animationController: _animationController,
                revealBackLayerAtStart: true,
                frontLayerScrim: Colors.transparent,
                backLayerScrim: Colors.transparent,
                subHeaderAlwaysActive: false,
                frontLayerShape: const BeveledRectangleBorder(),
                subHeader: _isFullScreen
                    ? null
                    : DecoratedBox(
                        decoration:
                            const BoxDecoration(color: AppColor.primaryBlack),
                        child: GestureDetector(
                          onVerticalDragEnd: (details) {
                            final dy = details.primaryVelocity ?? 0;
                            if (dy <= 0) {
                              _infoExpand();
                            } else {
                              _infoShrink();
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: _infoHeader(
                              context,
                              asset,
                              artistName,
                              canvasState,
                            ),
                          ),
                        ),
                      ),
              ),
              if (_isInfoExpand && !_isFullScreen)
                Positioned(
                  top: _appBarBottomDy ?? 80,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _infoShrink,
                    onVerticalDragEnd: (details) {
                      final dy = details.primaryVelocity ?? 0;
                      if (dy > 0) {
                        _infoShrink();
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      height: MediaQuery.of(context).size.height / 2 -
                          (_appBarBottomDy ?? 80),
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getDisplayKey(AssetToken asset) => asset.displayKey;

  Widget _artworkInfoIcon() => Semantics(
        label: 'artworkInfoIcon',
        child: IconButton(
          onPressed: () {
            _isInfoExpand ? _infoShrink() : _infoExpand();
          },
          constraints: const BoxConstraints(
            maxWidth: 44,
            maxHeight: 44,
            minWidth: 44,
            minHeight: 44,
          ),
          icon: SvgPicture.asset(
            !_isInfoExpand
                ? 'assets/images/info_white.svg'
                : 'assets/images/info_white_active.svg',
            width: 22,
            height: 22,
          ),
        ),
      );

  dynamic _onLoaded({WebViewController? webViewController, int? time}) {
    _webViewController = webViewController;
  }

  Widget _infoHeader(
    BuildContext context,
    AssetToken asset,
    String? artistName,
    CanvasDeviceState canvasState,
  ) {
    var subTitle = '';
    if (artistName != null && artistName.isNotEmpty) {
      subTitle = artistName;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 5, 20),
      child: Row(
        children: [
          Expanded(
            child: ArtworkDetailsHeader(
              title: asset.displayTitle ?? '',
              subTitle: subTitle,
              onSubTitleTap: asset.artistID != null && asset.isFeralfile
                  ? () => unawaited(
                        injector<NavigationService>()
                            .openFeralFileArtistPage(asset.artistID!),
                      )
                  : null,
            ),
          ),
          _artworkInfoIcon(),
          Semantics(
            label: 'artworkDotIcon',
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: IconButton(
                onPressed: () async => _showArtworkOptionsDialog(
                  context,
                  asset,
                  canvasState,
                ),
                constraints: const BoxConstraints(
                  maxWidth: 44,
                  maxHeight: 44,
                  minWidth: 44,
                  minHeight: 44,
                ),
                icon: SvgPicture.asset(
                  'assets/images/more_circle.svg',
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoContent(
    BuildContext context,
    IdentityState identityState,
    ArtworkDetailState state,
    String? artistName,
  ) {
    final theme = Theme.of(context);
    final asset = state.assetToken!;
    final editionSubTitle = getEditionSubTitle(asset);
    return Stack(
      children: [
        Visibility(
          visible: _isOpenedWithWebview(asset),
          child: WebviewControllerTextField(
            webViewController: _webViewController,
            focusNode: _focusNode,
            textController: _textController,
            disableKeys: asset.disableKeys,
          ),
        ),
        SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Visibility(
                  visible:
                      checkWeb3ContractAddress.contains(asset.contractAddress),
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                    child: OutlineButton(
                      color: Colors.transparent,
                      text: 'web3_glossary'.tr(),
                      onTap: () {
                        unawaited(
                          Navigator.pushNamed(
                            context,
                            AppRouter.previewPrimerPage,
                            arguments: asset,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Visibility(
                  visible: editionSubTitle.isNotEmpty,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: ResponsiveLayout.getPadding,
                      child: Text(
                        editionSubTitle,
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                    ),
                  ),
                ),
                debugInfoWidget(context, currentAsset),
                Padding(
                  padding: ResponsiveLayout.getPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'Desc',
                        child: SelectionArea(
                          focusNode: _selectTextFocusNode,
                          child: HtmlWidget(
                            customStylesBuilder: auHtmlStyle,
                            asset.description ?? '',
                            textStyle: theme.textTheme.ppMori400White14,
                            onTapUrl: (url) async {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                              return true;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      artworkDetailsMetadataSection(context, asset, artistName),
                      if (asset.fungible) ...[
                        tokenOwnership(
                          context,
                          asset,
                          identityState.identityMap[asset.owner] ?? '',
                        ),
                      ] else ...[
                        if (state.provenances.isNotEmpty)
                          _provenanceView(context, state.provenances)
                        else
                          const SizedBox(),
                      ],
                      artworkDetailsRightSection(context, asset),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5 -
                      (_appBarBottomDy ?? 80),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _provenanceView(BuildContext context, List<Provenance> provenances) =>
      BlocBuilder<IdentityBloc, IdentityState>(
        builder: (context, identityState) =>
            BlocBuilder<AccountsBloc, AccountsState>(
          builder: (context, accountsState) {
            final addresses = accountsState.addresses?.map((e) => e.address);
            if (addresses?.isNotEmpty == true) {
              _accountNumberHash = HashSet.of(addresses!);
            }

            return artworkDetailsProvenanceSectionNotEmpty(
              context,
              provenances,
              _accountNumberHash,
              identityState.identityMap,
            );
          },
        ),
      );

  bool _isHidden(AssetToken token) => injector<ConfigurationService>()
      .getTempStorageHiddenTokenIDs()
      .contains(token.id);

  Future<void> _showArtworkOptionsDialog(
    BuildContext context,
    AssetToken asset,
    CanvasDeviceState canvasDeviceState,
  ) async {
    final showKeyboard = _isOpenedWithWebview(asset);
    final castingDevice =
        canvasDeviceState.lastSelectedActiveDeviceForKey(_getDisplayKey(asset));
    final connectedDevice =
        injector<FFBluetoothService>().castingBluetoothDevice;
    final isCasting = connectedDevice != null;
    final hasLocalAddress = await asset.hasLocalAddress();
    if (!context.mounted) {
      return;
    }
    final isHidden = _isHidden(asset);
    _focusNode.unfocus();

    unawaited(
      UIHelper.showDrawerAction(
        context,
        options: [
          OptionItem(
            title: 'full_screen'.tr(),
            icon: SvgPicture.asset('assets/images/fullscreen_icon.svg'),
            onTap: () {
              Navigator.of(context).pop();
              _setFullScreen();
            },
          ),
          if (showKeyboard && isCasting)
            OptionItem(
              title: 'interact'.tr(),
              icon: SvgPicture.asset('assets/images/keyboard_icon.svg'),
              onTap: () {
                Navigator.of(context).pop();
                final castingDevice = canvasDeviceState
                    .lastSelectedActiveDeviceForKey(_getDisplayKey(asset));
                final bluetoothConnectedDevice =
                    injector<FFBluetoothService>().castingBluetoothDevice;
                if (castingDevice != null || bluetoothConnectedDevice != null) {
                  unawaited(
                    Navigator.of(context).pushNamed(
                      AppRouter.keyboardControlPage,
                      arguments: KeyboardControlPagePayload(
                        getEditionSubTitle(asset),
                        asset.description ?? '',
                        [bluetoothConnectedDevice ?? castingDevice!],
                      ),
                    ),
                  );
                } else {
                  FocusScope.of(context).requestFocus(_focusNode);
                }
              },
            ),
          if (asset.secondaryMarketURL.isNotEmpty)
            OptionItem(
              title: 'view_on_'.tr(args: [asset.secondaryMarketName]),
              icon: SvgPicture.asset(
                'assets/images/external_link_white.svg',
                width: 18,
                height: 18,
              ),
              onTap: () async {
                final browser = FeralFileBrowser();
                await browser.openUrl(asset.secondaryMarketURL);
              },
            ),
          if (widget.payload.shouldUseLocalCache && hasLocalAddress)
            OptionItem(
              title: isHidden ? 'unhide_aw'.tr() : 'hide_aw'.tr(),
              icon: SvgPicture.asset('assets/images/hide_artwork_white.svg'),
              onTap: () async {
                await injector<ConfigurationService>()
                    .updateTempStorageHiddenTokenIDs([asset.id], !isHidden);
                unawaited(injector<SettingsDataService>().backupUserSettings());

                if (!context.mounted) {
                  return;
                }
                NftCollectionBloc.eventController.add(ReloadEvent());
                Navigator.of(context).pop();
                unawaited(
                  UIHelper.showHideArtworkResultDialog(
                    context,
                    !isHidden,
                    onOK: () {
                      Navigator.of(context).popUntil(
                        (route) =>
                            route.settings.name == AppRouter.homePage ||
                            route.settings.name ==
                                AppRouter.homePageNoTransition,
                      );
                    },
                  ),
                );
              },
            ),
          if (!widget.payload.shouldUseLocalCache)
            OptionItem(
              title: 'refresh_metadata'.tr(),
              icon: SvgPicture.asset(
                'assets/images/refresh_metadata_white.svg',
                width: 20,
                height: 20,
              ),
              onTap: () async {
                await injector<TokensService>().fetchManualTokens([asset.id]);
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
                await Navigator.of(context).pushReplacementNamed(
                  AppRouter.artworkDetailsPage,
                  arguments: widget.payload.copyWith(),
                );
              },
            ),
          OptionItem.emptyOptionItem,
        ],
      ),
    );
  }

  bool _isOpenedWithWebview(AssetToken asset) =>
      asset.medium == 'software' ||
      asset.medium == 'other' ||
      (asset.medium?.isEmpty ?? true);

  Future<void> _setFullScreen() async {
    unawaited(_openSnackBar(context));
    if (_isInfoExpand) {
      _infoShrink();
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await enableLandscapeMode();
    unawaited(WakelockPlus.enable());
    setState(() {
      _isFullScreen = true;
    });
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    unawaited(WakelockPlus.disable());
    await disableLandscapeMode();
    setState(() {
      _isFullScreen = false;
    });
  }

  Future<void> _openSnackBar(BuildContext context) async {
    await UIHelper.openSnackBarExistFullScreen(context);
  }
}

class ArtworkDetailPayload {
  ArtworkDetailPayload(
    this.identity, {
    this.playlist,
    this.useIndexer = false,
    this.shouldUseLocalCache = true,
    this.key,
  });

  final Key? key;
  final ArtworkIdentity identity;
  final PlayListModel? playlist;
  final bool useIndexer; // set true when navigate from discover/gallery page
  // if local token, it can be hidden and refresh metadata
  final bool shouldUseLocalCache;

  ArtworkDetailPayload copyWith({
    ArtworkIdentity? identity,
    PlayListModel? playlist,
    bool? useIndexer,
    bool? shouldUseLocalCache,
  }) =>
      ArtworkDetailPayload(
        identity ?? this.identity,
        playlist: playlist ?? this.playlist,
        useIndexer: useIndexer ?? this.useIndexer,
        shouldUseLocalCache: shouldUseLocalCache ?? this.shouldUseLocalCache,
      );
}

@JsonSerializable()
class ArtworkIdentity {
  ArtworkIdentity(this.id, this.owner);

  factory ArtworkIdentity.fromJson(Map<String, dynamic> json) =>
      _$ArtworkIdentityFromJson(json);
  final String id;
  final String owner;

  Map<String, dynamic> toJson() => _$ArtworkIdentityToJson(this);

  String get key => '$id||$owner';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ArtworkIdentity && id == other.id && owner == other.owner;
  }

  @override
  int get hashCode => id.hashCode ^ owner.hashCode;
}
