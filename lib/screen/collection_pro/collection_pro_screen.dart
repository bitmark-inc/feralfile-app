import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/album/album_screen.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/playlists/list_playlists/list_playlists.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/album_ext.dart';
import 'package:autonomy_flutter/util/collection_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/galery_thumbnail_item.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/searchBar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/models/album_model.dart';
import 'package:nft_collection/models/asset_token.dart';

import 'album.dart';

class CollectionPro extends StatefulWidget {
  final List<CompactedAssetToken> tokens;

  const CollectionPro({super.key, required this.tokens});

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
  late bool isShowFullHeader;
  final GlobalKey<CollectionSectionState> _collectionSectionKey = GlobalKey();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    searchStr = ValueNotifier('');
    searchStr.addListener(() {
      loadCollection();
    });
    isShowSearchBar = false;
    isShowFullHeader = true;
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListenerShowfullHeader);
    loadCollection();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    loadCollection();
    super.didPopNext();
  }

  _scrollListenerShowfullHeader() {
    if (_scrollController.offset > 50 && isShowSearchBar) {
      if (isShowFullHeader) {
        setState(() {
          isShowFullHeader = false;
        });
      }
    } else {
      if (!isShowFullHeader) {
        setState(() {
          isShowFullHeader = true;
        });
      }
    }
  }

  loadCollection() {
    refreshCollectionSection();
    _bloc.add(LoadCollectionEvent(filterStr: searchStr.value));
  }

  fetchIdentities(CollectionLoadedState state) {
    final listAlbumByArtist = state.listAlbumByArtist;
    final neededIdentities = [
      ...?listAlbumByArtist?.map((e) => e.id).toList(),
    ].whereNotNull().toList().unique();
    neededIdentities.removeWhere((element) => element == '');

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
    return SafeArea(
      child: BlocConsumer(
        bloc: _bloc,
        listener: (context, state) {
          if (state is CollectionLoadedState) {
            fetchIdentities(state);
          }
        },
        builder: (context, collectionProState) {
          if (collectionProState is CollectionLoadedState) {
            final listAlbumByMedium = collectionProState.listAlbumByMedium;

            final works = collectionProState.works;
            final paddingTop = MediaQuery.of(context).viewPadding.top;
            return BlocBuilder<IdentityBloc, IdentityState>(
                builder: (context, identityState) {
                  final identityMap = identityState.identityMap
                    ..removeWhere((key, value) => value.isEmpty);
                  final listAlbumByArtist = collectionProState.listAlbumByArtist
                      ?.map(
                        (e) {
                          final name = identityMap[e.id] ?? e.name ?? e.id;
                          e.name = name;
                          return e;
                        },
                      )
                      .toList()
                      .filterByName(searchStr.value);
                  return Scaffold(
                    body: Stack(
                      children: [
                        CustomScrollView(
                          shrinkWrap: true,
                          controller: _scrollController,
                          slivers: [
                            SliverAppBar(
                              pinned: isShowSearchBar,
                              centerTitle: true,
                              backgroundColor: Colors.white,
                              expandedHeight: isShowFullHeader ? 126 : 75,
                              collapsedHeight: isShowFullHeader ? 126 : 75,
                              shadowColor: Colors.transparent,
                              flexibleSpace: Column(
                                children: [
                                  if (isShowFullHeader) ...[
                                    headDivider(),
                                    const SizedBox(height: 22),
                                  ],
                                  SizedBox(
                                    height: 50,
                                    child: !isShowSearchBar
                                        ? HeaderView(
                                            paddingTop: paddingTop,
                                            action: GestureDetector(
                                              child: SvgPicture.asset(
                                                "assets/images/search.svg",
                                                width: 24,
                                                height: 24,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                        AppColor.primaryBlack,
                                                        BlendMode.srcIn),
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
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15),
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
                                  ),
                                  const SizedBox(height: 23),
                                  addOnlyDivider(
                                      color: AppColor.auQuickSilver,
                                      border: 0.25)
                                ],
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 60),
                            ),
                            SliverToBoxAdapter(
                              child: ValueListenableBuilder(
                                valueListenable: searchStr,
                                builder: (BuildContext context, String value,
                                    Widget? child) {
                                  return CollectionSection(
                                    key: _collectionSectionKey,
                                    filterString: value,
                                  );
                                },
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 60),
                            ),
                            if (searchStr.value.isEmpty) ...[
                              SliverToBoxAdapter(
                                child: AlbumSection(
                                  listAlbum: listAlbumByMedium,
                                  albumType: AlbumType.medium,
                                  searchStr: searchStr.value,
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 60),
                              ),
                            ],
                            if (searchStr.value.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: WorksSection(
                                  works: works,
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 60),
                              ),
                            ],
                            SliverToBoxAdapter(
                              child: AlbumSection(
                                listAlbum: listAlbumByArtist,
                                albumType: AlbumType.artist,
                                searchStr: searchStr.value,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 40),
                            )
                          ],
                        ),
                      ],
                    ),
                  );
                },
                bloc: _identityBloc);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subTitle;
  final Widget? icon;
  final Function()? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.subTitle,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.ppMori400Black14,
        ),
        const Spacer(),
        if (subTitle != null)
          Text(
            subTitle!,
            style: theme.textTheme.ppMori400Black14,
          ),
        if (icon != null) ...[
          const SizedBox(width: 15),
          GestureDetector(onTap: onTap, child: icon!)
        ],
      ],
    );
  }
}

