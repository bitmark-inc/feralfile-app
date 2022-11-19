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
import 'package:autonomy_flutter/util/style.dart';
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
import '../../util/iterable_ext.dart';

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
                isDemo
                    ? const SizedBox()
                    : IconButton(
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
                                          style:
                                              theme.primaryTextTheme.bodyText1,
                                          text: "you_are_about".tr(),
                                        ),
                                        TextSpan(
                                          style:
                                              theme.primaryTextTheme.headline4,
                                          text:
                                              playList?.name ?? tr('untitled'),
                                        ),
                                        TextSpan(
                                          style:
                                              theme.primaryTextTheme.bodyText1,
                                          text: "dont_worry".tr(),
                                        ),
                                      ]),
                                    ),
                                    actionButton: "delete".tr(),
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
                child: SizedBox(
                  height: double.infinity,
                  child: SingleChildScrollView(
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
                                (playList?.name?.isNotEmpty ?? false)
                                    ? playList!.name!
                                    : tr('untitled'),
                                style: !(playList?.name?.isNotEmpty ?? false)
                                    ? theme.textTheme.atlasSpanishGreyBold36
                                    : theme.textTheme.headline1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
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
                              ),
                            );
                          },
                          listener: (context, nftState) {},
                        )
                      ],
                    ),
                  ),
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
            bottom: 40,
            top: 5,
            left: 14,
            right: 14,
          ),
          child: Text(
            tr(tokensPlaylist.length != 1 ? 'artworks' : 'artwork',
                args: [tokensPlaylist.length.toString()]),
            style: theme.textTheme.atlasBlackMedium12,
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
                if (injector<ConfigurationService>()
                    .isImmediateInfoViewEnabled()) {
                  Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
                      arguments: payload);
                } else {
                  Navigator.of(context).pushNamed(AppRouter.artworkPreviewPage,
                      arguments: payload);
                }
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
