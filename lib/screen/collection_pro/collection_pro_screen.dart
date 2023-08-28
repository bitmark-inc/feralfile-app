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
import 'package:autonomy_flutter/screen/playlists/list_playlists/list_playlists.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/collection_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/searchBar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/models/album_model.dart';
import 'package:nft_collection/models/asset_token.dart';

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
  final controller = ScrollController();
  late String searchStr;
  late bool isSearching;
  final SectionInfo sectionInfo = SectionInfo(state: {
    CollectionProSection.collection: true,
    CollectionProSection.medium: true,
    CollectionProSection.artist: true,
  });

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    loadCollection();
    searchStr = '';
    isSearching = false;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    loadCollection();
    super.didPopNext();
  }

  loadCollection() {
    _bloc.add(LoadCollectionEvent());
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
        builder: (context, state) {
          if (state is CollectionLoadedState) {
            final listAlbumByMedium = state.listAlbumByMedium;
            final listAlbumByArtist = state.listAlbumByArtist;
            final paddingTop = MediaQuery.of(context).viewPadding.top;
            return BlocBuilder<IdentityBloc, IdentityState>(
                builder: (context, state) {
                  final identityMap = state.identityMap
                    ..removeWhere((key, value) => value.isEmpty);
                  return CustomScrollView(
                    controller: controller,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            headDivider(),
                            const SizedBox(height: 7),
                          ],
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 15),
                      ),
                      SliverToBoxAdapter(
                        child: HeaderView(
                          paddingTop: paddingTop,
                          isShowLogo: !isSearching,
                          action: ActionBar(
                            searchBar: AuSearchBar(
                              onChanged: (text) {
                                setState(() {
                                  searchStr = text;
                                });
                              },
                            ),
                            onSearch: () {
                              setState(() {
                                isSearching = true;
                              });
                            },
                            onCancel: () {
                              setState(() {
                                searchStr = '';
                                isSearching = false;
                              });
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 23),
                      ),
                      SliverToBoxAdapter(
                        child: addOnlyDivider(
                            color: AppColor.auQuickSilver, border: 0.25),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 60),
                      ),
                      const SliverToBoxAdapter(
                        child: CollectionSection(),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 60),
                      ),
                      SliverToBoxAdapter(
                        child: AlbumSection(
                            listAlbum: listAlbumByMedium,
                            albumType: AlbumType.medium,
                            identityMap: identityMap),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 60),
                      ),
                      SliverToBoxAdapter(
                        child: AlbumSection(
                            listAlbum: listAlbumByArtist,
                            albumType: AlbumType.artist,
                            identityMap: identityMap),
                      ),
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
}

class Header extends StatelessWidget {
  final String title;
  final String? subTitle;
  final Widget? icon;
  final Function()? onTap;

  const Header({
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
  final Map<String, String>? identityMap;

  const AlbumSection(
      {super.key,
      required this.listAlbum,
      required this.albumType,
      this.identityMap});

  @override
  State<AlbumSection> createState() => _AlbumSectionState();
}

class _AlbumSectionState extends State<AlbumSection> {
  Widget _header(BuildContext context, int total) {
    final title = widget.albumType == AlbumType.medium ? 'Medium' : 'Artist';
    return Header(title: title, subTitle: "$total");
  }

  Widget _icon(AlbumModel album) {
    switch (widget.albumType) {
      case AlbumType.medium:
        return SvgPicture.asset(
          "assets/images/medium_image.svg",
          width: 42,
          height: 42,
        );
      case AlbumType.artist:
        return SvgPicture.asset(
          "assets/images/medium_image.svg",
          width: 42,
          height: 42,
        );
        return CachedNetworkImage(
          imageUrl: album.thumbnailURL ?? "",
          width: 42,
          height: 42,
        );
    }
  }

  Widget _item(
      BuildContext context, AlbumModel album, Map<String, String> identityMap) {
    final theme = Theme.of(context);
    final title =
        ((album.name != album.id) ? album.name : identityMap[album.id]) ??
            album.id;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.albumPage,
          arguments: AlbumScreenPayload(
            type: widget.albumType,
            album: album,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            _icon(album),
            const SizedBox(width: 33),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.ppMori400Black14,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${album.total}', style: theme.textTheme.ppMori400Grey12),
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listAlbum.length,
            itemBuilder: (context, index) {
              final album = listAlbum[index];
              return _item(context, album, widget.identityMap ?? {});
            },
            separatorBuilder: (BuildContext context, int index) {
              return addDivider();
            },
          ),
        ],
      ),
    );
  }
}

