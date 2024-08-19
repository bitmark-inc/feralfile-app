import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/artwork_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/explore_search_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/featured_work_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home_state.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_artist_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_exhibition_view.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/playlist_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:collection/collection.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<FeralfileHomeBloc>().add(FeralFileHomeFetchDataEvent());
    _selectedIndex = FeralfileHomeTab.featured.index;
  }

  Widget _castButton(List<Artwork> featuredArtworks) {
    final tokenIDs =
        featuredArtworks.map((e) => e.indexerTokenId).whereNotNull().toList();
    final displayKey = tokenIDs.displayKey ?? '';
    return FFCastButton(
      displayKey: displayKey,
      onDeviceSelected: (device) async {
        // TODO: implement cast
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      AuIcon.chevron_Sm,
      size: 18,
      color: Theme.of(context).colorScheme.secondary,
    );
    return Scaffold(
      appBar: getDarkEmptyAppBar(),
      backgroundColor: AppColor.primaryBlack,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          // Header
          BlocBuilder<FeralfileHomeBloc, FeralfileHomeBlocState>(
            builder: (context, state) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ItemExpanedWidget(
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

  List<Item> _getItemList(FeralfileHomeBlocState state) {
    final numberFormater = NumberFormat('#,###', 'en_US');
    return [
      Item(
        id: FeralfileHomeTab.featured.index.toString(),
        title: 'Featured',
        subtitle: state.featuredArtworks != null
            ? numberFormater.format(state.featuredArtworks!.length)
            : '-',
        onSelected: () {
          setState(() {
            _selectedIndex = FeralfileHomeTab.featured.index;
          });
        },
      ),
      Item(
        id: FeralfileHomeTab.artworks.index.toString(),
        title: 'Artworks',
        subtitle: state.exploreStatisticsData != null
            ? numberFormater.format(state.exploreStatisticsData!.totalArtwork)
            : '-',
        onSelected: () {
          setState(() {
            _selectedIndex = FeralfileHomeTab.artworks.index;
          });
        },
      ),
      Item(
        id: FeralfileHomeTab.exhibitions.index.toString(),
        title: 'Exhibitions',
        subtitle: state.exploreStatisticsData != null
            ? numberFormater
                .format(state.exploreStatisticsData!.totalExhibition)
            : '-',
        onSelected: () {
          setState(() {
            _selectedIndex = FeralfileHomeTab.exhibitions.index;
          });
        },
      ),
      Item(
          id: FeralfileHomeTab.artists.index.toString(),
          title: 'Artists',
          subtitle: state.exploreStatisticsData != null
              ? numberFormater.format(state.exploreStatisticsData!.totalArtist)
              : '-',
          onSelected: () {
            setState(() {
              _selectedIndex = FeralfileHomeTab.artists.index;
            });
          }),
      Item(
        id: FeralfileHomeTab.curators.index.toString(),
        title: 'Curators',
        subtitle: state.exploreStatisticsData != null
            ? numberFormater.format(state.exploreStatisticsData!.totalCurator)
            : '-',
        onSelected: () {
          setState(() {
            _selectedIndex = FeralfileHomeTab.curators.index;
          });
        },
      ),
      // Item(
      //   id: FeralfileHomeTab.rAndD.index.toString(),
      //   title: 'R&D',
      //   subtitle: '2',
      //   onSelected: () {
      //     setState(() {
      //       _selectedIndex = FeralfileHomeTab.rAndD.index;
      //     });
      //   },
      // ),
    ];
  }

  Widget _bodyWidget(FeralfileHomeBlocState state) {
    final tab = FeralfileHomeTab.values[_selectedIndex];
    switch (tab) {
      case FeralfileHomeTab.featured:
        return _featuredWidget(context, state.featuredArtworks ?? []);
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
          child: FeaauredWorkView(
            tokenIDs: tokenIDs,
          ),
        ));
  }

  Widget _artworksWidget(BuildContext context) => Expanded(
        child: ExploreBar(
          key: const ValueKey(FeralfileHomeTab.artworks),
          childBuilder: (searchText, filters, sortBy) => ExploreSeriesView(
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

class ItemExpanedWidget extends StatefulWidget {
  final Widget? iconOnExpanded;
  final Widget? iconOnUnExpanded;
  final List<Item> items;
  final int selectedIndex;

  // actions on unexpanded
  final List<Widget> actions;

  const ItemExpanedWidget({
    required this.items,
    required this.selectedIndex,
    super.key,
    this.iconOnExpanded,
    this.iconOnUnExpanded,
    this.actions = const [],
  });

  @override
  State<ItemExpanedWidget> createState() => _ItemExpanedWidgetState();
}

class _ItemExpanedWidgetState extends State<ItemExpanedWidget> {
  bool _isExpanded = false;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) => Column(
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
        widget.iconOnExpanded ?? defaultIcon,
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
      children: [
        IgnorePointer(
          child: _itemWidget(context, _selectedItem(), withSubtitle: false),
        ),
        const SizedBox(width: 8),
        widget.iconOnUnExpanded ?? defaultIcon,
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
