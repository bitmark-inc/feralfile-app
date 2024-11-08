import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/feral_file_explore_helper.dart';
import 'package:autonomy_flutter/util/feralfile_alumni_ext.dart';
import 'package:autonomy_flutter/view/alumni_widget.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ExploreArtistView extends StatefulWidget {
  final String? searchText;
  final Map<FilterType, FilterValue> filters;
  final SortBy sortBy;

  const ExploreArtistView(
      {required this.filters,
      required this.sortBy,
      this.searchText,
      super.key});

  @override
  State<ExploreArtistView> createState() => ExploreArtistViewState();

  bool isEqual(Object other) =>
      other is ExploreArtistView &&
      other.searchText == searchText &&
      other.filters == filters &&
      other.sortBy == sortBy;
}

class ExploreArtistViewState extends State<ExploreArtistView> {
  List<AlumniAccount>? _artists;
  late Paging _paging;
  late ScrollController _scrollController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paging = Paging(offset: 0, limit: 18, total: 0);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels + 100 >
          _scrollController.position.maxScrollExtent) {
        unawaited(_loadMore());
      }
    });
    unawaited(_fetchArtists(context));
  }

  @override
  void didUpdateWidget(covariant ExploreArtistView oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_fetchArtists(context));
    scrollToTop();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    unawaited(_scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ));
  }

  Widget _loadingView(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 100),
        child: LoadingWidget(),
      );

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text('No artists found', style: theme.textTheme.ppMori400White14),
    );
  }

  Widget _artistView(BuildContext context, List<AlumniAccount> artists) =>
      ListAlumniView(
          listAlumni: artists,
          onAlumniSelected: (alumni) {
            unawaited(injector<NavigationService>()
                .openFeralFileArtistPage(alumni.slug ?? alumni.id));
          },
          scrollController: _scrollController,
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 100,
          ));

  @override
  Widget build(BuildContext context) {
    if (_artists == null) {
      return _loadingView(context);
    } else if (_artists!.isEmpty) {
      return _emptyView(context);
    } else {
      return _artistView(context, _artists!);
    }
  }

  Future<List<AlumniAccount>> _fetchArtists(BuildContext context) async {
    if (_isLoading) {
      return [];
    }
    _isLoading = true;

    final resp = await injector<FeralFileService>().getListAlumni(
      keywork: widget.searchText ?? '',
      isArtist: true,
      orderBy: widget.sortBy.queryParam,
      sortOrder: widget.sortBy.sortOrder.queryParam,
    );
    final artists = resp.result;
    final paging = resp.paging!;
    setState(() {
      _artists = artists;
      _paging = paging;
    });
    _isLoading = false;
    return artists;
  }

  Future<void> _loadMore() async {
    if (_isLoading) {
      return;
    }
    final canLoadMore = _paging.offset < _paging.total;
    if (!canLoadMore) {
      return;
    }
    _isLoading = true;
    final resp = await injector<FeralFileService>().getListAlumni(
      keywork: widget.searchText ?? '',
      isArtist: true,
      offset: _paging.offset + _paging.limit,
      limit: _paging.limit,
      orderBy: widget.sortBy.queryParam,
    );

    final artists = resp.result;
    final paging = resp.paging!;
    setState(() {
      _artists!.addAll(artists);
      _paging = paging;
    });
    _isLoading = false;
  }
}

class ExploreCuratorView extends StatefulWidget {
  final String? searchText;
  final Map<FilterType, FilterValue> filters;
  final SortBy sortBy;

  const ExploreCuratorView(
      {required this.filters,
      required this.sortBy,
      this.searchText,
      super.key});

  @override
  State<ExploreCuratorView> createState() => ExploreCuratorViewState();

  bool isEqual(Object other) =>
      other is ExploreCuratorView &&
      other.searchText == searchText &&
      other.filters == filters &&
      other.sortBy == sortBy;
}

