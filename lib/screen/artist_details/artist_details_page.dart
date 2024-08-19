import 'dart:async';

import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/artist_details/artist_details_bloc.dart';
import 'package:autonomy_flutter/screen/artist_details/artist_details_state.dart';
import 'package:autonomy_flutter/screen/artist_details/artist_exhibitions_page.dart';
import 'package:autonomy_flutter/screen/artist_details/artist_posts_page.dart';
import 'package:autonomy_flutter/screen/artist_details/artist_works_page.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/feralfile_home/artwork_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_exhibition_view.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/url_hepler.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/loading_view.dart';
import 'package:autonomy_flutter/view/post_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

class UserDetailsPagePayload {
  final String userId;

  UserDetailsPagePayload({required this.userId});
}

class UserDetailsPage extends StatefulWidget {
  final UserDetailsPagePayload payload;

  const UserDetailsPage({required this.payload, super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<UserDetailsBloc>()
        .add(ArtistDetailsFetchArtistEvent(artistId: widget.payload.userId));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getFFAppBar(
          context,
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.black,
        body: BlocConsumer<UserDetailsBloc, UserDetailsState>(
            listener: (context, state) {},
            builder: (BuildContext context, UserDetailsState state) {
              final artist = state.artist;
              if (artist == null) {
                return _loading();
              }
              return _content(context, state);
            }),
      );

  Widget _loading() => Center(
        child: loadingView(context, size: 100),
      );

  Widget _avatar(BuildContext context, FFUser user) {
    final avatarUrl = user.avatarUrl;
    return avatarUrl != null
        ? Image.network(
            avatarUrl,
            fit: BoxFit.fill,
          )
        : SvgPicture.asset('assets/images/default_avatat.svg');
  }

  Widget _content(BuildContext context, UserDetailsState state) {
    final user = state.artist!;
    final series = state.series;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _userProfile(context, user),
        )),
        if ((series?.length ?? 0) > 0)
          ..._workSection(context, user, series ?? []),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 36,
          ),
        ),
        if ((state.exhibitions?.length ?? 0) > 0)
          ..._exhibitionSection(context, user, state.exhibitions ?? []),
        if ((state.posts?.length ?? 0) > 0)
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
            ),
          ),
        ..._postSection(context, user, state.posts ?? []),
      ],
    );
  }

  Widget _artistUrl(BuildContext context, String url, {String? title}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        unawaited(launchUrl(Uri.parse(url)));
      },
      child: Row(
        children: [
          Text(
            title ?? UrlHepler.shortenUrl(url),
            style: theme.textTheme.ppMori400White12
                .copyWith(color: AppColor.auQuickSilver),
          ),
          const SizedBox(
            width: 8,
          ),
          SvgPicture.asset(
            'assets/images/arrow_45.svg',
            width: 12,
            height: 12,
            colorFilter:
                const ColorFilter.mode(AppColor.auQuickSilver, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }

  String _userRole(FFUser user) {
    if (user.isArtist == true && user.isCurator == true) {
      return 'artist_curator'.tr();
    } else if (user.isArtist == true) {
      return 'artist'.tr();
    } else if (user.isCurator == true) {
      return 'curator'.tr();
    }
    return '';
  }

  Widget _userProfile(BuildContext context, FFUser user) {
    final theme = Theme.of(context);
    final subTitleStyle = theme.textTheme.ppMori400White12
        .copyWith(color: AppColor.auQuickSilver);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _avatar(context, user),
            ),
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          _userRole(user),
          style: subTitleStyle,
        ),
        const SizedBox(
          height: 36,
        ),
        Text(
          user.displayAlias,
          style: theme.textTheme.ppMori700White24.copyWith(fontSize: 36),
        ),
        const SizedBox(
          height: 24,
        ),
        if (user is FFUserDetails && user.location != null) ...[
          Text(
            user.location!,
            style: subTitleStyle.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
        ],
        if (user is FFUserDetails &&
            user.website != null &&
            user.website!.isNotEmpty) ...[
          _artistUrl(context, user.website!),
          const SizedBox(
            height: 12,
          ),
        ],
        if (user.instagramUrl != null && user.instagramUrl!.isNotEmpty) ...[
          _artistUrl(context, user.instagramUrl!, title: 'Instagram'),
          const SizedBox(
            height: 12,
          ),
        ],

        if (user.twitterUrl != null && user.twitterUrl!.isNotEmpty) ...[
          _artistUrl(context, user.twitterUrl!, title: 'Twitter'),
          const SizedBox(
            height: 12,
          ),
        ],
        const SizedBox(
          height: 32,
        ),
        if (user.bio != null) ...[
          ReadMoreText(
            text: user.bio!,
            style: theme.textTheme.ppMori400White14,
          ),
          const SizedBox(
            height: 16,
          ),
        ],
        // Add more widgets here
      ],
    );
  }

  Widget _header(BuildContext context,
      {required String title, String? subtitle}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.ppMori700White24.copyWith(fontSize: 36),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(
              width: 8,
            ),
            Text(
              subtitle,
              style: theme.textTheme.ppMori400White24
                  .copyWith(fontSize: 36, color: AppColor.auQuickSilver),
            ),
          ]
        ],
      ),
    );
  }

  void _gotoUserWork(BuildContext context, FFUserDetails user) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.artistWorksPage,
      arguments: ArtistWorksPagePayload(user),
    ));
  }

  List<Widget> _workSection(
      BuildContext context, FFUserDetails user, List<FFSeries> series) {
    final header =
        _header(context, title: 'works'.tr(), subtitle: '${series.length}');
    final viewAll = PrimaryAsyncButton(
      color: AppColor.white,
      onTap: () {
        _gotoUserWork(context, user);
      },
      text: 'view_all_works'.tr(),
    );
    const viewALlBreakpoint = 4;

    return [
      SliverToBoxAdapter(child: header),
      SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: SeriesView(
                series: series.length > viewALlBreakpoint
                    ? series.sublist(0, viewALlBreakpoint)
                    : series,
                isScrollable: false,
              ),
            ),
          ],
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(
          height: 36,
        ),
      ),
      SliverToBoxAdapter(
        child: series.length > viewALlBreakpoint
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: viewAll,
              )
            : const SizedBox(),
      ),
      const SliverToBoxAdapter(
          child: SizedBox(
        height: 40,
      ))
    ];
  }

  void _viewAllArtistExhibitions(BuildContext context, FFUserDetails user) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.artistExhibitionsPage,
      arguments: ArtistExhibitionsPagePayload(user),
    ));
  }

  List<Widget> _exhibitionSection(
      BuildContext context, FFUserDetails user, List<Exhibition> exhibitions) {
    final header = _header(context,
        title: 'exhibitions'.tr(), subtitle: '${exhibitions.length}');
    final viewAll = PrimaryAsyncButton(
      onTap: () {
        _viewAllArtistExhibitions(context, user);
      },
      color: AppColor.white,
      text: 'view_all_exhibitions'.tr(),
    );
    const viewALlBreakpoint = 2;
    return [
      SliverToBoxAdapter(child: header),
      SliverToBoxAdapter(
          child: Row(
        children: [
          Expanded(
            child: ListExhibitionView(
              exhibitions: exhibitions.length > viewALlBreakpoint
                  ? exhibitions.sublist(0, viewALlBreakpoint)
                  : exhibitions,
              isScrollable: false,
            ),
          ),
        ],
      )),
      const SliverToBoxAdapter(
        child: SizedBox(
          height: 36,
        ),
      ),
      SliverToBoxAdapter(
        child: exhibitions.length > viewALlBreakpoint
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: viewAll,
              )
            : const SizedBox(),
      )
    ];
  }

  void _viewAllArtistPosts(BuildContext context, FFUserDetails user) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.artistPostsPage,
      arguments: ArtistPostsPagePayload(user),
    ));
  }

  List<Widget> _postSection(
      BuildContext context, FFUserDetails user, List<Post> posts) {
    final header = _header(context,
        title: 'publications'.tr(), subtitle: '${posts.length}');
    final viewAll = PrimaryAsyncButton(
      onTap: () {
        _viewAllArtistPosts(context, user);
      },
      color: AppColor.white,
      text: 'view_all_posts'.tr(),
    );
    const viewALlBreakpoint = 2;

    return [
      SliverToBoxAdapter(child: header),
      SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: ListPostView(
                posts: posts.length > viewALlBreakpoint
                    ? posts.sublist(0, viewALlBreakpoint)
                    : posts,
                isScrollable: false,
              ),
            ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: posts.length > viewALlBreakpoint
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: viewAll,
              )
            : const SizedBox(),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(
          height: 36,
        ),
      ),
    ];
  }
}

