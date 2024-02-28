import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/search_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';

class AddToCollectionScreen extends StatefulWidget {
  final PlayListModel playList;

  const AddToCollectionScreen({required this.playList, super.key});

  @override
  State<AddToCollectionScreen> createState() => _AddToCollectionScreenState();
}

class _AddToCollectionScreenState extends State<AddToCollectionScreen>
    with AfterLayoutMixin {
  final bloc = injector.get<AddNewPlaylistBloc>();
  final nftBloc = injector.get<NftCollectionBloc>();

  final _controller = ScrollController();
  late String _searchText;
  late bool _showSearchBar;
  List<String>? _initSelectedTokenIds;

  @override
  void initState() {
    _searchText = '';
    _showSearchBar = false;
    super.initState();

    _controller
      ..addListener(_scrollListenerToLoadMore)
      ..addListener(_scrollListenerToShowSearchBar);
    unawaited(refreshTokens().then((value) {
      nftBloc.add(GetTokensByOwnerEvent(pageKey: PageKey.init()));
    }));
    bloc.add(InitPlaylist(playListModel: widget.playList));
  }

  @override
  void afterFirstLayout(BuildContext context) {
    unawaited(
        injector<ConfigurationService>().setAlreadyShowCreatePlaylistTip(true));
    injector<ConfigurationService>().showCreatePlaylistTip.value = false;
  }

  void _scrollListenerToLoadMore() {
    if (_controller.position.pixels + 100 >=
        _controller.position.maxScrollExtent) {
      _loadMore();
    }
  }

  void _scrollListenerToShowSearchBar() {
    if (_controller.position.pixels <= 10 &&
        _controller.position.userScrollDirection == ScrollDirection.forward) {
      setState(() {
        _showSearchBar = true;
      });
    }
  }

  Future<void> _scrollToTop() async {
    await _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _loadMore() {
    final nextKey = nftBloc.state.nextKey;
    if (nextKey == null || nextKey.isLoaded) {
      return;
    }
    nftBloc.add(GetTokensByOwnerEvent(pageKey: nextKey));
  }

  Future<List<String>> getManualTokenIds() async {
    final cloudDb = injector<CloudDatabase>();
    final tokenIndexerIDs = (await cloudDb.connectionDao.getConnectionsByType(
            ConnectionType.manuallyIndexerTokenID.rawValue))
        .map((e) => e.key)
        .toList();
    return tokenIndexerIDs;
  }

  Future<List<String>> getAddresses() async {
    final accountService = injector<AccountService>();
    return await accountService.getAllAddresses();
  }

  Future refreshTokens() async {
    final indexerIds = await getManualTokenIds();

    nftBloc.add(RefreshNftCollectionByOwners(
      debugTokens: indexerIds,
    ));
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<CompactedAssetToken> setupPlayList({
    required List<CompactedAssetToken> tokens,
    List<String>? selectedTokenIds,
  }) {
    tokens = tokens.filterAssetToken().filterByTitleContain(_searchText);
    bloc.state.tokens = tokens;
    if (tokens.length <= INDEXER_TOKENS_MAXIMUM) {
      _loadMore();
    }
    return tokens;
  }

  List<CompactedAssetToken> reoderPlaylist({
    required List<CompactedAssetToken> tokens,
    List<String>? selectedTokenIds,
  }) {
    final filterSellectedTokens = tokens
        .where((element) => selectedTokenIds?.contains(element.id) ?? false)
        .toList();
    final unselectedTokens = tokens
        .where((element) => !(selectedTokenIds?.contains(element.id) ?? false))
        .toList();
    return filterSellectedTokens..addAll(unselectedTokens);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<AddNewPlaylistBloc, AddNewPlaylistState>(
      bloc: bloc,
      listener: (context, state) {
        if (state.isAddSuccess == true) {
          Navigator.pop(context, state.playListModel);
        }
        if (state.selectedIDs != null && _initSelectedTokenIds == null) {
          setState(() {
            _initSelectedTokenIds = state.selectedIDs!.toList();
          });
        }
      },
      builder: (context, state) {
        final nftState = nftBloc.state;
        final selectedCount = nftState.tokens.items
            .where(
                (element) => state.selectedIDs?.contains(element.id) ?? false)
            .length;
        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          appBar: getDoneAppBar(
            context,
            title: 'adding_to'.tr(namedArgs: {
              'title': widget.playList.getName(),
            }),
            onDone: (selectedCount > 0)
                ? () {
                    bloc.add(
                      CreatePlaylist(
                        name: widget.playList.name ?? '',
                      ),
                    );
                  }
                : null,
            onCancel: () {
              Navigator.pop(context);
            },
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.25),
              child:
                  addOnlyDivider(color: AppColor.auQuickSilver, border: 0.25),
            ),
          ),
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: BlocBuilder<NftCollectionBloc, NftCollectionBlocState>(
                bloc: nftBloc,
                builder: (context, nftState) => SafeArea(
                      top: false,
                      bottom: false,
                      child: Column(
                        children: [
                          if (_showSearchBar)
                            Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 20, 15, 18),
                                  child: ActionBar(
                                    searchBar: AuSearchBar(
                                      onChanged: (text) {
                                        setState(() {
                                          _searchText = text;
                                        });
                                      },
                                    ),
                                    onCancel: () async {
                                      setState(() {
                                        _searchText = '';
                                        _showSearchBar = false;
                                      });
                                      await _scrollToTop();
                                    },
                                  ),
                                ),
                                addOnlyDivider(),
                              ],
                            ),
                          Expanded(
                            child: NftCollectionGrid(
                              state: nftState.state,
                              tokens: nftState.tokens.items,
                              loadingIndicatorBuilder: loadingView,
                              customGalleryViewBuilder: (context, tokens) =>
                                  _assetsWidget(
                                context,
                                reoderPlaylist(
                                    tokens: setupPlayList(tokens: tokens),
                                    selectedTokenIds: _initSelectedTokenIds),
                                onChanged: (tokenID, value) => bloc.add(
                                  UpdateItemPlaylist(
                                      tokenID: tokenID, value: value),
                                ),
                                selectedTokens: state.selectedIDs,
                              ),
                            ),
                          )
                        ],
                      ),
                    )),
          ),
        );
      },
    );
  }

  Widget _assetsWidget(
    BuildContext context,
    List<CompactedAssetToken> tokens, {
    Function(String tokenID, bool value)? onChanged,
    List<String>? selectedTokens,
  }) {
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;

    final estimatedCellWidth = MediaQuery.of(context).size.width / cellPerRow -
        cellSpacing * (cellPerRow - 1);
    final cachedImageSize = (estimatedCellWidth * 3).ceil();

    return GridView.builder(
      controller: _controller,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cellPerRow,
        crossAxisSpacing: cellSpacing,
        mainAxisSpacing: cellSpacing,
      ),
      itemBuilder: (context, index) => ThubnailPlaylistItem(
        token: tokens[index],
        cachedImageSize: cachedImageSize,
        isSelected: selectedTokens?.contains(tokens[index].id) ?? false,
        onChanged: (value) {
          onChanged?.call(tokens[index].id, value ?? false);
        },
        usingThumbnailID: index > 50,
      ),
      itemCount: tokens.length,
    );
  }
}

