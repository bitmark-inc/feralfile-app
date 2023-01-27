//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/editorial.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PublisherView extends StatelessWidget {
  final Publisher publisher;
  final bool isLargeSize;

  const PublisherView(
      {Key? key, required this.publisher, this.isLargeSize = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: CachedNetworkImage(
            fit: BoxFit.contain,
            imageUrl: publisher.icon,
            width: 18,
            height: 18,
          ),
        ),
        const SizedBox(width: 10.0),
        Text(
          publisher.name,
          style: isLargeSize
              ? Theme.of(context).textTheme.ppMori400Grey14
              : Theme.of(context).textTheme.ppMori400Grey12,
        ),
      ],
    );
  }
}