class AlbumSection extends StatefulWidget {
  final List<AlbumModel>? listAlbum;
  final AlbumType albumType;
  final String searchStr;

  const AlbumSection(
      {super.key,
      required this.listAlbum,
      required this.albumType,
      required this.searchStr});

  @override
  State<AlbumSection> createState() => _AlbumSectionState();
}

class _AlbumSectionState extends State<AlbumSection> {
  Widget _header(BuildContext context, int total) {
    final title =
        widget.albumType == AlbumType.medium ? 'medium'.tr() : 'artists'.tr();
    final subTitle = widget.albumType == AlbumType.medium ? "" : "$total";
    return SectionHeader(title: title, subTitle: subTitle);
  }

  Widget _icon(AlbumModel album) {
    switch (widget.albumType) {
      case AlbumType.medium:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColor.auLightGrey,
          ),
          child: SvgPicture.asset(
            MediumCategoryExt.icon(album.id),
            width: 22,
            colorFilter:
                const ColorFilter.mode(AppColor.primaryBlack, BlendMode.srcIn),
          ),
        );
      case AlbumType.artist:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColor.auLightGrey,
          ),
        );
        return CachedNetworkImage(
            imageUrl: album.thumbnailURL ?? "",
            width: 42,
            height: 42,
            fit: BoxFit.cover,
            memCacheHeight: 42,
            memCacheWidth: 42,
            errorWidget: (context, url, error) =>
                const GalleryThumbnailErrorWidget(),
            placeholder: (context, url) => Container(
                  width: 42,
                  height: 42,
                  color: AppColor.disabledColor,
                ));
    }
  }

  Widget _item(BuildContext context, AlbumModel album) {
    final theme = Theme.of(context);
    var title = album.name ?? album.id;
    if (album.name == album.id) {
      title = title.maskOnly(5);
    }
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.albumPage,
          arguments: AlbumScreenPayload(
            type: widget.albumType,
            album: album,
            filterStr: widget.searchStr,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            _icon(
              album,
            ),
            const SizedBox(width: 33),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.ppMori400Black14,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${album.total}', style: theme.textTheme.ppMori400Grey14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAlbum = widget.listAlbum;
    const padding = 15.0;
    if (listAlbum == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(left: padding, right: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, listAlbum.length),
          addDivider(color: AppColor.primaryBlack),
          CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverList.separated(
                separatorBuilder: (BuildContext context, int index) {
                  return addDivider();
                },
                itemBuilder: (BuildContext context, int index) {
                  final album = listAlbum[index];
                  return _item(context, album);
                },
                itemCount: listAlbum.length,
              )
            ],
          ),
        ],
      ),
    );
  }
}

class WorksSection extends StatefulWidget {
  final List<CompactedAssetToken> works;

  const WorksSection({super.key, required this.works});

  @override
  State<WorksSection> createState() => _WorksSectionState();
}

