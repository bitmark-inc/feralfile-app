import 'dart:async';

import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/post_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ListPostView extends StatefulWidget {
  final List<Post> posts;
  final bool isScrollable;
  final EdgeInsets padding;

  const ListPostView(
      {required this.posts,
      super.key,
      this.isScrollable = true,
      this.padding = const EdgeInsets.all(0)});

  @override
  State<ListPostView> createState() => _ListPostViewState();
}

class _ListPostViewState extends State<ListPostView> {
  @override
  Widget build(BuildContext context) {
    final divider =
        addDivider(height: 36, color: AppColor.auQuickSilver, thickness: 0.5);
    return Padding(
      padding: widget.padding,
      child: CustomScrollView(
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
                  if (index != widget.posts.length - 1) divider,
                ],
              );
            },
            childCount: widget.posts.length,
          )),
        ],
      ),
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
                    AspectRatio(
                      aspectRatio: 1,
                      child: SvgPicture.asset(
                        'assets/images/default_avatat.svg',
                        fit: BoxFit.fitWidth,
                      ),
                    ),
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
