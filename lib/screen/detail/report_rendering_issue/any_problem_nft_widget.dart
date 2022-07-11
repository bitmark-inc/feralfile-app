//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnyProblemNFTWidget extends StatelessWidget {
  final AssetToken asset;
  final ThemeData theme;

  const AnyProblemNFTWidget(
      {Key? key, required this.asset, required this.theme})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showReportIssueDialog(context, asset),
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.fromLTRB(0, 18, 0, 24),
        color: theme.backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ANY PROBLEMS WITH THIS NFT?',
                style: theme.textTheme.bodyText1),
            SizedBox(
              width: 4,
            ),
            SvgPicture.asset("assets/images/iconSharpFeedback.svg",
                color: theme.textTheme.bodyText1?.color),
          ],
        ),
      ),
    );
  }
}
