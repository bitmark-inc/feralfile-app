import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/playlists/list_playlists/list_playlists.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/screen/predefined_collection/predefined_collection_screen.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/collection_ext.dart';
import 'package:autonomy_flutter/util/medium_category_ext.dart';
import 'package:autonomy_flutter/util/predefined_collection_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/galery_thumbnail_item.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/search_bar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
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

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _isLoaded = false;
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
    final paddingTop = MediaQuery.of(context).padding.top;
    return SafeArea(
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
                          String name = identityMap[e.id] ?? e.name ?? e.id;
                          if (name == e.id) {
                            name = name.maskOnly(5);
                          }
                          e.name = name;
                          return e;
                        },
                      )
                      .toList()
                      .filterByName(searchStr.value)
                    ..sort((a, b) =>
                        a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));
                  setState(() {
                    _listPredefinedCollectionByArtist =
                        listPredefinedCollectionByArtist;
                  });
                },
                builder: (context, identityState) {
                  final isEmptyView = _isLoaded &&
                      searchStr.value.isNotEmpty &&
                      _isEmptyCollection();
                  return CustomScrollView(
                    controller: _scrollController,
                    shrinkWrap: true,
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(height: paddingTop),
                      ),
                      SliverToBoxAdapter(
                        child: _pageHeader(context),
                      ),
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
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: _emptyView(context),
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
                                  _listPredefinedCollectionByMedium.length + 1,
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
                            childCount:
                                _listPredefinedCollectionByArtist.length + 1,
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

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'no_results'.tr(),
      style: theme.textTheme.ppMori400White14,
    );
  }

  Widget _predefinedCollectionByArtistBuilder(BuildContext context, int index) {
    const type = PredefinedCollectionType.artist;
    return _predefinedCollectionBuilder(context, index, type);
  }

  Widget _predefinedCollectionByMediumBuilder(BuildContext context, int index) {
    const type = PredefinedCollectionType.medium;
    return _predefinedCollectionBuilder(context, index, type);
  }

  Widget _worksBuilder(BuildContext context, int index) {
    const padding = EdgeInsets.symmetric(horizontal: 15);
    final sep = addDivider(color: AppColor.auLightGrey);
    if (index == 0) {
      return Padding(
        padding: padding,
        child: Column(
          children: [
            HeaderView(title: 'works'.tr(), padding: EdgeInsets.zero),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
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
    PredefinedCollectionType type,
  ) {
    final sep = addOnlyDivider(color: AppColor.auGreyBackground);
    const padding = EdgeInsets.symmetric(horizontal: 15);
    if (index == 0) {
      return Padding(
        padding: padding,
        child: Column(
          children: [
            _predefinedCollectionHeader(
              context,
              type,
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      );
    } else {
      final predefinedCollection = _getPredefinedCollection(index - 1, type);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: _predefinedCollectionitem(
                  context, predefinedCollection, type, searchStr.value),
            ),
            sep,
          ],
        ),
      );
    }
  }

  Widget _predefinedCollectionitem(
      BuildContext context,
      PredefinedCollectionModel predefinedCollection,
      PredefinedCollectionType type,
      String searchStr) {
    final theme = Theme.of(context);
    var title = predefinedCollection.name ?? predefinedCollection.id;
    if (predefinedCollection.name == predefinedCollection.id) {
      title = title.maskOnly(5);
    }
    final titleStyle = theme.textTheme.ppMori400White14;
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRouter.predefinedCollectionPage,
          arguments: PredefinedCollectionScreenPayload(
            type: type,
            predefinedCollection: predefinedCollection,
            filterStr: searchStr,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            _predefinedCollectionIcon(
              predefinedCollection,
              type,
            ),
            const SizedBox(width: 33),
            Expanded(
              child: Text(
                title,
                style: titleStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${predefinedCollection.total}',
                style: theme.textTheme.ppMori400Grey14),
          ],
        ),
      ),
    );
  }

  Widget _predefinedCollectionIcon(
      PredefinedCollectionModel predefinedCollection,
      PredefinedCollectionType type) {
    switch (type) {
      case PredefinedCollectionType.medium:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColor.auLightGrey,
          ),
          child: SvgPicture.asset(
            MediumCategoryExt.icon(predefinedCollection.id),
            width: 22,
            colorFilter:
                const ColorFilter.mode(AppColor.primaryBlack, BlendMode.srcIn),
          ),
        );
      case PredefinedCollectionType.artist:
        final compactedAssetTokens = predefinedCollection.compactedAssetToken;
        return SizedBox(
          width: 42,
          height: 42,
          child: tokenGalleryThumbnailWidget(context, compactedAssetTokens, 100,
              usingThumbnailID: false,
              galleryThumbnailPlaceholder: Container(
                width: 42,
                height: 42,
                color: AppColor.auLightGrey,
              )),
        );
    }
  }

  Widget _predefinedCollectionHeader(
      BuildContext context, PredefinedCollectionType type) {
    final title = type == PredefinedCollectionType.medium
        ? 'medium'.tr()
        : 'artists'.tr();
    return HeaderView(
      title: title,
      padding: EdgeInsets.zero,
    );
  }

  Widget _pageHeader(BuildContext context) {
    final paddingTop = MediaQuery.of(context).viewPadding.top;
    return Padding(
      padding: EdgeInsets.only(top: paddingTop)
          .add(const EdgeInsets.fromLTRB(12, 33, 12, 42)),
      child: !isShowSearchBar
          ? HeaderView(
              padding: EdgeInsets.zero,
              title: 'organize'.tr(),
              action: GestureDetector(
                child: SvgPicture.asset(
                  'assets/images/search.svg',
                  width: 24,
                  height: 24,
                  colorFilter:
                      const ColorFilter.mode(AppColor.white, BlendMode.srcIn),
                ),
                onTap: () {
                  setState(() {
                    isShowSearchBar = true;
                  });
                },
              ),
            )
          : Align(
              alignment: Alignment.bottomLeft,
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
    );
  }

  Widget _artworkItem(BuildContext context, CompactedAssetToken token) {
    final theme = Theme.of(context);
    final title = token.title ?? '';
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
