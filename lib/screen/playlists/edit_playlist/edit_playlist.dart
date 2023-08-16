import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';

import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import '../../../util/iterable_ext.dart';
import 'widgets/edit_playlist_gridview.dart';
import 'edit_playlist_bloc.dart';
import 'edit_playlist_state.dart';
import '../../../util/string_ext.dart';
import '../../../util/token_ext.dart';

class EditPlaylistScreen extends StatefulWidget {
  final PlayListModel? playListModel;

  const EditPlaylistScreen({Key? key, this.playListModel}) : super(key: key);

  @override
  State<EditPlaylistScreen> createState() => _EditPlaylistScreenState();
}

class _EditPlaylistScreenState extends State<EditPlaylistScreen> {
  final bloc = injector.get<EditPlaylistBloc>();
  final nftBloc = injector.get<NftCollectionBloc>(param1: false);
  List<CompactedAssetToken> tokensPlaylist = [];

  @override
  void initState() {
    super.initState();

    nftBloc.add(RefreshNftCollectionByIDs(ids: widget.playListModel?.tokenIDs));
    bloc.add(InitPlayList(
      playListModel: widget.playListModel?.copyWith(
        tokenIDs: List.from(widget.playListModel?.tokenIDs ?? []),
      ),
    ));
  }

  final _playlistService = injector<PlaylistService>();

  Future<void> deletePlayList() async {
    final listPlaylist = await _playlistService.getPlayList();
    listPlaylist
        .removeWhere((element) => element.id == widget.playListModel?.id);
    _playlistService.setPlayList(listPlaylist, override: true);
    injector.get<SettingsDataService>().backup();
    injector<NavigationService>().popUntilHomeOrSettings();
  }

  List<CompactedAssetToken> setupPlayList({
    required List<CompactedAssetToken> tokens,
    List<String>? tokenIDs,
  }) {
    tokens = tokens.filterAssetToken();

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
          Navigator.pushNamed(
            context,
            AppRouter.viewPlayListPage,
            arguments: state.playListModel,
          );
        }
      },
      builder: (context, state) {
        final playList = state.playListModel;
        final selectedItem = state.selectedItem ?? [];

        return Scaffold(
          appBar: AppBar(
            elevation: 1,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(AuIcon.chevron),
            ),
            actions: const [
              SizedBox(
                width: 50,
              )
            ],
            backgroundColor: theme.colorScheme.background,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text(
              (playList?.name?.isNotEmpty ?? false)
                  ? playList!.name!
                  : tr('untitled'),
              style: theme.textTheme.ppMori400Black14,
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
                  bloc: nftBloc,
                  builder: (context, nftState) {
                    return NftCollectionGrid(
                      state: nftState.state,
                      tokens: nftState.tokens.items,
                      loadingIndicatorBuilder: loadingView,
                      customGalleryViewBuilder: (gridContext, tokens) {
                        final listToken = setupPlayList(
                          tokens: tokens,
                          tokenIDs: playList?.tokenIDs ?? [],
                        );
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 14,
                                right: 14,
                                top: 24,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: listToken.isEmpty
                                    ? tokenEmptyAction(theme, playList)
                                    : tokenAction(
                                        selectedItem,
                                        theme,
                                        context,
                                        playList,
                                      ),
                              ),
                            ),
                            Expanded(
                              child: EditPlaylistGridView(
                                onAddTap: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.createPlayListPage,
                                  arguments: playList,
                                ).then((value) {
                                  if (value != null && value is PlayListModel) {
                                    bloc.add(SavePlaylist());
                                  }
                                }),
                                tokens: listToken,
                                onReorder: (tokens) {
                                  final tokenIDs =
                                      tokens.map((e) => e?.id ?? '').toList();
                                  bloc.add(
                                    UpdateOrderPlaylist(
                                      tokenIDs: tokenIDs,
                                      thumbnailURL: tokens
                                          .where((element) =>
                                              element?.id ==
                                              tokenIDs.firstOrDefault())
                                          .firstOrDefault()
                                          ?.getGalleryThumbnailUrl(),
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
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  listener: (context, nftState) {},
                ),
                BlocBuilder<NftCollectionBloc, NftCollectionBlocState>(
                    bloc: nftBloc,
                    builder: (context, state) {
                      return Positioned(
                        bottom: 30,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                PrimaryButton(
                                  onTap: () {
                                    final thumbnailUrl = tokensPlaylist
                                        .where((element) =>
                                            element.id ==
                                            playList?.tokenIDs.firstOrDefault())
                                        .firstOrDefault()
                                        ?.getGalleryThumbnailUrl();
                                    playList?.thumbnailURL = thumbnailUrl;
                                    bloc.add(SavePlaylist());
                                  },
                                  width: 170,
                                  text: tr('done').capitalize(),
                                  color: theme.auSuperTeal,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget tokenAction(List<String> selectedItem, ThemeData theme,
      BuildContext context, PlayListModel? playList) {
    return Row(
      children: [
        Text(
          tr(
              selectedItem.length != 1
                  ? 'artworks_selected'
                  : 'artwork_selected',
              args: [selectedItem.length.toString()]),
          style: theme.textTheme.ppMori400Black12,
        ),
        const Spacer(),
        GestureDetector(
          onTap: selectedItem.isEmpty
              ? null
              : () => UIHelper.showMessageActionNew(
                    context,
                    tr('remove_from_list'),
                    '',
                    descriptionWidget: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          style: theme.textTheme.ppMori400White16,
                          text: "you_are_about_to_remove".tr(),
                        ),
                        TextSpan(
                          style: theme.textTheme.ppMori700White16,
                          text: tr(
                              selectedItem.length != 1 ? 'artworks' : 'artwork',
                              args: [selectedItem.length.toString()]),
                        ),
                        TextSpan(
                          style: theme.textTheme.ppMori400White16,
                          text: "from_the_playlist".tr(),
                        ),
                        TextSpan(
                          style: theme.textTheme.ppMori700White16,
                          text: playList?.name ?? tr('untitled'),
                        ),
                        TextSpan(
                          style: theme.textTheme.ppMori400White16,
                          text: "they_will_remain".tr(),
                        ),
                      ]),
                    ),
                    actionButton: "remove".tr(),
                    onAction: () {
                      Navigator.pop(context);
                      bloc.add(
                        RemoveTokens(
                          tokenIDs: selectedItem,
                        ),
                      );
                    },
                  ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(64),
            ),
            child: Text(
              '${tr('remove')} ${selectedItem.isEmpty ? '' : '(${selectedItem.length})'}',
              style: theme.textTheme.ppMori400White12,
            ),
          ),
        ),
      ],
    );
  }

  Widget tokenEmptyAction(ThemeData theme, PlayListModel? playList) {
    return Row(
      children: [
        Text(
          tr('no_artwork_in_this_playlist'),
          style: theme.textTheme.ppMori400Black12,
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.createPlayListPage,
              arguments: playList,
            ).then((value) {
              if (value != null && value is PlayListModel) {
                bloc.add(SavePlaylist());
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(64),
            ),
            child: Text(
              tr('add'),
              style: theme.textTheme.ppMori400White12,
            ),
          ),
        )
      ],
    );
  }
}
