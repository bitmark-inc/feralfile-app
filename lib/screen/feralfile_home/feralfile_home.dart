import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/artwork_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/featured_work_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home_state.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_exhibition_view.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:collection/collection.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum FeralfileHomeTab {
  featured,
  artworks,
  exhibitions,
  artists,
  curators,
  rAndD
}

class FeralfileHomePage extends StatefulWidget {
  const FeralfileHomePage({super.key});

  @override
  State<FeralfileHomePage> createState() => _FeralfileHomePageState();
}

class _FeralfileHomePageState extends State<FeralfileHomePage> {
  late List<Item> _items;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<FeralfileHomeBloc>().add(FeralFileHomeFetchDataEvent());
    _items = _getItemList(context.read<FeralfileHomeBloc>().state);
    _selectedIndex = FeralfileHomeTab.exhibitions.index;
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.top,
            ),
          ),
          // Header
          SliverToBoxAdapter(
            child: BlocBuilder<FeralfileHomeBloc, FeralfileHomeBlocState>(
              builder: (context, state) {
                return ItemExpanedWidget(
                  items: _getItemList(state),
                  selectedIndex: _selectedIndex,
                  iconOnExpanded: RotatedBox(
                    quarterTurns: 1,
                    child: icon,
                  ),
                  iconOnUnExpanded: RotatedBox(
                    quarterTurns: 2,
                    child: icon,
                  ),
                );
              },
            ),
          ),
          // body
          SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
          BlocBuilder<FeralfileHomeBloc, FeralfileHomeBlocState>(
            builder: (context, state) {
              return _bodyWidget(state);
            },
          )
        ],
      ),
    );
  }

  List<Item> _getItemList(FeralfileHomeBlocState state) {
    return [
      Item(
        id: FeralfileHomeTab.featured.index.toString(),
        title: 'Featured',
        subtitle: state.featuredArtworks?.length.toString() ?? '-',
        onSelected: () {
          setState(() {
            _selectedIndex = FeralfileHomeTab.featured.index;
          });
        },
      ),
      Item(
        id: FeralfileHomeTab.artworks.index.toString(),
        title: 'Artworks',
        subtitle: state.artworks?.paging.total.toString() ?? '-',
        onSelected: () {
          setState(() {
            _selectedIndex = FeralfileHomeTab.artworks.index;
          });
        },
      ),
      Item(
        id: FeralfileHomeTab.exhibitions.index.toString(),
        title: 'Exhibitions',
        subtitle: state.exhibitions?.length.toString() ?? '-',
        onSelected: () {
          setState(() {
            _selectedIndex = FeralfileHomeTab.exhibitions.index;
          });
        },
      ),
      Item(
          id: FeralfileHomeTab.artists.index.toString(),
          title: 'Artists',
          subtitle: state.artists?.paging.total.toString() ?? '-',
          onSelected: () {
            setState(() {
              _selectedIndex = FeralfileHomeTab.artists.index;
            });
          }),
      Item(
        id: FeralfileHomeTab.curators.index.toString(),
        title: 'Curators',
        subtitle: state.curators?.paging.total.toString() ?? '-',
        onSelected: () {
          setState(() {
            _selectedIndex = FeralfileHomeTab.curators.index;
          });
        },
      ),
      Item(
        id: FeralfileHomeTab.rAndD.index.toString(),
        title: 'R&D',
        subtitle: '2',
        onSelected: () {
          setState(() {
            _selectedIndex = FeralfileHomeTab.rAndD.index;
          });
        },
      ),
    ];
  }

  Widget _bodyWidget(FeralfileHomeBlocState state) {
    final tab = FeralfileHomeTab.values[_selectedIndex];
    switch (tab) {
      case FeralfileHomeTab.featured:
        return _featuredWidget(state.featuredArtworks ?? []);
      case FeralfileHomeTab.artworks:
        return _artworksWidget();
      case FeralfileHomeTab.exhibitions:
        return _exhibitionsWidget();
      case FeralfileHomeTab.artists:
        return _artistsWidget();
      case FeralfileHomeTab.curators:
        return _curatorsWidget();
      case FeralfileHomeTab.rAndD:
        return _rAndDWidget();
    }
  }

  Widget _featuredWidget(List<Artwork> featuredArtworks) {
    final tokenIDs =
        featuredArtworks.map((e) => e.indexerTokenId).whereNotNull().toList();
    return MultiBlocProvider(
        providers: [
          BlocProvider<IdentityBloc>(
            create: (context) => IdentityBloc(injector(), injector()),
          ),
        ],
        child: FeaauredWorkView(
          tokenIDs: tokenIDs,
        ));
  }

  Widget _artworksWidget() {
    final series =
        context.read<FeralfileHomeBloc>().state.artworks?.result ?? [];
    return SeriesView(series: series);
  }

  Widget _exhibitionsWidget() {
    final featured = context.read<FeralfileHomeBloc>().state.featuredArtworks;
    return FeaauredWorkView(
        tokenIDs:
            featured?.map((e) => e.indexerTokenId).whereNotNull().toList() ??
                []);
    final exhibitions =
        context.read<FeralfileHomeBloc>().state.exhibitions ?? [];
    return ListExhibitionView(exhibitions: exhibitions);
  }

  Widget _artistsWidget() {
    return Container(
      color: Colors.yellow,
      child: Center(
        child: Text('Artists'),
      ),
    );
  }

  Widget _curatorsWidget() {
    return Container(
      color: Colors.purple,
      child: Center(
        child: Text('Curators'),
      ),
    );
  }

  Widget _rAndDWidget() {
    return Container(
      color: Colors.orange,
      child: Center(
        child: Text('R&D'),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          behavior: HitTestBehavior.opaque,
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
  }

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
        _itemWidget(context, _selectedItem()),
        widget.iconOnUnExpanded ?? defaultIcon,
        const Spacer(),
        ...widget.actions,
      ],
    );
  }

  Item _selectedItem() {
    return widget.items[_selectedIndex];
  }

  Widget _itemWidget(BuildContext context, Item item) {
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
            Text(item.subtitle, style: subtitleStyle),
          ],
        ),
      ),
    );
  }
}
