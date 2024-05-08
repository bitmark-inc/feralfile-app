import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_state.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/iterable_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/token_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/stream_common_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';

enum CollectionType { manual, medium, artist }

class ViewPlaylistScreenPayload {
  final PlayListModel? playListModel;
  final CollectionType collectionType;
  final Widget? titleIcon;

  const ViewPlaylistScreenPayload(
      {this.playListModel,
      this.titleIcon,
      this.collectionType = CollectionType.manual});
}

class ViewPlaylistScreen extends StatefulWidget {
  final ViewPlaylistScreenPayload payload;

  const ViewPlaylistScreen({required this.payload, super.key});

  @override
  State<ViewPlaylistScreen> createState() => _ViewPlaylistScreenState();
}

class _ViewPlaylistScreenState extends State<ViewPlaylistScreen> {
  final bloc = injector.get<ViewPlaylistBloc>();
  final nftBloc = injector.get<NftCollectionBloc>(param1: false);
  final _playlistService = injector<PlaylistService>();
  List<ArtworkIdentity> accountIdentities = [];
  List<CompactedAssetToken> tokensPlaylist = [];
  bool isDemo = injector.get<ConfigurationService>().isDemoArtworksMode();
  final _focusNode = FocusNode();
  late CanvasDeviceBloc _canvasDeviceBloc;
  late SortOrder _sortOrder;
  late bool editable;
  final _canvasClientServiceV2 = injector<CanvasClientServiceV2>();

  List<SortOrder> _getAvailableOrders() {
    switch (widget.payload.collectionType) {
      case CollectionType.artist:
        return [
          SortOrder.title,
          SortOrder.newest,
        ];
      case CollectionType.medium:
        return [
          SortOrder.title,
          SortOrder.artist,
          SortOrder.newest,
        ];
      default:
        return [
          SortOrder.manual,
          SortOrder.title,
          SortOrder.artist,
        ];
    }
  }

  @override
  void initState() {
    _sortOrder = _getAvailableOrders().first;
    editable = widget.payload.collectionType == CollectionType.manual &&
        !(widget.payload.playListModel?.isDefault ?? true);
    super.initState();

    nftBloc.add(RefreshNftCollectionByIDs(
      ids: isDemo ? [] : widget.payload.playListModel?.tokenIDs,
      debugTokenIds: isDemo ? widget.payload.playListModel?.tokenIDs : [],
    ));

    _canvasDeviceBloc = context.read<CanvasDeviceBloc>();
    unawaited(_fetchDevice());
    bloc.add(GetPlayList(playListModel: widget.payload.playListModel));
  }

  Future<void> deletePlayList() async {
    final listPlaylist = await _playlistService.getPlayList();
    listPlaylist.removeWhere(
        (element) => element.id == widget.payload.playListModel?.id);
    await _playlistService.setPlayList(listPlaylist, override: true);
    unawaited(injector.get<SettingsDataService>().backup());
    injector<NavigationService>().popUntilHomeOrSettings();
  }