class ThubnailPlaylistItem extends StatefulWidget {
  final bool showSelect;
  final bool isSelected;
  final CompactedAssetToken token;
  final Function(bool?)? onChanged;
  final int cachedImageSize;
  final bool usingThumbnailID;
  final bool showTriggerOrder;

  const ThubnailPlaylistItem({
    required this.token,
    required this.cachedImageSize,
    super.key,
    this.showSelect = true,
    this.isSelected = false,
    this.onChanged,
    this.showTriggerOrder = false,
    this.usingThumbnailID = true,
  });

  @override
  State<ThubnailPlaylistItem> createState() => _ThubnailPlaylistItemState();
}

class _ThubnailPlaylistItemState extends State<ThubnailPlaylistItem> {
  bool isSelected = false;

  @override
  void initState() {
    super.initState();
    isSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(covariant ThubnailPlaylistItem oldWidget) {
    setState(() {
      isSelected = widget.isSelected;
    });
    super.didUpdateWidget(oldWidget);
  }

  void onChanged(bool? value) {
    setState(() {
      isSelected = !isSelected;
      widget.onChanged?.call(isSelected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(isSelected),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: tokenGalleryThumbnailWidget(
              context,
              widget.token,
              widget.cachedImageSize,
              usingThumbnailID: widget.usingThumbnailID,
              useHero: false,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Visibility(
              visible: widget.showSelect,
              child: RadioSelectAddress(
                isChecked: isSelected,
                borderColor: theme.colorScheme.secondary,
                onTap: onChanged,
              ),
            ),
          ),
          Visibility(
            visible: widget.showTriggerOrder,
            child: Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Align(
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Container(
                      width: 20,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Container(
                      width: 20,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
