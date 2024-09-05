import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/explore_statistics_data.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/artwork_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/explore_search_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/featured_work_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home_state.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_artist_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_exhibition_view.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/playlist_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/keep_alive_widget.dart';
import 'package:autonomy_flutter/view/stream_common_widget.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/models/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum FeralfileHomeTab {
  featured,
  artworks,
  exhibitions,
  artists,
  curators,
  rAndD;

  List<SortBy> getSortBy({bool isSearching = false}) {
    switch (this) {
      case FeralfileHomeTab.artworks:
        return [
          if (isSearching) SortBy.relevance,
          SortBy.createdAt,
          SortBy.title,
        ];
      case FeralfileHomeTab.exhibitions:
        return [
          if (isSearching) SortBy.relevance,
          SortBy.openAt,
          SortBy.title,
        ];
      case FeralfileHomeTab.artists:
      case FeralfileHomeTab.curators:
        return [
          if (isSearching) SortBy.relevance,
          SortBy.firstExhibitionJoinedAt,
          SortBy.alias,
        ];
      default:
        return [
          if (isSearching) SortBy.relevance,
          SortBy.createdAt,
          SortBy.title,
        ];
    }
  }

  SortBy getDefaultSortBy({bool isSearching = false}) =>
      getSortBy(isSearching: isSearching).first;

  Map<FilterType, List<FilterValue>> getFilterBy() {
    switch (this) {
      case FeralfileHomeTab.artworks:
        return {
          FilterType.type: [
            FilterValue.edition,
            FilterValue.series,
            FilterValue.oneofone,
          ],
          FilterType.chain: [
            FilterValue.ethereum,
            FilterValue.tezos,
            // dont support Bitmark chain
          ],
          FilterType.medium: [
            FilterValue.image,
            FilterValue.video,
            FilterValue.software,
            FilterValue.pdf,
            FilterValue.audio,
            FilterValue.threeD,
            FilterValue.animatedGif,
            FilterValue.text,
          ],
        };
      case FeralfileHomeTab.exhibitions:
        return {
          FilterType.type: [
            FilterValue.solo,
            FilterValue.group,
          ],
        };
      default:
        return {};
    }
  }
}

class FeralfileHomePage extends StatefulWidget {
  const FeralfileHomePage({super.key});

  @override
  State<FeralfileHomePage> createState() => FeralfileHomePageState();
}

