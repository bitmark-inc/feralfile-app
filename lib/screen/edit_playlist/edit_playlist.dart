import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/screen/add_new_playlist/add_new_playlist.dart';
import 'package:autonomy_flutter/screen/app_router.dart';

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import '../../util/iterable_ext.dart';
import 'widgets/edit_playlist_gridview.dart';
import 'widgets/text_name_playlist.dart';
import 'edit_playlist_bloc.dart';
import 'edit_playlist_state.dart';

class EditPlaylistScreen extends StatefulWidget {
  final PlayListModel? playListModel;
  const EditPlaylistScreen({Key? key, this.playListModel}) : super(key: key);

  @override
  State<EditPlaylistScreen> createState() => _EditPlaylistScreenState();
}

class _EditPlaylistScreenState extends State<EditPlaylistScreen> {
  final bloc = injector.get<EditPlaylistBloc>();
  final nftBloc = injector.get<NftCollectionBloc>();
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

    bloc.add(InitPlayList(
      playListModel: widget.playListModel?.copyWith(
        tokenIDs: List.from(widget.playListModel?.tokenIDs ?? []),
      ),
    ));
  }

  List<AssetToken> setupPlayList({
    required List<AssetToken> tokens,
    List<String>? tokenIDs,
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

    final temp = tokenIDs
            ?.map((e) =>
                tokens.where((element) => element.id == e).firstOrDefault())
            .toList() ??
        [];

    temp.removeWhere((element) => element == null);
    tokensPlaylist = List.from(temp);

    return tokensPlaylist;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<EditPlaylistBloc, EditPlaylistState>(
      bloc: bloc,
      listener: (context, state) {
        if (state.isAddSuccess ?? false) {
          injector<NavigationService>().popUntilHomeOrSettings();
        }
      },
      builder: (context, state) {
        final playList = state.playListModel;
        final selectedItem = state.selectedItem ?? [];
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
                GestureDetector(
                  onTap: () => bloc.add(SavePlaylist()),
                  child: Text(
                    tr('save').toUpperCase(),
                    style: theme.textTheme.button,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
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
                      TextNamePlaylist(
                        playList: playList,
                        onEditPlaylistName: (value) => playList?.name = value,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40, top: 5),
                        child: Row(
                          children: [
                            Text(
                              tr(
                                  selectedItem.length != 1
                                      ? 'artworks_selected'
                                      : 'artwork_selected',
                                  args: [selectedItem.length.toString()]),
                              style: theme.textTheme.atlasBlackMedium12,
                            ),
                            const Spacer(),
                            Visibility(
                              visible: selectedItem.isNotEmpty,
                              child: GestureDetector(
                                onTap: () => UIHelper.showMessageAction(
                                  context,
                                  tr('remove_from_list'),
                                  '',
                                  descriptionWidget: RichText(
                                    text: TextSpan(children: [
                                      TextSpan(
                                        style: theme.primaryTextTheme.bodyText1,
                                        text: "you_are_about_to_remove".tr(),
                                      ),
                                      TextSpan(
                                        style: theme.primaryTextTheme.headline4,
                                        text: tr(
                                            selectedItem.length != 1
                                                ? 'artworks'
                                                : 'artwork',
                                            args: [
                                              selectedItem.length.toString()
                                            ]),
                                      ),
                                      TextSpan(
                                        style: theme.primaryTextTheme.bodyText1,
                                        text: "from_the_playlist".tr(),
                                      ),
                                      TextSpan(
                                        style: theme.primaryTextTheme.headline4,
                                        text: playList?.name ?? tr('untitled'),
                                      ),
                                      TextSpan(
                                        style: theme.primaryTextTheme.bodyText1,
                                        text: "they_will_remain".tr(),
                                      ),
                                    ]),
                                  ),
                                  actionButton: "remove".tr(),
                                  onAction: () {
                                    Navigator.pop(context);
                                    bloc.add(
                                      RemoveTokens(tokenIDs: selectedItem),
                                    );
                                  },
                                ),
                                child: Text(
                                  tr('remove'),
                                  style: theme.textTheme.atlasBlackMedium12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
                    bloc: nftBloc,
                    builder: (context, nftState) {
                      return NftCollectionGrid(
                        state: nftState.state,
                        tokens: nftState.tokens,
                        loadingIndicatorBuilder: loadingView,
                        customGalleryViewBuilder: (gridContext, tokens) {
                          return EditPlaylistGridView(
                            onAddTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.createPlayListPage,
                              arguments: playList,
                            ).then((value) {
                              if (value != null && value is PlayListModel) {
                                bloc.add(InitPlayList(
                                  playListModel: value,
                                ));
                              }
                            }),
                            tokens: setupPlayList(
                              tokens: tokens,
                              tokenIDs: playList?.tokenIDs,
                            ),
                            onReorder: (tokens) {
                              final tokenIDs =
                                  tokens.map((e) => e?.id ?? '').toList();
                              bloc.add(
                                UpdateOrderPlaylist(
                                  tokenIDs: tokenIDs,
                                  thumbnailURL: tokens
                                      .where((element) =>
                                          element?.id == tokenIDs.first)
                                      .first
                                      ?.getThumbnailUrl(),
                                ),
                              );
                            },
                            selectedTokens: selectedItem,
                            onChangedSelect: (tokenID, value) => bloc.add(
                              UpdateSelectedPlaylist(
                                tokenID: tokenID,
                                value: value,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    listener: (context, nftState) {},
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