class _WorksSectionState extends State<WorksSection> {
  @override
  void initState() {
    super.initState();
  }

  Widget _artworkItem(BuildContext context, CompactedAssetToken token) {
    final theme = Theme.of(context);
    final title = token.title ?? "";
    final artistName = token.artistTitle ?? token.artistID ?? "";
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
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
              onTap: () {
                Navigator.pushNamed(
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
                  style: theme.textTheme.ppMori400Black14,
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

  @override
  Widget build(BuildContext context) {
    const padding = 15.0;
    final compactedAssetTokens = widget.works;

    return Padding(
      padding: const EdgeInsets.only(left: padding, right: padding),
      child: Column(
        children: [
          SectionHeader(
              title: "works".tr(), subTitle: "${compactedAssetTokens.length}"),
          addDivider(color: AppColor.primaryBlack),
          CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverList.separated(
                  itemBuilder: (BuildContext context, int index) {
                    final token = compactedAssetTokens[index];
                    return SizedBox(
                        height: 164, child: _artworkItem(context, token));
                  },
                  itemCount: compactedAssetTokens.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return addDivider(color: AppColor.auLightGrey);
                  }),
            ],
          ),
        ],
      ),
    );
  }
}

class CollectionSection extends StatefulWidget {
  final String filterString;

  const CollectionSection({super.key, this.filterString = ""});

  @override
  State<CollectionSection> createState() => CollectionSectionState();
}

class CollectionSectionState extends State<CollectionSection>
    with RouteAware, WidgetsBindingObserver {
  final _configurationService = injector.get<ConfigurationService>();
  final _playlistService = injector.get<PlaylistService>();
  final _versionService = injector.get<VersionService>();
  late ValueNotifier<List<PlayListModel>?> _playlists;
  late bool isDemo;

  Future<List<PlayListModel>?> getPlaylist() async {
    final isSubscribed = _configurationService.isPremium();
    if (!isSubscribed && !isDemo) return null;
    if (isDemo) {
      return _versionService.getDemoAccountFromGithub();
    }
    List<PlayListModel> playlists = await _playlistService.getPlayList();

    final defaultPlaylists = await _playlistService.defaultPlaylists();
    playlists = defaultPlaylists..addAll(playlists);
    return playlists;
  }

  Future<void> _initPlayList() async {
    _playlists.value = await getPlaylist() ?? [];
  }

  @override
  void initState() {
    _playlists = ValueNotifier(null);
    isDemo = _configurationService.isDemoArtworksMode();
    super.initState();
    _initPlayList();
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
    _initPlayList();
    super.didPopNext();
  }

  Widget _header(BuildContext context, int total) {
    final isShowAddIcon = widget.filterString.isEmpty;
    return SectionHeader(
      title: "collections".tr(),
      subTitle: "$total",
      icon: isShowAddIcon
          ? SvgPicture.asset(
              "assets/images/Add.svg",
              width: 22,
              height: 22,
            )
          : null,
      onTap: () {
        _gotoCreatePlaylist(context);
      },
    );
  }

  void _gotoCreatePlaylist(BuildContext context) {
    Navigator.of(context).pushNamed(AppRouter.createPlayListPage).then((value) {
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
    return ValueListenableBuilder<List<PlayListModel>?>(
      valueListenable: _playlists,
      builder: (context, value, child) {
        if (value == null) return const SizedBox.shrink();

        final playlists = value.filter(widget.filterString);
        final playlistIDsString = playlists.map((e) => e.id).toList().join();
        final playlistKeyBytes = utf8.encode(playlistIDsString);
        final playlistKey = sha256.convert(playlistKeyBytes).toString();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  _header(context, playlists.length),
                  addDivider(color: AppColor.primaryBlack),
                ],
              ),
            ),
            ListPlaylistsScreen(
              key: Key(playlistKey),
              playlists: _playlists,
              filter: widget.filterString,
              onReorder: (oldIndex, newIndex) {},
            )
          ],
        );
      },
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

  static List<CollectionProSection> get allSections {
    return [
      CollectionProSection.collection,
      CollectionProSection.medium,
      CollectionProSection.artist,
    ];
  }
}
