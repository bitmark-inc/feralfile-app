//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/editorial.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/editorial/common/bottom_link.dart';
import 'package:autonomy_flutter/screen/editorial/common/publisher_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ArticleView extends StatelessWidget {
  final EditorialPost post;

  const ArticleView({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PublisherView(publisher: post.publisher),
          const SizedBox(height: 10.0),
          Text(
            post.content["title"],
            style: theme.textTheme.ppMori400White16,
            maxLines: 2,
          ),
          const SizedBox(height: 15.0),
          Row(
            children: [
              Expanded(
                child: IntrinsicHeight(
                  child: CachedNetworkImage(
                    fit: BoxFit.contain,
                    imageUrl: post.content["thumbnail_url"],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 15.0),
          Text(
            post.content["description"],
            style: theme.textTheme.ppMori400White14,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20.0),
          BottomLink(name: "read_more".tr(), tag: post.tag ?? ""),
        ],
      ),
      onTap: () => Navigator.of(context)
          .pushNamed(AppRouter.articleDetailPage, arguments: post),
    );
  }
}
