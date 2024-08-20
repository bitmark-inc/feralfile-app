import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/artist_details/artist_details_page.dart';
import 'package:autonomy_flutter/screen/feralfile_home/filter_bar.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/feral_file_explore_helper.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  List<FFUser>? _artists;
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
    if (!oldWidget.isEqual(widget) || true) {
      unawaited(_fetchArtists(context));
    }
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

  Widget _artistView(BuildContext context, List<FFUser> artists) =>
      ListUserView(
          users: artists,
          onUserSelected: (user) {
            if (user is FFUserDetails) {
              _gotoArtistDetails(context, user.toFFArtist());
            }
          },
          scrollController: _scrollController,
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 100,
          ));

  void _gotoArtistDetails(BuildContext context, FFArtist artist) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.userDetailsPage,
      arguments: UserDetailsPagePayload(userId: artist.slug ?? artist.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_artists == null) {
      return _loadingView(context);
    } else if (_artists!.isEmpty) {
      return _emptyView(context);
    } else {
      return Expanded(child: _artistView(context, _artists!));
    }
  }

  Future<List<FFArtist>> _fetchArtists(BuildContext context) async {
    if (_isLoading) {
      return [];
    }
    _isLoading = true;

    final resp = await injector<FeralFileService>().exploreArtists(
      keywork: widget.searchText ?? '',
      orderBy: widget.sortBy.queryParam,
      sortOrder: widget.sortBy.sortOrder.queryParam,
    );
    final artists = resp.result;
    final paging = resp.paging;
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
    final resp = await injector<FeralFileService>().exploreArtists(
      keywork: widget.searchText ?? '',
      offset: _paging.offset + _paging.limit,
      limit: _paging.limit,
      orderBy: widget.sortBy.queryParam,
    );

    final artists = resp.result;
    final paging = resp.paging;
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
  List<FFUser>? _curators;
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
    if (!oldWidget.isEqual(widget) || true) {
      unawaited(_fetchCurators(context));
    }
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
      child: Text('No curators found', style: theme.textTheme.ppMori400White14),
    );
  }

  Widget _curatorView(BuildContext context, List<FFUser> curators) =>
      ListUserView(
        users: curators,
        onUserSelected: (user) {
          if (user is FFUserDetails) {
            _gotoCuratorDetails(context, user.toFFCurator());
          }
        },
        scrollController: _scrollController,
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 100,
        ),
      );

  void _gotoCuratorDetails(BuildContext context, FFCurator curator) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.userDetailsPage,
      arguments: UserDetailsPagePayload(userId: curator.slug ?? curator.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_curators == null) {
      return _loadingView(context);
    } else if (_curators!.isEmpty) {
      return _emptyView(context);
    } else {
      return Expanded(child: _curatorView(context, _curators!));
    }
  }

  Future<List<FFCurator>> _fetchCurators(BuildContext context) async {
    if (_isLoading) {
      return [];
    }
    _isLoading = true;
    final resp = await injector<FeralFileService>().exploreCurators(
      keywork: widget.searchText ?? '',
      orderBy: widget.sortBy.queryParam,
      sortOrder: widget.sortBy.sortOrder.queryParam,
    );
    final ignoreCuratorIds = FeralFileExploreHelper.ignoreCuratorIds;
    final curators = resp.result;
    final paging = resp.paging;
    setState(() {
      _curators = curators
          .where((curator) => !ignoreCuratorIds.contains(curator.id))
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
    final resp = await injector<FeralFileService>().exploreCurators(
      keywork: widget.searchText ?? '',
      offset: _paging.offset + _paging.limit,
      limit: _paging.limit,
      orderBy: widget.sortBy.queryParam,
      sortOrder: widget.sortBy.sortOrder.queryParam,
    );

    final ignoreCuratorIds = FeralFileExploreHelper.ignoreCuratorIds;

    final curators = resp.result;
    final paging = resp.paging;
    setState(() {
      _curators!.addAll(curators
          .where((curator) => !ignoreCuratorIds.contains(curator.id))
          .toList());
      _paging = paging;
    });
    _isLoading = false;
  }
}

class ListUserView extends StatefulWidget {
  final List<FFUser> users;
  final Function(FFUser) onUserSelected;
  final ScrollController? scrollController;
  final EdgeInsets padding;

  const ListUserView(
      {required this.users,
      required this.onUserSelected,
      this.scrollController,
      this.padding = const EdgeInsets.all(0),
      super.key});

  @override
  State<ListUserView> createState() => _ListUserViewState();
}

class _ListUserViewState extends State<ListUserView> {
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
                    final user = widget.users[index];
                    return GestureDetector(
                      onTap: () {
                        widget.onUserSelected(user);
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: _artistItem(context, user),
                      ),
                    );
                  },
                  childCount: widget.users.length,
                )),
          ),
        ],
      );

  Widget _artistAvatar(BuildContext context, FFUser user) {
    final avatarUrl = user.avatarUrl;
    return avatarUrl != null
        ? Image.network(
            avatarUrl,
            fit: BoxFit.fitWidth,
          )
        : SvgPicture.asset(
            'assets/images/default_avatat.svg',
            fit: BoxFit.fitWidth,
          );
  }

  Widget _artistItem(BuildContext context, FFUser user) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1.0, child: _artistAvatar(context, user))),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayAlias,
                  style: theme.textTheme.ppMori400White12,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }
}
