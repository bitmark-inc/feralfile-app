import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/screen/add_new_playlist/add_new_playlist.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/edit_playlist/widgets/text_name_playlist.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
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

  final _configurationService = injector<ConfigurationService>();

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
            backgroundColor: theme.backgroundColor,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: TextNamePlaylist(
              playList: playList,
              onEditPlaylistName: (value) => playList?.name = value,
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
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
                          PrimaryButton(
                            onTap: () {
                              bloc.add(SavePlaylist());
                            },
                            text: tr('finish'),
                            color: theme.auLightGrey,
                          ),
                          BlocBuilder<NftCollectionBloc,
                              NftCollectionBlocState>(
                            bloc: nftBloc,
                            builder: (context, state) {
                              final isSeletedAll =
                                  selectedItem.length == tokensPlaylist.length;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 15, top: 15),
                                child: tokensPlaylist.isEmpty
                                    ? Text(
                                        tr('no_artwork_in_this_playlist'),
                                        style: theme.textTheme.ppMori400Black12,
                                      )
                                    : Row(
                                        children: [
                                          Text(
                                            tr(
                                                selectedItem.length != 1
                                                    ? 'artworks_selected'
                                                    : 'artwork_selected',
                                                args: [
                                                  selectedItem.length.toString()
                                                ]),
                                            style: theme
                                                .textTheme.ppMori400Black12,
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              final tokenIDs = tokensPlaylist
                                                  .map((e) => e.id)
                                                  .toList();

                                              bloc.add(
                                                SelectAllPlaylist(
                                                  value: !isSeletedAll,
                                                  tokenIDs: tokenIDs,
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(),
                                                borderRadius:
                                                    BorderRadius.circular(64),
                                              ),
                                              child: Text(
                                                tr(
                                                  isSeletedAll
                                                      ? tr('unselect_all')
                                                      : tr('select_all'),
                                                ),
                                                style: theme
                                                    .textTheme.ppMori400Black12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              );
                            },
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
                                  tokenIDs: playList?.tokenIDs ?? [],
                                ),
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
                                    Navigator.pop(context);
                                  },
                                  width: 170,
                                  text: tr('undo'),
                                  color: theme.auLightGrey,
                                ),
                                tokensPlaylist.isEmpty
                                    ? PrimaryButton(
                                        onTap: () {
                                          UIHelper.showMessageActionNew(
                                            context,
                                            tr('delete_playlist'),
                                            '',
                                            descriptionWidget: RichText(
                                              text: TextSpan(children: [
                                                TextSpan(
                                                  style: theme.textTheme
                                                      .ppMori400White16,
                                                  text: "you_are_about".tr(),
                                                ),
                                                TextSpan(
                                                  style: theme.textTheme
                                                      .ppMori700White16,
                                                  text: playList?.name ??
                                                      tr('untitled'),
                                                ),
                                                TextSpan(
                                                  style: theme.textTheme
                                                      .ppMori400White16,
                                                  text: "dont_worry".tr(),
                                                ),
                                              ]),
                                            ),
                                            actionButton: "delete_dialog".tr(),
                                            onAction: deletePlayList,
                                          );
                                        },
                                        width: 170,
                                        text: tr('delete_playlist'),
                                      )
                                    : PrimaryButton(
                                        onTap: selectedItem.isEmpty
                                            ? null
                                            : () =>
                                                UIHelper.showMessageActionNew(
                                                  context,
                                                  tr('remove_from_list'),
                                                  '',
                                                  descriptionWidget: RichText(
                                                    text: TextSpan(children: [
                                                      TextSpan(
                                                        style: theme.textTheme
                                                            .ppMori400White16,
                                                        text:
                                                            "you_are_about_to_remove"
                                                                .tr(),
                                                      ),
                                                      TextSpan(
                                                        style: theme.textTheme
                                                            .ppMori700White16,
                                                        text: tr(
                                                            selectedItem.length !=
                                                                    1
                                                                ? 'artworks'
                                                                : 'artwork',
                                                            args: [
                                                              selectedItem
                                                                  .length
                                                                  .toString()
                                                            ]),
                                                      ),
                                                      TextSpan(
                                                        style: theme.textTheme
                                                            .ppMori400White16,
                                                        text:
                                                            "from_the_playlist"
                                                                .tr(),
                                                      ),
                                                      TextSpan(
                                                        style: theme.textTheme
                                                            .ppMori700White16,
                                                        text: playList?.name ??
                                                            tr('untitled'),
                                                      ),
                                                      TextSpan(
                                                        style: theme.textTheme
                                                            .ppMori400White16,
                                                        text: "they_will_remain"
                                                            .tr(),
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
                                        width: 170,
                                        text:
                                            '${tr('remove')} ${selectedItem.isEmpty ? '' : '(${selectedItem.length})'}',
                                        color: selectedItem.isEmpty
                                            ? theme.auLightGrey
                                            : theme.auSuperTeal,
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
}