class FeralfileHomePageState extends State<FeralfileHomePage>
    with AutomaticKeepAliveClientMixin {
  late int _selectedIndex;
  late CanvasDeviceBloc _canvasDeviceBloc;
  final _featuredWorkKey = GlobalKey<FeaturedWorkViewState>();
  final _artworkViewKey = GlobalKey<ExploreSeriesViewState>();
  final _exhibitionViewKey = GlobalKey<ExploreExhibitionState>();
  final _artistViewKey = GlobalKey<ExploreArtistViewState>();
  final _curatorViewKey = GlobalKey<ExploreCuratorViewState>();
  final GlobalKey<_ItemExpandedWidgetState> _itemExpandedKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
    context.read<FeralfileHomeBloc>().add(FeralFileHomeFetchDataEvent());
    _selectedIndex = FeralfileHomeTab.featured.index;
  }

  Widget _castButton(BuildContext context, List<Artwork> featuredArtworks) {
    final tokenIDs =
        featuredArtworks.map((e) => e.indexerTokenId).whereNotNull().toList();
    final displayKey = tokenIDs.displayKey ?? '';
    return FFCastButton(
      displayKey: displayKey,
      onDeviceSelected: (device) async {
        final duration = speedValues.values.first.inMilliseconds;
        final listPlayArtwork = tokenIDs
            .map((e) =>
                PlayArtworkV2(token: CastAssetToken(id: e), duration: duration))
            .toList();
        _canvasDeviceBloc
            .add(CanvasDeviceChangeControlDeviceEvent(device, listPlayArtwork));
      },
    );
  }

  void scrollToTop() {
    final tab = FeralfileHomeTab.values[_selectedIndex];
    switch (tab) {
      case FeralfileHomeTab.featured:
        _featuredWorkKey.currentState?.scrollToTop();
      case FeralfileHomeTab.artworks:
        _artworkViewKey.currentState?.scrollToTop();
      case FeralfileHomeTab.exhibitions:
        _exhibitionViewKey.currentState?.scrollToTop();
      case FeralfileHomeTab.artists:
        _artistViewKey.currentState?.scrollToTop();
      case FeralfileHomeTab.curators:
        _curatorViewKey.currentState?.scrollToTop();
      case FeralfileHomeTab.rAndD:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final icon = Icon(
      AuIcon.chevron_Sm,
      size: 18,
      color: Theme.of(context).colorScheme.secondary,
    );
    return Scaffold(
      appBar: getDarkEmptyAppBar(Colors.transparent),
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: AppColor.primaryBlack,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top + 32,
          ),
          // Header
          BlocBuilder<FeralfileHomeBloc, FeralfileHomeBlocState>(
            builder: (context, state) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ItemExpandedWidget(
                key: _itemExpandedKey,
                items: _getItemList(state),
                selectedIndex: _selectedIndex,
                iconOnExpanded: RotatedBox(
                  quarterTurns: 3,
                  child: icon,
                ),
                iconOnUnExpanded: RotatedBox(
                  quarterTurns: 1,
                  child: icon,
                ),
                actions: [
                  if (_selectedIndex == FeralfileHomeTab.featured.index &&
                      state.featuredArtworks != null &&
                      state.featuredArtworks!.isNotEmpty)
                    _castButton(context, state.featuredArtworks ?? []),
                ],
              ),
            ),
          ),
          // body
          const SizedBox(height: 16),
          BlocBuilder<FeralfileHomeBloc, FeralfileHomeBlocState>(
            builder: (context, state) => _bodyWidget(state),
          )
        ],
      ),
    );
  }

  void jumpToTab(FeralfileHomeTab tab) {
    setState(() {
      _selectedIndex = tab.index;
    });
    _itemExpandedKey.currentState?.selectItem(tab.index);
  }

  List<Item> _getItemList(FeralfileHomeBlocState state) {
    final numberFormater = NumberFormat('#,###', 'en_US');
    return [
      Item(
        id: FeralfileHomeTab.featured.index.toString(),
        title: 'featured'.tr(),
        subtitle: state.featuredArtworks != null
            ? numberFormater.format(state.featuredArtworks!.length)
            : '-',
        onSelected: () {
          jumpToTab(FeralfileHomeTab.featured);
        },
      ),
      Item(
        id: FeralfileHomeTab.artworks.index.toString(),
        title: '_artworks'.tr(),
        subtitle: state.exploreStatisticsData != null
            ? numberFormater.format(state.exploreStatisticsData!.totalArtwork)
            : '-',
        onSelected: () {
          jumpToTab(FeralfileHomeTab.artworks);
        },
      ),
      Item(
        id: FeralfileHomeTab.exhibitions.index.toString(),
        title: 'exhibitions'.tr(),
        subtitle: state.exploreStatisticsData != null
            ? numberFormater
                .format(state.exploreStatisticsData!.totalExhibition)
            : '-',
        onSelected: () {
          jumpToTab(FeralfileHomeTab.exhibitions);
        },
      ),
      Item(
          id: FeralfileHomeTab.artists.index.toString(),
          title: 'artists'.tr(),
          subtitle: state.exploreStatisticsData != null
              ? numberFormater.format(state.exploreStatisticsData!.totalArtist)
              : '-',
          onSelected: () {
            jumpToTab(FeralfileHomeTab.artists);
          }),
      Item(
        id: FeralfileHomeTab.curators.index.toString(),
        title: 'curators'.tr(),
        subtitle: state.exploreStatisticsData != null
            ? numberFormater.format(state.exploreStatisticsData!.totalCurator)
            : '-',
        onSelected: () {
          jumpToTab(FeralfileHomeTab.curators);
        },
      ),
    ];
  }

  Widget _bodyWidget(FeralfileHomeBlocState state) {
    final tab = FeralfileHomeTab.values[_selectedIndex];
    switch (tab) {
      case FeralfileHomeTab.featured:
        return KeepAliveWidget(
            child: _featuredWidget(context, state.featuredArtworks ?? []));
      case FeralfileHomeTab.artworks:
        return _artworksWidget(context);
      case FeralfileHomeTab.exhibitions:
        return _exhibitionsWidget(context);
      case FeralfileHomeTab.artists:
        return _artistsWidget(context);
      case FeralfileHomeTab.curators:
        return _curatorsWidget(context);
      case FeralfileHomeTab.rAndD:
        return _rAndDWidget(context);
    }
  }

  Widget _featuredWidget(BuildContext context, List<Artwork> featuredArtworks) {
    final tokenIDs =
        featuredArtworks.map((e) => e.indexerTokenId).whereNotNull().toList();
    return MultiBlocProvider(
      providers: [
        BlocProvider<IdentityBloc>(
          create: (context) => IdentityBloc(injector(), injector()),
        ),
      ],
      child: Expanded(
        child: FeaturedWorkView(
          key: _featuredWorkKey,
          tokenIDs: tokenIDs,
        ),
      ),
    );
  }

  Widget _artworksWidget(BuildContext context) => Expanded(
        child: ExploreBar(
          key: const ValueKey(FeralfileHomeTab.artworks),
          childBuilder: (searchText, filters, sortBy) => ExploreSeriesView(
            key: _artworkViewKey,
            searchText: searchText,
            filters: filters,
            sortBy: sortBy,
          ),
        ),
      );

  Widget _exhibitionsWidget(BuildContext context) => Expanded(
        child: ExploreBar(
          key: const ValueKey(FeralfileHomeTab.exhibitions),
          childBuilder: (searchText, filters, sortBy) => ExploreExhibition(
            key: _exhibitionViewKey,
            searchText: searchText,
            filters: filters,
            sortBy: sortBy,
          ),
          tab: FeralfileHomeTab.exhibitions,
        ),
      );

  Widget _artistsWidget(BuildContext context) => Expanded(
          child: ExploreBar(
        key: const ValueKey(FeralfileHomeTab.artists),
        childBuilder: (searchText, filters, sortBy) => ExploreArtistView(
          key: _artistViewKey,
          searchText: searchText,
          filters: filters,
          sortBy: sortBy,
        ),
        tab: FeralfileHomeTab.artists,
      ));

  Widget _curatorsWidget(BuildContext context) => Expanded(
          child: ExploreBar(
        key: const ValueKey(FeralfileHomeTab.curators),
        childBuilder: (searchText, filters, sortBy) => ExploreCuratorView(
          key: _curatorViewKey,
          searchText: searchText,
          filters: filters,
          sortBy: sortBy,
        ),
        tab: FeralfileHomeTab.curators,
      ));

  Widget _rAndDWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text('R&D coming soon', style: theme.textTheme.ppMori700White24),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class Item {
  String id;
  String title;
  String subtitle;
  Function onSelected;

  Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.onSelected,
  });
}

