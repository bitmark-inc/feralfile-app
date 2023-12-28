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
    _scrollController = widget.scrollController;
    _scrollController.addListener(_scrollListenerShowFullHeader);
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
    _scrollController.removeListener(_scrollListenerShowFullHeader);
    super.dispose();
  }

  @override
  void didPopNext() {
    loadCollection();
    super.didPopNext();
  }

  void _scrollListenerShowFullHeader() {
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
  Widget build(BuildContext context) => SafeArea(
        child: BlocConsumer(
          bloc: _bloc,
          listener: (context, state) {
            if (state is CollectionLoadedState) {
              fetchIdentities(state);
            }
          },
          builder: (context, collectionProState) {
            if (collectionProState is CollectionLoadedState) {
              final listPredefinedCollectionByMedium =
                  collectionProState.listPredefinedCollectionByMedium;

              final works = collectionProState.works;
              return BlocBuilder<IdentityBloc, IdentityState>(
                  builder: (context, identityState) {
                    final identityMap = identityState.identityMap
                      ..removeWhere((key, value) => value.isEmpty);
                    final listPredefinedCollectionByArtist = collectionProState
                        .listPredefinedCollectionByArtist
                        ?.map(
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
                      ?..sort((a, b) => a.name!
                          .toLowerCase()
                          .compareTo(b.name!.toLowerCase()));
                    return Stack(
                      children: [
                        CustomScrollView(
                          shrinkWrap: true,
                          slivers: [
                            SliverToBoxAdapter(
                              child: _header(context),
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
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 60),
                            ),
                            if (searchStr.value.isEmpty) ...[
                              SliverToBoxAdapter(
                                child: PredefinedCollectionSection(
                                  listPredefinedCollection:
                                      listPredefinedCollectionByMedium ?? [],
                                  predefinedCollectionType:
                                      PredefinedCollectionType.medium,
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
                              child: PredefinedCollectionSection(
                                listPredefinedCollection:
                                    listPredefinedCollectionByArtist ?? [],
                                predefinedCollectionType:
                                    PredefinedCollectionType.artist,
                                searchStr: searchStr.value,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 40),
                            ),
                          ],
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

  Widget _header(BuildContext context) {
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
}

class SectionHeader extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final String? subTitle;
  final Widget? icon;
  final Function()? onTap;

  const SectionHeader({
    required this.title,
    super.key,
    this.titleStyle,
    this.subTitle,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleDefaultStyle =
        theme.textTheme.ppMori700White24.copyWith(fontSize: 36);
    return Row(
      children: [
        Text(
          title,
          style: titleStyle ?? titleDefaultStyle,
        ),
        const Spacer(),
        if (subTitle != null)
          Text(
            subTitle!,
            style: theme.textTheme.ppMori400Black14,
          ),
        if (icon != null) ...[
          const SizedBox(width: 15),
          GestureDetector(onTap: onTap, child: icon)
        ],
      ],
    );
  }
}

class PredefinedCollectionSection extends StatefulWidget {
  final List<PredefinedCollectionModel> listPredefinedCollection;
  final PredefinedCollectionType predefinedCollectionType;
  final String searchStr;

  const PredefinedCollectionSection(
      {required this.listPredefinedCollection,
      required this.predefinedCollectionType,
      required this.searchStr,
      super.key});

  @override
  State<PredefinedCollectionSection> createState() =>
      _PredefinedCollectionSectionState();
}

class _PredefinedCollectionSectionState
    extends State<PredefinedCollectionSection> {
  Widget _header(BuildContext context, int total) {
    final title =
        widget.predefinedCollectionType == PredefinedCollectionType.medium
            ? 'medium'.tr()
            : 'artists'.tr();
    return SectionHeader(title: title, subTitle: '');
  }

  Widget _icon(PredefinedCollectionModel predefinedCollection) {
    switch (widget.predefinedCollectionType) {
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

  Widget _item(
      BuildContext context, PredefinedCollectionModel predefinedCollection) {
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
            type: widget.predefinedCollectionType,
            predefinedCollection: predefinedCollection,
            filterStr: widget.searchStr,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            _icon(
              predefinedCollection,
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

  @override
  Widget build(BuildContext context) {
    final listPredefinedCollection = widget.listPredefinedCollection;
    const padding = 15.0;
    return Padding(
      padding: const EdgeInsets.only(left: padding, right: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, listPredefinedCollection.length),
          const SizedBox(
            height: 30,
          ),
          CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverList.separated(
                separatorBuilder: (BuildContext context, int index) =>
                    addOnlyDivider(color: AppColor.auGreyBackground),
                itemBuilder: (BuildContext context, int index) {
                  final predefinedCollection = listPredefinedCollection[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: _item(context, predefinedCollection),
                  );
                },
                itemCount: listPredefinedCollection.length,
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

  const WorksSection({required this.works, super.key});

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

  @override
  Widget build(BuildContext context) {
    const padding = 15.0;
    final compactedAssetTokens = widget.works;

    return Padding(
      padding: const EdgeInsets.only(left: padding, right: padding),
      child: Column(
        children: [
          SectionHeader(title: 'works'.tr(), subTitle: ''),
          const SizedBox(height: 30),
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
                  separatorBuilder: (BuildContext context, int index) =>
                      addDivider(color: AppColor.auLightGrey)),
            ],
          ),
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
  late bool isDemo;

  Future<List<PlayListModel>?> getPlaylist({bool withDefault = false}) async {
    final isSubscribed = _configurationService.isPremium();
    if (!isSubscribed && !isDemo) {
      return null;
    }
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

  @override
  void initState() {
    _playlists = ValueNotifier(null);
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
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<PlayListModel>?>(
        valueListenable: _playlists,
        builder: (context, value, child) {
          if (value == null) {
            return const SizedBox.shrink();
          }

          final playlists = value.filter(widget.filterString);
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
        },
      );
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
