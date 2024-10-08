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
import 'package:autonomy_flutter/screen/feralfile_home/artwork_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_exhibition_view.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_post_view.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/url_hepler.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/user_widget.dart';
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

  Widget _loading() => const Center(
        child: LoadingWidget(),
      );

  Widget _avatar(BuildContext context, FFUser user) {
    final avatarUrl = user.avatarUrl;
    return AspectRatio(
      aspectRatio: 1,
      child: UserAvatar(url: avatarUrl),
    );
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
        if ((state.exhibitions?.length ?? 0) > 0) ...[
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
            ),
          ),
          ..._exhibitionSection(context, user, state.exhibitions ?? []),
        ],
        if ((state.posts?.length ?? 0) > 0) ...[
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
            ),
          ),
          ..._postSection(context, user, state.posts ?? []),
        ],
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
        if (user.alumniAccount?.location != null) ...[
          Text(
            user.alumniAccount!.location!,
            style: subTitleStyle.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
        ],
        if (user.alumniAccount?.website != null &&
            user.alumniAccount!.website!.isNotEmpty) ...[
          _artistUrl(context, user.alumniAccount!.website!),
          const SizedBox(
            height: 12,
          ),
        ],
        if (user.instagramUrl != null && user.instagramUrl!.isNotEmpty) ...[
          _artistUrl(context, user.instagramUrl!, title: 'instagram'.tr()),
          const SizedBox(
            height: 12,
          ),
        ],

        if (user.twitterUrl != null && user.twitterUrl!.isNotEmpty) ...[
          _artistUrl(context, user.twitterUrl!, title: 'twitter'.tr()),
          const SizedBox(
            height: 12,
          ),
        ],
        const SizedBox(
          height: 32,
        ),
        if (user.alumniAccount?.bio != null) ...[
          ReadMoreText(
            text: user.alumniAccount!.bio!,
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

  void _gotoUserWork(BuildContext context, FFUser user) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.artistWorksPage,
      arguments: ArtistWorksPagePayload(user),
    ));
  }

  List<Widget> _workSection(
      BuildContext context, FFUser user, List<FFSeries> series) {
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

  void _viewAllArtistExhibitions(BuildContext context, FFUser user) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.artistExhibitionsPage,
      arguments: ArtistExhibitionsPagePayload(user),
    ));
  }

  List<Widget> _exhibitionSection(
      BuildContext context, FFUser user, List<Exhibition> exhibitions) {
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
          child: addDivider(
              height: 36, color: AppColor.auQuickSilver, thickness: 0.5)),
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
      SliverToBoxAdapter(
          child: addDivider(
              height: 36, color: AppColor.auQuickSilver, thickness: 0.5)),
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

  void _viewAllArtistPosts(BuildContext context, FFUser user) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.artistPostsPage,
      arguments: ArtistPostsPagePayload(user),
    ));
  }

  List<Widget> _postSection(
      BuildContext context, FFUser user, List<Post> posts) {
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
          child: addDivider(
              height: 36, color: AppColor.auQuickSilver, thickness: 0.5)),
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
        child: addDivider(
            height: 36, color: AppColor.auQuickSilver, thickness: 0.5),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(
          height: 36,
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
              onTapUrl: (url) async {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
                return true;
              },
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
