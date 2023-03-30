import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/playlists/edit_playlist/widgets/text_name_playlist.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_state.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/play_control.dart';
import 'package:autonomy_flutter/util/token_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import '../../../util/iterable_ext.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';

class ViewPlaylistScreen extends StatefulWidget {
  final PlayListModel? playListModel;
  const ViewPlaylistScreen({Key? key, this.playListModel}) : super(key: key);

  @override
  State<ViewPlaylistScreen> createState() => _ViewPlaylistScreenState();
}

class _ViewPlaylistScreenState extends State<ViewPlaylistScreen> {
  final bloc = injector.get<ViewPlaylistBloc>();
  final nftBloc = injector.get<NftCollectionBloc>(param1: false);
  final _configurationService = injector<ConfigurationService>();
  List<ArtworkIdentity> accountIdentities = [];
  List<CompactedAssetToken> tokensPlaylist = [];
  bool isDemo = injector.get<ConfigurationService>().isDemoArtworksMode();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    nftBloc.add(RefreshNftCollectionByIDs(
      ids: isDemo ? [] : widget.playListModel?.tokenIDs,
      debugTokenIds: isDemo ? widget.playListModel?.tokenIDs : [],
    ));

    bloc.add(GetPlayList(playListModel: widget.playListModel));
  }

  deletePlayList() {
    final listPlaylist = _configurationService.getPlayList();
    listPlaylist
        ?.removeWhere((element) => element.id == widget.playListModel?.id);
    _configurationService.setPlayList(listPlaylist, override: true);
    injector.get<SettingsDataService>().backup();
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
        [];

    temp.removeWhere((element) => element == null);

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

  void _onMoreTap(BuildContext context, PlayListModel? playList) {
    final theme = Theme.of(context);
    UIHelper.showDrawerAction(
      context,
      options: [
        OptionItem(
          title: 'Rename',
          icon: SvgPicture.asset(
            'assets/images/rename_icon.svg',
            width: 24,
          ),
          onTap: () {
            Navigator.pop(context);
            bloc.add(ChangeRename(value: true));
          },
        ),
        OptionItem(
          title: 'Edit',
          icon: SvgPicture.asset(
            'assets/images/edit_icon.svg',
            width: 24,
          ),
          onTap: () {
            Navigator.pop(context);
            if (isDemo) return;
            Navigator.pushNamed(
              context,
              AppRouter.editPlayListPage,
              arguments: playList,
            );
          },
        ),
        OptionItem(
          title: 'Delete',
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
              descriptionWidget: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    style: theme.textTheme.ppMori400White16,
                    text: "you_are_about".tr(),
                  ),
                  TextSpan(
                    style: theme.textTheme.ppMori700White16,
                    text: playList?.name ?? tr('untitled'),
                  ),
                  TextSpan(
                    style: theme.textTheme.ppMori400White16,
                    text: "dont_worry".tr(),
                  ),
                ]),
              ),
              actionButton: "delete_dialog".tr(),
              onAction: deletePlayList,
            );
          },
        ),
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
        final isRename = state.isRename;
        if (isRename == true) {
          _focusNode.requestFocus();
        }
        return Scaffold(
          appBar: AppBar(
            elevation: 1,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(AuIcon.chevron),
            ),
            backgroundColor: theme.colorScheme.background,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: isRename ?? false
                ? TextNamePlaylist(
                    focusNode: _focusNode,
                    playList: playList,
                    onEditPlaylistName: (value) {
                      bloc.add(SavePlaylist(
                          name: value.trim().isNotEmpty ? value.trim() : null));
                    },
                  )
                : Text(
                    (playList?.name?.isNotEmpty ?? false)
                        ? playList!.name!
                        : tr('untitled'),
                    style: theme.textTheme.ppMori400Black14,
                  ),
            actions: const [
              SizedBox(
                width: 50,
              )
            ],
          ),
          body: BlocBuilder<NftCollectionBloc, NftCollectionBlocState>(
            bloc: nftBloc,
            builder: (context, nftState) {
              return NftCollectionGrid(
                state: nftState.state,
                tokens: setupPlayList(
                  tokens: nftState.tokens.items,
                  selectedTokens: playList?.tokenIDs,
                ),
                customGalleryViewBuilder: (context, tokens) => _assetsWidget(
                  context,
                  tokens,
                  accountIdentities: accountIdentities,
                  playControlModel:
                      playList?.playControlModel ?? PlayControlModel(),
                  onMoreTap: () => _onMoreTap(context, playList),
                  onShuffleTap: () => _onShufferTap(playList),
                  onTimerTap: () => _onTimerTap(playList),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _assetsWidget(
    BuildContext context,
    List<CompactedAssetToken> tokens, {
    required List<ArtworkIdentity> accountIdentities,
    Function()? onMoreTap,
    Function()? onShuffleTap,
    Function()? onTimerTap,
    required PlayControlModel playControlModel,
  }) {
    final theme = Theme.of(context);
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
            Padding(
              padding: const EdgeInsets.only(
                bottom: 24,
                top: 24,
                left: 14,
                right: 14,
              ),
              child: Row(
                children: [
                  Text(
                    tr(tokens.length != 1 ? 'artworks' : 'artwork',
                        args: [tokens.length.toString()]),
                    style: theme.textTheme.ppMori400Black12,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onMoreTap,
                    child: SvgPicture.asset(
                      'assets/images/more_circle.svg',
                      color: theme.auQuickSilver,
                      width: 24,
                    ),
                  )
                ],
              ),
            ),
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
                    onTap: () {
                      if (asset.pending == true && !asset.hasMetadata) return;

                      final index = tokens
                          .where((e) => e.pending != true || e.hasMetadata)
                          .toList()
                          .indexOf(asset);
                      final payload = ArtworkDetailPayload(
                        accountIdentities,
                        index,
                        playControl: playControlModel,
                      );

                      Navigator.of(context).pushNamed(
                          AppRouter.artworkDetailsPage,
                          arguments: payload);
                    },
                  );
                },
                itemCount: tokens.length,
              ),
            ),
            const SizedBox(
              height: 50,
            )
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: PlaylistControl(
            playControl: playControlModel,
            showPlay: accountIdentities.isNotEmpty,
            onShuffleTap: onShuffleTap,
            onTimerTap: onTimerTap,
            onPlayTap: () {
              final payload = ArtworkDetailPayload(
                accountIdentities,
                0,
                playControl: playControlModel,
              );
              Navigator.of(context).pushNamed(
                AppRouter.artworkPreviewPage,
                arguments: payload,
              );
            },
          ),
        )
      ],
    );
  }
}