class CollectionSection extends StatefulWidget {
  final String? filterString;

  const CollectionSection({super.key, this.filterString});

  @override
  State<CollectionSection> createState() => _CollectionSectionState();
}

class _CollectionSectionState extends State<CollectionSection>
    with RouteAware, WidgetsBindingObserver {
  final _configurationService = injector.get<ConfigurationService>();
  final _playlistService = injector.get<PlaylistService>();
  final _versionService = injector.get<VersionService>();
  late ValueNotifier<List<PlayListModel>?> _playlists;

  Future<List<PlayListModel>?> getPlaylist() async {
    final isSubscribed = _configurationService.isPremium();
    final isDemo = _configurationService.isDemoArtworksMode();

    if (!isSubscribed && !isDemo) return null;
    if (isDemo) {
      return _versionService.getDemoAccountFromGithub();
    }
    return _playlistService.getPlayList();
  }

  _initPlayList() async {
    _playlists.value = await getPlaylist() ?? [];
    _playlists.value!.filter(widget.filterString);
  }

  @override
  void initState() {
    _playlists = ValueNotifier(null);
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
    return Header(
      title: "Collections",
      subTitle: "$total",
      icon: const Icon(
        AuIcon.add,
        size: 22,
        color: AppColor.primaryBlack,
      ),
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PlayListModel>?>(
      valueListenable: _playlists,
      builder: (context, value, child) {
        final playlists = value;
        if (playlists == null) return const SizedBox.shrink();
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
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: SizedBox(
                height: 200,
                width: 400,
                child: ListPlaylistsScreen(
                  key: Key(playlistKey),
                  playlists: _playlists,
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

class ActionBar extends StatefulWidget {
  final Widget? searchIcon;
  final AuSearchBar searchBar;
  final Function()? onSearch;
  final Function()? onCancel;
  final bool isShowFull;

  const ActionBar(
      {super.key,
      this.searchIcon,
      required this.searchBar,
      this.onSearch,
      this.onCancel,
      this.isShowFull = false});

  @override
  State<ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> {
  late bool _isShowFull;

  @override
  void initState() {
    _isShowFull = widget.isShowFull;
    super.initState();
  }

  Widget _searchIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isShowFull = !_isShowFull;
        });
        widget.onSearch?.call();
      },
      child: widget.searchIcon ??
          SvgPicture.asset(
            "assets/images/search.svg",
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
                AppColor.secondarySpanishGrey, BlendMode.srcIn),
          ),
    );
  }

  Widget _searchingBar(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: widget.searchBar,
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () {
            widget.onCancel?.call();
            setState(() {
              _isShowFull = !_isShowFull;
            });
          },
          child: Text(
            "Cancel",
            style: theme.textTheme.ppMori400Grey14,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isShowFull) {
      return _searchingBar(context);
    }
    return Row(
      children: [const Spacer(), _searchIcon(context)],
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

extension CollectionProSectionExtension on CollectionProSection {
  String get title {
    switch (this) {
      case CollectionProSection.collection:
        return "Collections";
      case CollectionProSection.medium:
        return "Medium";
      case CollectionProSection.artist:
        return "Artist";
    }
  }
}

extension CollectionProSectionListExtension on List<CollectionProSection> {
  bool shouldShowSection(CollectionProSection section) {
    return isEmpty || contains(section);
  }
}