class ListPostView extends StatefulWidget {
  final List<Post> posts;
  final bool isScrollable;

  const ListPostView(
      {required this.posts, super.key, this.isScrollable = true});

  @override
  State<ListPostView> createState() => _ListPostViewState();
}

class _ListPostViewState extends State<ListPostView> {
  @override
  Widget build(BuildContext context) {
    final divider =
        addDivider(height: 36, color: AppColor.auQuickSilver, thickness: 0.5);
    return CustomScrollView(
      shrinkWrap: true,
      physics: widget.isScrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      slivers: [
        SliverList(
            delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = widget.posts[index];
            return Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _postItem(context, post),
                  ),
                ),
                divider,
              ],
            );
          },
          childCount: widget.posts.length,
        ))
      ],
    );
  }

  Widget _postItem(BuildContext context, Post post) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMMM y');
    final dateTime = post.dateTime ?? post.createdAt;
    final defaultStyle = theme.textTheme.ppMori400White12
        .copyWith(color: AppColor.auQuickSilver);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.dateTime != null)
          Text(
            dateFormat.format(dateTime),
            style: defaultStyle,
          ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  if (post.coverURI != null)
                    PostThumbnail(
                      post: post,
                    )
                  else
                    SvgPicture.asset('assets/images/default_avatat.svg'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Text(
              post.type.capitalize(),
              style: defaultStyle,
            ),
            const SizedBox(width: 24),
            if (post.exhibition != null)
              GestureDetector(
                onTap: () {
                  _gotoExhibition(context, post.exhibition!);
                },
                child: Text(
                  post.exhibition!.title,
                  style: defaultStyle.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
          ],
        ),
        const SizedBox(height: 36),
        Text(
          post.title,
          style: theme.textTheme.ppMori400White24,
        ),
        if (post.author != null && post.author!.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            post.author ?? 'Author Name',
            style: defaultStyle,
          ),
        ],
      ],
    );
  }

  void _gotoExhibition(BuildContext context, Exhibition exhibition) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.exhibitionDetailPage,
      arguments: ExhibitionDetailPayload(exhibitions: [exhibition], index: 0),
    ));
  }
}

class ReadMoreText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle style;

  const ReadMoreText(
      {required this.text, required this.style, this.maxLines = 3, super.key});

  @override
  State<ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<ReadMoreText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Column(
          children: [
            HtmlWidget(
              widget.text,
              customStylesBuilder: auHtmlStyle,
              textStyle: widget.style,
            ),
            // if (!_isExpanded) ...[
            //   const SizedBox(
            //     height: 16,
            //   ),
            //   Text(
            //     'read_more'.tr(),
            //     style: widget.style.copyWith(
            //       color: AppColor.auQuickSilver,
            //     ),
            //   ),
            // ]
          ],
        ),
      );
}
