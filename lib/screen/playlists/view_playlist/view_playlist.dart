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
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/iterable_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/token_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
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
  late bool editable;
  final _canvasClientServiceV2 = injector<CanvasClientServiceV2>();

  @override
  void initState() {
    editable = widget.payload.collectionType == CollectionType.manual &&
        !(widget.payload.playListModel?.isDefault ?? true);
    super.initState();

    nftBloc.add(RefreshNftCollectionByIDs(
      ids: isDemo ? [] : widget.payload.playListModel?.tokenIDs,
      debugTokenIds: isDemo ? widget.payload.playListModel?.tokenIDs : [],
    ));

    _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
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

  List<CompactedAssetToken> _setupPlayList({
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

    tokensPlaylist = List.from(temp);

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

  Widget _appBarTitle(BuildContext context, PlayListModel playList) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (widget.payload.titleIcon != null) ...[
          SizedBox(width: 22, height: 22, child: widget.payload.titleIcon),
          const SizedBox(width: 10),
          Text(
            playList.getName(),
            style: theme.textTheme.ppMori700Black36
                .copyWith(color: AppColor.white),
          ),
        ] else ...[
          Expanded(
            child: Text(
              playList.getName(),
              style: theme.textTheme.ppMori700Black36
                  .copyWith(color: AppColor.white),
              textAlign: TextAlign.left,
            ),
          ),
        ]
      ],
    );
  }

  List<Widget> _appBarAction(BuildContext context, PlayListModel playList) => [
        if (editable) ...[
          const SizedBox(width: 15),
          GestureDetector(
              onTap: () async => _onMoreTap(context, playList),
              child: SvgPicture.asset(
                'assets/images/more_circle.svg',
                colorFilter:
                    const ColorFilter.mode(AppColor.white, BlendMode.srcIn),
                width: 24,
              )),
        ],
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
            _canvasDeviceBloc.add(
                CanvasDeviceChangeControlDeviceEvent(device, listPlayArtwork));
          },
        ),
        const SizedBox(width: 15),
      ];

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return BlocConsumer<ViewPlaylistBloc, ViewPlaylistState>(
      bloc: bloc,
      listener: (context, state) {},
      builder: (context, state) {
        if (state.playListModel == null) {
          return const SizedBox();
        }

        final playList = state.playListModel!;
        return Scaffold(
          backgroundColor: AppColor.primaryBlack,
          appBar: getPlaylistAppBar(
            context,
            title: _appBarTitle(context, playList),
            actions: _appBarAction(context, playList),
          ),
          body: BlocBuilder<NftCollectionBloc, NftCollectionBlocState>(
            bloc: nftBloc,
            builder: (context, nftState) => Column(
              children: [
                BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
                  bloc: _canvasDeviceBloc,
                  builder: (context, canvasDeviceState) {
                    final isPlaylistCasting =
                        _canvasDeviceBloc.state.controllingDevice != null;
                    if (isPlaylistCasting) {
                      return const Padding(
                        padding: EdgeInsets.all(15),
                        child: PlaylistControl(),
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                ),
                Expanded(
                  child: NftCollectionGrid(
                    state: nftState.state,
                    tokens: _setupPlayList(
                      tokens: nftState.tokens.items,
                      selectedTokens: playList.tokenIDs,
                    ),
                    customGalleryViewBuilder: (context, tokens) =>
                        _assetsWidget(
                      context,
                      tokens,
                      accountIdentities: accountIdentities,
                      playlist: playList,
                      onShuffleTap: () => _onShufferTap(playList),
                      onTimerTap: () => _onTimerTap(playList),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _moveToArtwork(CompactedAssetToken compactedAssetToken) {
    final controllingDevice = _canvasDeviceBloc.state.controllingDevice;
    if (controllingDevice != null) {
      return _canvasClientServiceV2.moveToArtwork(controllingDevice,
          artworkId: compactedAssetToken.id);
    }
    return Future.value(false);
  }

  Widget _assetsWidget(
    BuildContext context,
    List<CompactedAssetToken> tokens, {
    required List<ArtworkIdentity> accountIdentities,
    required PlayListModel playlist,
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
                              shouldRefreshCache:
                                  asset.shouldRefreshThumbnailCache,
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

                        unawaited(_moveToArtwork(asset));

                        final payload = asset.isPostcard
                            ? PostcardDetailPagePayload(
                                accountIdentities,
                                index,
                                playlist: playlist,
                              )
                            : ArtworkDetailPayload(
                                accountIdentities,
                                index,
                                playlist: playlist,
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
      ],
    );
  }
}

class AddButton extends StatelessWidget {
  final Widget icon;
  final Widget? iconOnDisabled;
  final void Function() onTap;
  final bool isEnable;

  const AddButton({
    required this.icon,
    required this.onTap,
    super.key,
    this.iconOnDisabled,
    this.isEnable = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: isEnable ? onTap : null,
      child: isEnable ? icon : iconOnDisabled ?? icon);
}
