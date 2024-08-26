import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/artists_list_page/artists_list_page.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/playlists/list_playlists/list_playlists.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/screen/predefined_collection/predefined_collection_screen.dart';
import 'package:autonomy_flutter/screen/wallet/wallet_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/collection_ext.dart';
import 'package:autonomy_flutter/util/predefined_collection_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/galery_thumbnail_item.dart';
import 'package:autonomy_flutter/view/get_started_banner.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/predefined_collection/predefined_collection_item.dart';
import 'package:autonomy_flutter/view/search_bar.dart';
import 'package:autonomy_flutter/view/title_text.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/predefined_collection_model.dart';

class CollectionPro extends StatefulWidget {
  final List<CompactedAssetToken> tokens;
  final ScrollController scrollController;

  const CollectionPro(
      {required this.tokens, required this.scrollController, super.key});

  @override
  State<CollectionPro> createState() => CollectionProState();
}

class CollectionProState extends State<CollectionPro>
    with RouteAware, WidgetsBindingObserver {
  final _bloc = injector.get<CollectionProBloc>();
  final _identityBloc = injector.get<IdentityBloc>();
  late ScrollController _scrollController;
  late ValueNotifier<String> searchStr;
  late bool isShowSearchBar;
  final GlobalKey<CollectionSectionState> _collectionSectionKey = GlobalKey();
  List<PredefinedCollectionModel> _listPredefinedCollectionByArtist = [];
  List<PredefinedCollectionModel> _listPredefinedCollectionByMedium = [];
  List<CompactedAssetToken> _works = [];
  late bool _isLoaded;
  late bool _showGetStartedBanner = false;
  final _configurationService = injector<ConfigurationService>();
  static const _maxArtistsView = 30;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _isLoaded = false;
    _showGetStartedBanner = _configurationService.getShowAddAddressBanner();
    searchStr = ValueNotifier('');
    searchStr.addListener(() {
      loadCollection();
    });
    isShowSearchBar = false;
    _scrollController = widget.scrollController;
    loadCollection();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didPopNext() {
    loadCollection();
    super.didPopNext();
  }

  void loadCollection() {
    unawaited(refreshCollectionSection());
    _bloc.add(LoadCollectionEvent(filterStr: searchStr.value));
  }

  void fetchIdentities(CollectionLoadedState state) {
    final listPredefinedCollectionByArtist =
        state.listPredefinedCollectionByArtist;
    final neededIdentities = [
      ...?listPredefinedCollectionByArtist?.map((e) => e.id),
    ].whereNotNull().toList().unique()
      ..removeWhere((element) => element == '');

    if (neededIdentities.isNotEmpty) {
      _identityBloc.add(GetIdentityEvent(neededIdentities));
    }
  }

  Future<void> refreshCollectionSection() async {
    final collectionSectionState = _collectionSectionKey.currentState;
    if (collectionSectionState != null) {
      await collectionSectionState.refreshPlaylist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top + 40;
    return Scaffold(
      appBar: getFFAppBar(
        context,
        onBack: () {
          Navigator.pop(context);
        },
        centerTitle: false,
        title: TitleText(title: 'organize'.tr()),
        action: !isShowSearchBar
            ? IconButton(
                onPressed: () {
                  setState(() {
                    isShowSearchBar = true;
                  });
                },
                constraints: const BoxConstraints(
                  maxWidth: 44,
                  maxHeight: 44,
                  minWidth: 44,
                  minHeight: 44,
                ),
                icon: Padding(
                  padding: const EdgeInsets.all(0),
                  child: SvgPicture.asset(
                    'assets/images/search.svg',
                    width: 24,
                    height: 24,
                    colorFilter:
                        const ColorFilter.mode(AppColor.white, BlendMode.srcIn),
                  ),
                ),
              )
            : const SizedBox(),
      ),
      backgroundColor: AppColor.primaryBlack,
      body: SafeArea(
        top: false,
        bottom: false,
        child: BlocConsumer(
          bloc: _bloc,
          listener: (context, state) {
            if (state is CollectionLoadedState) {
              fetchIdentities(state);
              setState(() {
                _listPredefinedCollectionByMedium =
                    state.listPredefinedCollectionByMedium ?? [];
                _works = state.works;
                _isLoaded = true;
              });
            }
          },
          builder: (context, collectionProState) {
            if (collectionProState is CollectionLoadedState) {
              return BlocConsumer<IdentityBloc, IdentityState>(
                  listener: (context, identityState) {
                    final identityMap = identityState.identityMap
                      ..removeWhere((key, value) => value.isEmpty);
                    final listPredefinedCollectionByArtist = (collectionProState
                                .listPredefinedCollectionByArtist ??
                            [])
                        .map(
                          (e) {
                            String name = e.name ?? e.id;
                            if (name == e.id) {
                              name = name.toIdentityOrMask(identityMap) ??
                                  name.maskOnly(5);
                            }
                            e.name = name;
                            return e;
                          },
                        )
                        .toList()
                        .filterByName(searchStr.value)
                      ..sort((a, b) => a.name.compareSearchKey(b.name));
                    setState(() {
                      _listPredefinedCollectionByArtist =
                          listPredefinedCollectionByArtist;
                    });
                  },
                  builder: (context, identityState) {
                    final isEmptyView = !_isLoaded ||
                        (_isEmptyCollection() && searchStr.value.isEmpty);
                    final isSearchEmptyView = _isLoaded &&
                        _isEmptyCollection() &&
                        searchStr.value.isNotEmpty;
                    return CustomScrollView(
                      controller: _scrollController,
                      shrinkWrap: true,
                      slivers: [
                        if (isShowSearchBar)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: ActionBar(
                                searchBar: AuSearchBar(
                                  onChanged: (text) {},
                                  onSearch: (text) {
                                    setState(() {
                                      searchStr.value = text;
                                    });
                                  },
                                  onClear: (text) {
                                    setState(() {
                                      searchStr.value = text;
                                    });
                                  },
                                ),
                                onCancel: () {
                                  setState(() {
                                    searchStr.value = '';
                                    isShowSearchBar = false;
                                  });
                                },
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: paddingTop),
                        ),
                        if (!isEmptyView)
                          SliverToBoxAdapter(
                            child: ValueListenableBuilder(
                              valueListenable: searchStr,
                              builder: (BuildContext context, String value,
                                      Widget? child) =>
                                  CollectionSection(
                                key: _collectionSectionKey,
                                filterString: value,
                              ),
                            ),
                          ),
                        if (isEmptyView) ...[
                          SliverToBoxAdapter(
                            child: Visibility(
                              visible: isEmptyView,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: _emptyView(context),
                              ),
                            ),
                          ),
                        ] else if (isSearchEmptyView) ...[
                          SliverToBoxAdapter(
                            child: Visibility(
                              visible: isSearchEmptyView,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: _searchEmptyView(context),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 60),
                          ),
                          if (searchStr.value.isEmpty) ...[
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                _predefinedCollectionByMediumBuilder,
                                childCount:
                                    _listPredefinedCollectionByMedium.length +
                                        1,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 60),
                            ),
                          ],
                          if (searchStr.value.isNotEmpty) ...[
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                _worksBuilder,
                                childCount: _works.length + 1,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 60),
                            ),
                          ],
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              _predefinedCollectionByArtistBuilder,
                              childCount: min(
                                      _listPredefinedCollectionByArtist.length,
                                      _maxArtistsView) +
                                  1,
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ],
                    );
                  },
                  bloc: _identityBloc);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  bool _isEmptyCollection() {
    final collection =
        _collectionSectionKey.currentState?.filterPlaylist(searchStr.value) ??
            [];
    final isEmpty = _listPredefinedCollectionByArtist.isEmpty &&
            _listPredefinedCollectionByMedium.isEmpty ||
        (_works.isEmpty &&
            searchStr.value.isNotEmpty &&
            _listPredefinedCollectionByArtist.isEmpty &&
            collection.isEmpty);
    return isEmpty;
  }

  Widget _searchEmptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'no_results'.tr(),
      style: theme.textTheme.ppMori400White14,
    );
  }

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'see_your_collection'.tr(),
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 15),
        if (_showGetStartedBanner)
          GetStartedBanner(
            onClose: () async {
              await _hideGetStartedBanner();
            },
            title: 'add_collection_from_address'.tr(),
            onGetStarted: _onGetStarted,
          )
      ],
    );
  }

  Future<void> _hideGetStartedBanner() async {
    setState(() {
      _showGetStartedBanner = false;
    });
    await _configurationService.setShowPostcardBanner(false);
  }

  Future<void> _onGetStarted() async {
    await Navigator.of(context).pushNamed(AppRouter.walletPage,
        arguments: const WalletPagePayload(openAddAddress: true));
  }

  Widget _predefinedCollectionByArtistBuilder(BuildContext context, int index) {
    const type = PredefinedCollectionType.artist;
    final isSearching = searchStr.value.isNotEmpty;
    final numberOfArtists = _listPredefinedCollectionByArtist.length;
    final displaySeeAll =
        !isSearching && index == 0 && numberOfArtists > _maxArtistsView;
    final Widget? action = displaySeeAll
        ? GestureDetector(
            onTap: () async {
              await Navigator.of(context).pushNamed(AppRouter.artistsListPage,
                  arguments: ArtistsListPagePayload(
                      _listPredefinedCollectionByArtist));
            },
            child: Text(
              'see_all'.tr(),
              style: Theme.of(context).textTheme.ppMori400White14.copyWith(
                    decoration: TextDecoration.underline,
                  ),
            ))
        : null;
    return _predefinedCollectionBuilder(context, index, type, action: action);
  }

  Widget _predefinedCollectionByMediumBuilder(BuildContext context, int index) {
    const type = PredefinedCollectionType.medium;
    return _predefinedCollectionBuilder(context, index, type);
  }

  Widget _worksBuilder(BuildContext context, int index) {
    const padding = EdgeInsets.symmetric(horizontal: 8);
    final sep = addDivider(color: AppColor.auLightGrey);
    if (index == 0) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeaderView(title: 'works'.tr(), padding: EdgeInsets.zero),
            const SizedBox(
              height: 30,
            ),
            if (searchStr.value.isNotEmpty && _works.isEmpty)
              _searchEmptyView(context),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: SizedBox(
                height: 164,
                child: _artworkItem(context, _works[index - 1]),
              ),
            ),
            sep,
          ],
        ),
      );
    }
  }

  PredefinedCollectionModel _getPredefinedCollection(
      int index, PredefinedCollectionType type) {
    switch (type) {
      case PredefinedCollectionType.medium:
        return _listPredefinedCollectionByMedium[index];
      case PredefinedCollectionType.artist:
        return _listPredefinedCollectionByArtist[index];
    }
  }

  Widget _predefinedCollectionBuilder(
    BuildContext context,
    int index,
    PredefinedCollectionType type, {
    Widget? action,
  }) {
    final sep = addOnlyDivider(color: AppColor.auGreyBackground);
    const padding = EdgeInsets.symmetric(horizontal: 8);
    if (index == 0) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _predefinedCollectionHeader(context, type, action: action),
            const SizedBox(
              height: 30,
            ),
            if (searchStr.value.isNotEmpty &&
                _listPredefinedCollectionByArtist.isEmpty &&
                type == PredefinedCollectionType.artist)
              _searchEmptyView(context)
          ],
        ),
      );
    } else {
      final predefinedCollection = _getPredefinedCollection(index - 1, type);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            PredefinedCollectionItem(
              predefinedCollection: predefinedCollection,
              type: type,
              searchStr: searchStr.value,
            ),
            sep,
          ],
        ),
      );
    }
  }

  Widget _predefinedCollectionHeader(
      BuildContext context, PredefinedCollectionType type,
      {Widget? action}) {
    final title = type == PredefinedCollectionType.medium
        ? 'medium'.tr()
        : 'artists'.tr();
    return HeaderView(
      title: title,
      padding: EdgeInsets.zero,
      action: action,
    );
  }

  Widget _artworkItem(BuildContext context, CompactedAssetToken token) {
    final theme = Theme.of(context);
    final title = token.displayTitle ?? '';
    final artistName = token.artistTitle ?? token.artistID ?? '';
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRouter.artworkDetailsPage,
          arguments: ArtworkDetailPayload(
            [
              ArtworkIdentity(token.id, token.owner),
            ],
            0,
          ),
        );
      },
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: GaleryThumbnailItem(
              assetToken: token,
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  AppRouter.artworkDetailsPage,
                  arguments: ArtworkDetailPayload(
                    [
                      ArtworkIdentity(token.id, token.owner),
                    ],
                    0,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 19),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.ppMori400White14,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  artistName,
                  style: theme.textTheme.ppMori400Black14
                      .copyWith(color: AppColor.auLightGrey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CollectionSection extends StatefulWidget {
  final String filterString;

  const CollectionSection({super.key, this.filterString = ''});

  @override
  State<CollectionSection> createState() => CollectionSectionState();
}

class CollectionSectionState extends State<CollectionSection>
    with RouteAware, WidgetsBindingObserver {
  final _configurationService = injector.get<ConfigurationService>();
  final _playlistService = injector.get<PlaylistService>();
  final _versionService = injector.get<VersionService>();
  late ValueNotifier<List<PlayListModel>?> _playlists;
  List<PlayListModel>? _currentPlaylists;
  late bool isDemo;

  Future<List<PlayListModel>?> getPlaylist({bool withDefault = false}) async {
    if (isDemo) {
      return _versionService.getDemoAccountFromGithub();
    }
    List<PlayListModel> playlists = await _playlistService.getPlayList();
    if (withDefault) {
      final defaultPlaylists = await _playlistService.defaultPlaylists();
      playlists = defaultPlaylists..addAll(playlists);
    }
    return playlists;
  }

  Future<void> _initPlayList() async {
    _playlists.value = await getPlaylist() ?? [];
  }

  List<PlayListModel> getPlaylists() => _currentPlaylists ?? [];

  List<PlayListModel> filterPlaylist(String filterString) =>
      _playlists.value?.filter(filterString) ?? [];

  @override
  void initState() {
    _playlists = ValueNotifier(null);
    _playlists.addListener(() {
      setState(() {
        _currentPlaylists = filterPlaylist(widget.filterString);
      });
    });
    isDemo = _configurationService.isDemoArtworksMode();
    super.initState();
    unawaited(_initPlayList());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    unawaited(_initPlayList());
    super.didPopNext();
  }

  Future<void> _gotoCreatePlaylist(BuildContext context) async {
    await Navigator.of(context)
        .pushNamed(AppRouter.createPlayListPage)
        .then((value) {
      if (value != null && value is PlayListModel) {
        Navigator.pushNamed(
          context,
          AppRouter.viewPlayListPage,
          arguments: ViewPlaylistScreenPayload(playListModel: value),
        );
      }
    });
  }

  Future<void> refreshPlaylist() async {
    await _initPlayList();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPlaylists == null) {
      return const SizedBox.shrink();
    }
    final playlists = _currentPlaylists!;
    final playlistIDsString = playlists.map((e) => e.id).toList().join();
    final playlistKeyBytes = utf8.encode(playlistIDsString);
    final playlistKey = sha256.convert(playlistKeyBytes).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListPlaylistsScreen(
          key: Key(playlistKey),
          playlists: _playlists,
          filter: widget.filterString,
          onReorder: (oldIndex, newIndex) {},
          onAdd: () async {
            await _gotoCreatePlaylist(context);
          },
        )
      ],
    );
  }
}

class SectionInfo {
  Map<CollectionProSection, bool> state;

  SectionInfo({required this.state});
}

enum CollectionProSection {
  collection,
  medium,
  artist;

  static List<CollectionProSection> get allSections => [
        CollectionProSection.collection,
        CollectionProSection.medium,
        CollectionProSection.artist,
      ];
}