class ExploreCuratorViewState extends State<ExploreCuratorView> {
  List<AlumniAccount>? _curators;
  late ScrollController _scrollController;
  late Paging _paging;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paging = Paging(offset: 0, limit: 18, total: 0);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels + 100 >
          _scrollController.position.maxScrollExtent) {
        unawaited(_loadMore());
      }
    });
    unawaited(_fetchCurators(context));
  }

  @override
  void didUpdateWidget(covariant ExploreCuratorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_fetchCurators(context));
    scrollToTop();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    unawaited(_scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ));
  }

  Widget _loadingView(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 100),
        child: LoadingWidget(),
      );

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text('no_curator_found', style: theme.textTheme.ppMori400White14),
    );
  }

  Widget _curatorView(BuildContext context, List<AlumniAccount> curators) =>
      ListAlumniView(
        listAlumni: curators,
        onAlumniSelected: (alumni) {
          unawaited(injector<NavigationService>()
              .openFeralFileCuratorPage(alumni.slug ?? alumni.id));
        },
        scrollController: _scrollController,
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 100,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_curators == null) {
      return _loadingView(context);
    } else if (_curators!.isEmpty) {
      return _emptyView(context);
    } else {
      return _curatorView(context, _curators!);
    }
  }

  Future<List<AlumniAccount>> _fetchCurators(BuildContext context) async {
    if (_isLoading) {
      return [];
    }
    _isLoading = true;
    final resp = await injector<FeralFileService>().getListAlumni(
      keywork: widget.searchText ?? '',
      isCurator: true,
      orderBy: widget.sortBy.queryParam,
      sortOrder: widget.sortBy.sortOrder.queryParam,
    );
    final ignoreCuratorAddresses =
        FeralFileExploreHelper.ignoreCuratorAddresses;
    final curators = resp.result;
    final paging = resp.paging!;
    setState(() {
      _curators = curators
          .where((curator) => !curator.addressesList
              .any((address) => ignoreCuratorAddresses.contains(address)))
          .toList();
      _paging = paging;
    });
    _isLoading = false;
    return curators;
  }

  Future<void> _loadMore() async {
    if (_isLoading) {
      return;
    }
    final canLoadMore = _paging.offset < _paging.total;
    if (!canLoadMore) {
      return;
    }
    _isLoading = true;
    final resp = await injector<FeralFileService>().getListAlumni(
      keywork: widget.searchText ?? '',
      isCurator: true,
      offset: _paging.offset + _paging.limit,
      limit: _paging.limit,
      orderBy: widget.sortBy.queryParam,
      sortOrder: widget.sortBy.sortOrder.queryParam,
    );

    final ignoreCuratorAddresses =
        FeralFileExploreHelper.ignoreCuratorAddresses;

    final curators = resp.result;
    final paging = resp.paging!;
    setState(() {
      _curators!.addAll(curators
          .where((curator) => !curator.addressesList
              .any((address) => ignoreCuratorAddresses.contains(address)))
          .toList());
      _paging = paging;
    });
    _isLoading = false;
  }
}

class ListAlumniView extends StatefulWidget {
  final List<AlumniAccount> listAlumni;
  final Function(AlumniAccount) onAlumniSelected;
  final ScrollController? scrollController;
  final EdgeInsets padding;

  const ListAlumniView(
      {required this.listAlumni,
      required this.onAlumniSelected,
      this.scrollController,
      this.padding = const EdgeInsets.all(0),
      super.key});

  @override
  State<ListAlumniView> createState() => _ListAlumniViewState();
}

class _ListAlumniViewState extends State<ListAlumniView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: widget.padding,
            sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 102.0 / 152,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 30,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final alumni = widget.listAlumni[index];
                    return GestureDetector(
                      onTap: () {
                        widget.onAlumniSelected(alumni);
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: _artistItem(context, alumni),
                      ),
                    );
                  },
                  childCount: widget.listAlumni.length,
                )),
          ),
        ],
      );

  Widget _artistAvatar(BuildContext context, AlumniAccount alumni) {
    final avatarUrl = alumni.avatarUrl;
    return AlumniAvatar(url: avatarUrl);
  }

  Widget _artistItem(BuildContext context, AlumniAccount alumni) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 1, child: _artistAvatar(context, alumni)),
        const SizedBox(height: 14),
        Expanded(
            child: Text(
          alumni.displayAlias,
          style: theme.textTheme.ppMori400White12,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )),
      ],
    );
  }
}
