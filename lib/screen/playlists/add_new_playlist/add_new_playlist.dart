import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/add_new_playlist/add_new_playlist_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/searchBar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/address_index.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';

import '../../../util/token_ext.dart';

class AddNewPlaylistScreen extends StatefulWidget {
  final PlayListModel? playListModel;

  const AddNewPlaylistScreen({Key? key, this.playListModel}) : super(key: key);

  @override
  State<AddNewPlaylistScreen> createState() => _AddNewPlaylistScreenState();
}

class _AddNewPlaylistScreenState extends State<AddNewPlaylistScreen>
    with AfterLayoutMixin {
  final bloc = injector.get<AddNewPlaylistBloc>();
  final nftBloc = injector.get<NftCollectionBloc>();
  final _playlistNameC = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  List<AssetToken> tokensPlaylist = [];
  final _controller = ScrollController();
  late String _searchText;

  @override
  void initState() {
    _searchText = '';
    super.initState();

    _playlistNameC.text = widget.playListModel?.name ?? '';
    _controller.addListener(_scrollListenerToLoadMore);
    refreshTokens().then((value) {
      nftBloc.add(GetTokensByOwnerEvent(pageKey: PageKey.init()));
    });
    bloc.add(InitPlaylist(playListModel: widget.playListModel));
  }

  @override
  void afterFirstLayout(BuildContext context) {
    injector<ConfigurationService>().setAlreadyShowCreatePlaylistTip(true);
    injector<ConfigurationService>().showCreatePlaylistTip.value = false;
  }

  _scrollListenerToLoadMore() {
    if (_controller.position.pixels + 100 >=
        _controller.position.maxScrollExtent) {
      _loadMore();
    }
  }

  _loadMore() {
    final nextKey = nftBloc.state.nextKey;
    if (nextKey == null || nextKey.isLoaded) return;
    nftBloc.add(GetTokensByOwnerEvent(pageKey: nextKey));
  }

  Future<List<AddressIndex>> getAddressIndexes() async {
    final accountService = injector<AccountService>();
    return await accountService.getAllAddressIndexes();
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
    _playlistNameC.dispose();
    super.dispose();
  }

  List<CompactedAssetToken> setupPlayList({
    required List<CompactedAssetToken> tokens,
    List<String>? selectedTokens,
  }) {
    tokens = tokens.filterAssetToken().filterByTitleContain(_searchText);
    bloc.state.tokens = tokens;
    if (tokens.length <= INDEXER_TOKENS_MAXIMUM) {
      _loadMore();
    }
    return tokens;
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
      },
      builder: (context, state) {
        final paddingTop = MediaQuery.of(context).viewPadding.top;
        return Scaffold(
          backgroundColor: theme.primaryColor,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: BlocBuilder<NftCollectionBloc, NftCollectionBlocState>(
                bloc: nftBloc,
                builder: (context, nftState) {
                  final selectedCount = nftState.tokens.items
                      .where((element) =>
                          state.selectedIDs?.contains(element.id) ?? false)
                      .length;
                  final isSelectedAll = selectedCount == state.tokens?.length;
                  return SafeArea(
                    top: false,
                    bottom: false,
                    child: Stack(
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              HeaderView(paddingTop: paddingTop, isWhite: true),
                              AuSearchBar(
                                onChanged: (text) {
                                  setState(() {
                                    _searchText = text;
                                  });
                                },
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('playlist_name'),
                                          style:
                                              theme.textTheme.ppMori400Grey12,
                                        ),
                                        TextFormField(
                                          controller: _playlistNameC,
                                          cursorColor:
                                              theme.colorScheme.secondary,
                                          style: theme.primaryTextTheme
                                              .ppMori700White24,
                                          decoration: InputDecoration(
                                            hintText: tr('untitled'),
                                            hintStyle:
                                                theme.textTheme.ppMori700Grey24,
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 2,
                                                color:
                                                    theme.colorScheme.secondary,
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 2,
                                                color:
                                                    theme.colorScheme.secondary,
                                              ),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 2,
                                                color:
                                                    theme.colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            tr(
                                              selectedCount != 1
                                                  ? 'artworks_selected'
                                                  : 'artwork_selected',
                                              args: [selectedCount.toString()],
                                            ),
                                            style: theme
                                                .textTheme.ppMori400White12,
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () => bloc.add(
                                                SelectItemPlaylist(
                                                    isSelectAll:
                                                        !isSelectedAll)),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: theme.disableColor,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(64),
                                              ),
                                              child: Text(
                                                isSelectedAll
                                                    ? tr('unselect_all')
                                                    : tr('select_all'),
                                                style: theme
                                                    .textTheme.ppMori400Grey12,
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
                                child: NftCollectionGrid(
                                  state: nftState.state,
                                  tokens: nftState.tokens.items,
                                  loadingIndicatorBuilder: loadingView,
                                  customGalleryViewBuilder: (context, tokens) =>
                                      _assetsWidget(
                                    context,
                                    setupPlayList(tokens: tokens),
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
                        ),
                        Positioned(
                          bottom: 30,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  PrimaryButton(
                                    onTap: () {
                                      Navigator.pop(context);
                                      final metricClient =
                                          injector<MetricClientService>();
                                      metricClient.addEvent(
                                          MixpanelEvent.undoCreatePlaylist);
                                    },
                                    width: 170,
                                    text: 'cancel'.tr(),
                                    color: theme.auLightGrey,
                                  ),
                                  PrimaryButton(
                                    onTap: () {
                                      if (selectedCount <= 0) {
                                        return;
                                      }
                                      bloc.add(
                                        CreatePlaylist(
                                          name: _playlistNameC.text.isNotEmpty
                                              ? _playlistNameC.text
                                              : null,
                                        ),
                                      );
                                    },
                                    width: 170,
                                    text: tr('save'),
                                    color: theme.auSuperTeal,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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
      itemBuilder: (context, index) {
        return ThubnailPlaylistItem(
          token: tokens[index],
          cachedImageSize: cachedImageSize,
          isSelected: selectedTokens?.contains(tokens[index].id) ?? false,
          onChanged: (value) {
            onChanged?.call(tokens[index].id, value ?? false);
          },
          usingThumbnailID: index > 50,
        );
      },
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
    Key? key,
    required this.token,
    required this.cachedImageSize,
    this.showSelect = true,
    this.isSelected = false,
    this.onChanged,
    this.showTriggerOrder = false,
    this.usingThumbnailID = true,
  }) : super(key: key);

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

  onChanged(value) {
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
