import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/view_playlist/view_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/view_playlist/view_playlist_state.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/play_control.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import '../../util/token_ext.dart';

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
  @override
  void initState() {
    super.initState();
    hiddenTokens =
        injector<ConfigurationService>().getTempStorageHiddenTokenIDs();
    sentArtworks = injector<ConfigurationService>().getRecentlySentToken();
    injector<AccountService>().getAllAddresses().then((value) {
      nftBloc.add(RefreshTokenEvent(
        addresses: value,
      ));
      nftBloc.add(RequestIndexEvent(value));
    });
    bloc.add(GetPlayList());
  }

  deletePlayList() {
    final listPlaylist = _configurationService.getPlayList();
    listPlaylist
        ?.removeWhere((element) => element.id == widget.playListModel?.id);
    _configurationService.setPlayList(listPlaylist, override: true);
    injector.get<SettingsDataService>().backup();
    Navigator.pop(context);
    Navigator.pop(context);
  }

  List<AssetToken> setupPlayList({
    required List<AssetToken> tokens,
    List<String>? selectedTokens,
  }) {
    tokens.sortToken();
    tokens = tokens
        .where((element) => selectedTokens?.contains(element.id) ?? false)
        .toList();
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
    accountIdentities = tokens
        .where((e) => e.pending != true || e.hasMetadata)
        .map((element) => ArtworkIdentity(element.id, element.ownerAddress))
        .toList();
    tokensPlaylist = tokens;
    return tokens;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ViewPlaylistBloc, ViewPlaylistState>(
      bloc: bloc,
      listener: (context, state) {},
      builder: (context, state) {
        final playList = widget.playListModel;
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.backgroundColor,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    children: [
                      const Icon(Icons.navigate_before),
                      Text(
                        tr('back'),
                        style: theme.textTheme.button,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    UIHelper.showDialogAction(context, options: [
                      OptionItem(
                          title: tr('modify_playlist'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRouter.editPlayListPage,
                              arguments: playList,
                            );
                          }),
                      OptionItem(
                          title: tr('delete_playlist'),
                          onTap: () {
                            Navigator.pop(context);
                            UIHelper.showMessageAction(
                              context,
                              tr('delete_playlist'),
                              '',
                              descriptionWidget: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    style: theme.primaryTextTheme.bodyText1,
                                    text: "you_are_about".tr(),
                                  ),
                                  TextSpan(
                                    style: theme.primaryTextTheme.headline4,
                                    text: playList?.name ?? tr('untitled'),
                                  ),
                                  TextSpan(
                                    style: theme.primaryTextTheme.bodyText1,
                                    text: "dont_worry".tr(),
                                  ),
                                ]),
                              ),
                              actionButton: "Remove",
                              onAction: deletePlayList,
                            );
                          }),
                    ]);
                  },
                  icon: const Icon(Icons.more_horiz),
                )
              ],
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 14,
                        right: 14,
                        top: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playList?.name ?? tr('untitled'),
                            style: playList?.name == null
                                ? theme.textTheme.atlasSpanishGreyBold36
                                : theme.textTheme.headline1,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40, top: 5),
                            child: Text(
                              tr(
                                  tokensPlaylist.length > 1
                                      ? 'artworks'
                                      : 'artwork',
                                  args: [tokensPlaylist.length.toString()]),
                              style: theme.textTheme.atlasBlackMedium12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: BlocConsumer<NftCollectionBloc,
                          NftCollectionBlocState>(
                        bloc: nftBloc,
                        builder: (context, nftState) {
                          return NftCollectionGrid(
                            state: nftState.state,
                            tokens: nftState.tokens,
                            loadingIndicatorBuilder: loadingView,
                            customGalleryViewBuilder: (context, tokens) =>
                                _assetsWidget(
                              context,
                              setupPlayList(
                                tokens: tokens,
                                selectedTokens: playList?.tokenIDs,
                              ),
                              accountIdentities: accountIdentities,
                            ),
                          );
                        },
                        listener: (context, nftState) {},
                      ),
                    )
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: PlaylistControl(
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
  }) {
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;

    final estimatedCellWidth = MediaQuery.of(context).size.width / cellPerRow -
        cellSpacing * (cellPerRow - 1);
    final cachedImageSize = (estimatedCellWidth * 3).ceil();

    return GridView.builder(
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
            Navigator.of(context)
                .pushNamed(AppRouter.artworkPreviewPage, arguments: payload);
          },
        );
      },
      itemCount: tokens.length,
    );
  }
}

Widget loadingView(BuildContext context) {
  final theme = Theme.of(context);
  return Center(
      child: Column(
    children: [
      CircularProgressIndicator(
        backgroundColor: Colors.white60,
        color: theme.colorScheme.secondary,
        strokeWidth: 2,
      ),
    ],
  ));
}
