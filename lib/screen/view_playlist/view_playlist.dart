import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/edit_playlist/widgets/text_name_playlist.dart';
import 'package:autonomy_flutter/screen/view_playlist/view_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/view_playlist/view_playlist_state.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/play_control.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import '../../util/iterable_ext.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';

class ViewPlaylistScreen extends StatefulWidget {
  final PlayListModel? playListModel;
  const ViewPlaylistScreen({Key? key, this.playListModel}) : super(key: key);

  @override
  State<ViewPlaylistScreen> createState() => _ViewPlaylistScreenState();
}

class _ViewPlaylistScreenState extends State<ViewPlaylistScreen> {
  final bloc = injector.get<ViewPlaylistBloc>();
  final nftBloc = injector.get<NftCollectionBloc>();
  final _configurationService = injector<ConfigurationService>();
  List<ArtworkIdentity> accountIdentities = [];
  List<String> hiddenTokens = [];
  List<SentArtwork> sentArtworks = [];
  List<AssetToken> tokensPlaylist = [];
  bool isDemo = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    hiddenTokens =
        injector<ConfigurationService>().getTempStorageHiddenTokenIDs();
    sentArtworks = injector<ConfigurationService>().getRecentlySentToken();
    injector<AccountService>().getAllAddresses().then((value) {
      isDemo = injector.get<ConfigurationService>().isDemoArtworksMode();
      nftBloc.add(RefreshTokenEvent(
          addresses: value,
          debugTokens: isDemo ? widget.playListModel?.tokenIDs ?? [] : []));
      nftBloc.add(RequestIndexEvent(value));
    });
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

  List<AssetToken> setupPlayList({
    required List<AssetToken> tokens,
    List<String>? selectedTokens,
  }) {
    final expiredTime = DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME);

    tokens = tokens
        .where(
          (element) =>
              !hiddenTokens.contains(element.id) &&
              !sentArtworks.any(
                (e) => e.isHidden(
                    tokenID: element.id,
                    address: element.ownerAddress,
                    timestamp: expiredTime),
              ),
        )
        .toList();

    final temp = selectedTokens
            ?.map((e) =>
                tokens.where((element) => element.id == e).firstOrDefault())
            .toList() ??
        [];

    temp.removeWhere((element) => element == null);

    tokensPlaylist = List.from(temp);

    accountIdentities = tokensPlaylist
        .where((e) => e.pending != true || e.hasMetadata)
        .map((element) => ArtworkIdentity(element.id, element.ownerAddress))
        .toList();

    return tokensPlaylist;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ViewPlaylistBloc, ViewPlaylistState>(
      bloc: bloc,
      listener: (context, state) {},
      builder: (context, state) {
        final playList = widget.playListModel;
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
            backgroundColor: theme.backgroundColor,
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
          body: Stack(
            children: [
              SafeArea(
                child: SizedBox(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    child:
                        BlocBuilder<NftCollectionBloc, NftCollectionBlocState>(
                      bloc: nftBloc,
                      builder: (context, nftState) {
                        return NftCollectionGrid(
                          state: nftState.state,
                          tokens: nftState.tokens,
                          loadingIndicatorBuilder: (context) =>
                              Center(child: loadingIndicator()),
                          customGalleryViewBuilder: (context, tokens) =>
                              _assetsWidget(
                            context,
                            setupPlayList(
                              tokens: tokens,
                              selectedTokens: playList?.tokenIDs,
                            ),
                            accountIdentities: accountIdentities,
                            onMoreTap: () {
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
                                              style: theme
                                                  .textTheme.ppMori400White16,
                                              text: "you_are_about".tr(),
                                            ),
                                            TextSpan(
                                              style: theme
                                                  .textTheme.ppMori700White16,
                                              text: playList?.name ??
                                                  tr('untitled'),
                                            ),
                                            TextSpan(
                                              style: theme
                                                  .textTheme.ppMori400White16,
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
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: PlaylistControl(
                  showPlay: accountIdentities.isNotEmpty,
                  onPlayTap: () {
                    final payload = ArtworkDetailPayload(
                      accountIdentities,
                      0,
                      isPlaylist: true,
                    );
                    Navigator.of(context).pushNamed(
                      AppRouter.artworkPreviewPage,
                      arguments: payload,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _assetsWidget(
    BuildContext context,
    List<AssetToken> tokens, {
    required List<ArtworkIdentity> accountIdentities,
    Function()? onMoreTap,
  }) {
    final theme = Theme.of(context);
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;

    final estimatedCellWidth = MediaQuery.of(context).size.width / cellPerRow -
        cellSpacing * (cellPerRow - 1);
    final cachedImageSize = (estimatedCellWidth * 3).ceil();

    return Column(
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
                tr(tokensPlaylist.length != 1 ? 'artworks' : 'artwork',
                    args: [tokensPlaylist.length.toString()]),
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                  : tokenGalleryWidget(
                      context,
                      asset,
                      cachedImageSize,
                    ),
              onTap: () {
                if (asset.pending == true && !asset.hasMetadata) return;

                final index = tokens
                    .where((e) => e.pending != true || e.hasMetadata)
                    .toList()
                    .indexOf(asset);
                final payload = ArtworkDetailPayload(accountIdentities, index,
                    isPlaylist: true);

                Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
                    arguments: payload);
              },
            );
          },
          itemCount: tokens.length,
        ),
        const SizedBox(
          height: 80,
        ),
      ],
    );
  }
}