class ItemExpandedWidget extends StatefulWidget {
  final Widget? iconOnExpanded;
  final Widget? iconOnUnExpanded;
  final List<Item> items;
  final int selectedIndex;

  // actions on unexpanded
  final List<Widget> actions;

  const ItemExpandedWidget({
    required this.items,
    required this.selectedIndex,
    super.key,
    this.iconOnExpanded,
    this.iconOnUnExpanded,
    this.actions = const [],
  });

  @override
  State<ItemExpandedWidget> createState() => _ItemExpandedWidgetState();
}

class _ItemExpandedWidgetState extends State<ItemExpandedWidget> {
  bool _isExpanded = false;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void selectItem(int index) {
    setState(() {
      _selectedIndex = index;
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) => TapRegion(
        onTapOutside: (event) {
          setState(() {
            _isExpanded = false;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                color: Colors.transparent,
                child: _isExpanded ? _expandedHeader() : _unexpandedHeader(),
              ),
            ),
            // Expanded items
            if (_isExpanded) ...[
              for (var item in widget.items.skip(1)) _itemWidget(context, item),
            ]
          ],
        ),
      );

  Widget _expandedHeader() {
    final theme = Theme.of(context);
    final defaultIcon = Icon(
      AuIcon.chevron_Sm,
      size: 18,
      color: theme.colorScheme.secondary,
    );
    return Row(
      children: [
        _itemWidget(context, widget.items.first),
        const Spacer(),
        Column(
          children: [
            widget.iconOnExpanded ?? defaultIcon,
          ],
        )
      ],
    );
  }

  Widget _unexpandedHeader() {
    final theme = Theme.of(context);
    final defaultIcon = Icon(
      AuIcon.chevron_Sm,
      size: 18,
      color: theme.colorScheme.secondary,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IgnorePointer(
              child: _itemWidget(context, _selectedItem(), withSubtitle: false),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                widget.iconOnUnExpanded ?? defaultIcon,
              ],
            ),
          ],
        ),
        const Spacer(),
        ...widget.actions,
      ],
    );
  }

  Item _selectedItem() => widget.items[_selectedIndex];

  Widget _itemWidget(BuildContext context, Item item,
      {bool withSubtitle = true}) {
    final isSelected = item == _selectedItem();
    final theme = Theme.of(context);
    final defaultTitleStyle = theme.textTheme.ppMori700Black36
        .copyWith(color: AppColor.auGreyBackground);
    final selectedTitleStyle = theme.textTheme.ppMori700Black36.copyWith(
      color: AppColor.white,
    );
    final titleStyle = isSelected ? selectedTitleStyle : defaultTitleStyle;

    final defaultSubtitleStyle = theme.textTheme.ppMori400Black16
        .copyWith(color: AppColor.auGreyBackground);
    final selectedSubtitleStyle = theme.textTheme.ppMori400Black16.copyWith(
      color: AppColor.white,
    );
    final subtitleStyle =
        isSelected ? selectedSubtitleStyle : defaultSubtitleStyle;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = widget.items.indexOf(item);
          _isExpanded = false;
        });
        item.onSelected();
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: titleStyle,
            ),
            const SizedBox(width: 8),
            if (withSubtitle) Text(item.subtitle, style: subtitleStyle),
          ],
        ),
      ),
    );
  }
}