  List<CompactedAssetToken> setupPlayList({
    required List<CompactedAssetToken> tokens,
    List<String>? selectedTokens,
  }) {
    tokens = tokens.filterAssetToken();

    final temp = selectedTokens
            ?.map((e) =>
                tokens.where((element) => element.id == e).firstOrDefault())
            .toList() ??
        []
      ..removeWhere((element) => element == null);

    tokensPlaylist = List.from(temp)
      ..sort((a, b) {
        final x = _sortOrder.compare(a, b);
        return x;
      });

    accountIdentities = tokensPlaylist
        .where((e) => e.pending != true || e.hasMetadata)
        .map((element) => ArtworkIdentity(element.id, element.owner))
        .toList();
    return tokensPlaylist;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onSelectOrder(SortOrder order) {
    setState(() {
      _sortOrder = order;
    });
  }

  Future<void> _onOrderTap(BuildContext context, List<SortOrder> orders) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.isMobile
              ? double.infinity
              : Constants.maxWidthModalTablet),
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => Container(
                color: AppColor.feralFileHighlight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 17, 15, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3, left: 37),
                              child: Text(
                                'sort_by'.tr(),
                                style: theme.textTheme.ppMori400Black14,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 28,
                              width: 28,
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                padding: const EdgeInsets.all(0),
                                icon: const Icon(
                                  AuIcon.close,
                                  size: 18,
                                  color: AppColor.primaryBlack,
                                  weight: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    addOnlyDivider(color: AppColor.white),
                    const SizedBox(height: 20),
                    ListView.separated(
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _onSelectOrder(order);
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: Row(
                                children: [
                                  AuRadio<SortOrder>(
                                    onTap: (order) {
                                      Navigator.pop(context);
                                      _onSelectOrder(order);
                                    },
                                    value: order,
                                    groupValue: _sortOrder,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      order.text,
                                      style: theme.textTheme.ppMori400Black14,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: orders.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: 15),
                    ),
                    const SizedBox(height: 65),
                  ],
                ),
              )),
    );
  }

  Future<void> _onMoreTap(BuildContext context, PlayListModel? playList) async {
    final theme = Theme.of(context);
    await UIHelper.showDrawerAction(
      context,
      options: [
        OptionItem(
          title: 'edit_collection'.tr(),
          icon: SvgPicture.asset(
            'assets/images/rename_icon.svg',
            width: 24,
          ),
          onTap: () {
            Navigator.pop(context);
            if (isDemo) {
              return;
            }
            Navigator.pushNamed(
              context,
              AppRouter.editPlayListPage,
              arguments: playList,
            );
          },
        ),
        OptionItem(
          title: 'delete_collection'.tr(),
          icon: SvgPicture.asset(
            'assets/images/delete_icon.svg',
            width: 24,
          ),
          onTap: () {
            Navigator.pop(context);
            UIHelper.showMessageActionNew(
              context,
              tr('delete_playlist'),
              '',
              descriptionWidget: Text(
                'delete_playlist_desc'.tr(),
                style: theme.textTheme.ppMori400White14,
              ),
              actionButton: 'remove_collection'.tr(),
              onAction: deletePlayList,
            );
          },
        ),
        OptionItem(),
      ],
    );
  }

  void _onShufferTap(PlayListModel? playList) {
    final playControlModel = playList?.playControlModel ?? PlayControlModel();
    playControlModel.isShuffle = !playControlModel.isShuffle;
    bloc.add(UpdatePlayControl(playControlModel: playControlModel));
  }

  void _onTimerTap(PlayListModel? playList) {
    final playControlModel = playList?.playControlModel ?? PlayControlModel();
    bloc.add(
        UpdatePlayControl(playControlModel: playControlModel.onChangeTime()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ViewPlaylistBloc, ViewPlaylistState>(
      bloc: bloc,
      listener: (context, state) {},
      builder: (context, state) {
        final playList = state.playListModel;
        if (playList == null) {
          return const SizedBox();
        }
        return Scaffold(
          appBar: AppBar(
            systemOverlayStyle: systemUiOverlayLightStyle(AppColor.white),
            elevation: 0,
            shadowColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Row(
                children: [
                  SizedBox(
                    width: 15,
                  ),
                  Icon(
                    AuIcon.chevron,
                    color: AppColor.secondaryDimGrey,
                    size: 18,
                  ),
                ],
              ),
            ),
            leadingWidth: editable ? 90 : 55,
            titleSpacing: 0,
            backgroundColor: theme.colorScheme.background,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.payload.titleIcon != null) ...[
                  SizedBox(
                      width: 22, height: 22, child: widget.payload.titleIcon),
                  const SizedBox(width: 10),
                  Text(
                    playList.getName(),
                    style: theme.textTheme.ppMori400Black16,
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      playList.getName(),
                      style: theme.textTheme.ppMori400Black16,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]
              ],
            ),
            actions: [
              const SizedBox(width: 15),
              FFCastButton(
                onDeviceSelected: (device) async {
                  final listTokenIds = playList.tokenIDs;
                  if (listTokenIds == null) {
                    log.info('Playlist tokenIds is null');
                    return;
                  }
                  final duration = speedValues.values.first.inMilliseconds;
                  final listPlayArtwork = listTokenIds
                      .map((e) => PlayArtworkV2(
                          token: CastAssetToken(id: e), duration: duration))
                      .toList();
                  _canvasDeviceBloc.add(CanvasDeviceCastListArtworkEvent(
                      device, listPlayArtwork));
                },
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () async {
                  await _onOrderTap(context, _getAvailableOrders());
                },
                child: SvgPicture.asset(
                  'assets/images/sort.svg',
                  colorFilter:
                      ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
                  width: 22,
                  height: 22,
                ),
              ),
              if (editable) ...[
                const SizedBox(width: 15),
                GestureDetector(
                    onTap: () async => _onMoreTap(context, playList),
                    child: SvgPicture.asset(
                      'assets/images/more_circle.svg',
                      colorFilter:
                          ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
                      width: 24,
                    )),
              ],
              const SizedBox(width: 15),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.25),
              child:
                  addOnlyDivider(color: AppColor.auQuickSilver, border: 0.25),
            ),
          ),
          body: BlocBuilder<NftCollectionBloc, NftCollectionBlocState>(
            bloc: nftBloc,
            builder: (context, nftState) => NftCollectionGrid(
              state: nftState.state,
              tokens: setupPlayList(
                tokens: nftState.tokens.items,
                selectedTokens: playList.tokenIDs,
              ),
              customGalleryViewBuilder: (context, tokens) => _assetsWidget(
                context,
                tokens,
                accountIdentities: accountIdentities,
                playControlModel:
                    playList.playControlModel ?? PlayControlModel(),
                onShuffleTap: () => _onShufferTap(playList),
                onTimerTap: () => _onTimerTap(playList),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> moveToAddNftToCollection(BuildContext context) async {
    await Navigator.pushNamed(
      context,
      AppRouter.addToCollectionPage,
      arguments: widget.payload.playListModel,
    ).then((value) {
      if (value != null && value is PlayListModel) {
        bloc.add(SavePlaylist(name: value.name));
        nftBloc.add(RefreshNftCollectionByIDs(
          ids: isDemo ? [] : value.tokenIDs,
          debugTokenIds: isDemo ? value.tokenIDs : [],
        ));
      }
    });
  }

  Widget _assetsWidget(
    BuildContext context,
    List<CompactedAssetToken> tokens, {
    required List<ArtworkIdentity> accountIdentities,
    required PlayControlModel playControlModel,
    Function()? onShuffleTap,
    Function()? onTimerTap,
  }) {
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;

    final estimatedCellWidth = MediaQuery.of(context).size.width / cellPerRow -
        cellSpacing * (cellPerRow - 1);
    final cachedImageSize = (estimatedCellWidth * 3).ceil();
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cellPerRow,
                    crossAxisSpacing: cellSpacing,
                    mainAxisSpacing: cellSpacing,
                  ),
                  itemBuilder: (context, index) {
                    final asset = tokens[index];
                    return GestureDetector(
                      child: asset.pending == true && !asset.hasMetadata
                          ? PendingTokenWidget(
                              thumbnail: asset.galleryThumbnailURL,
                              tokenId: asset.tokenId,
                            )
                          : tokenGalleryThumbnailWidget(
                              context,
                              asset,
                              cachedImageSize,
                              usingThumbnailID: index > 50,
                              useHero: false,
                            ),
                      onTap: () async {
                        if (asset.pending == true && !asset.hasMetadata) {
                          return;
                        }

                        final index = tokens
                            .where((e) => e.pending != true || e.hasMetadata)
                            .toList()
                            .indexOf(asset);
                        final payload = asset.isPostcard
                            ? PostcardDetailPagePayload(
                                accountIdentities,
                                index,
                                playControl: playControlModel,
                              )
                            : ArtworkDetailPayload(
                                accountIdentities,
                                index,
                                playControl: playControlModel,
                              );
                        final pageName = asset.isPostcard
                            ? AppRouter.claimedPostcardDetailsPage
                            : AppRouter.artworkDetailsPage;

                        await Navigator.of(context)
                            .pushNamed(pageName, arguments: payload);
                      },
                    );
                  },
                  itemCount: tokens.length),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (editable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Center(
                    child: AddButton(
                      icon: SvgPicture.asset(
                        'assets/images/Add.svg',
                        width: 30,
                        height: 30,
                      ),
                      onTap: () async {
                        await moveToAddNftToCollection(context);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 22),
            ],
          ),
        )
      ],
    );
  }

  Future<void> _fetchDevice() async {
    _canvasDeviceBloc.add(CanvasDeviceGetDevicesEvent(
        widget.payload.playListModel?.id ?? '',
        syncAll: false));
  }
}

enum SortOrder {
  title,
  artist,
  newest,
  manual;

  String get text {
    switch (this) {
      case SortOrder.title:
        return tr('sort_by_title');
      case SortOrder.artist:
        return tr('sort_by_artist');
      case SortOrder.newest:
        return tr('sort_by_newest');
      case SortOrder.manual:
        return tr('sort_by_manual');
    }
  }

  int compare(CompactedAssetToken a, CompactedAssetToken b) {
    switch (this) {
      case SortOrder.title:
        return a.title?.compareTo(b.title ?? '') ?? 1;
      case SortOrder.artist:
        return a.artistID?.compareTo(b.artistID ?? '') ?? 1;
      case SortOrder.newest:
        return b.lastActivityTime.compareTo(a.lastActivityTime);
      case SortOrder.manual:
        return -1;
    }
  }
}

class AddButton extends StatelessWidget {
  final Widget icon;
  final void Function() onTap;

  const AddButton({
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: icon,
      );
}
