//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/models/asset_token.dart';

class AnyProblemNFTWidget extends StatelessWidget {
  final AssetToken asset;

  const AnyProblemNFTWidget({Key? key, required this.asset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => showReportIssueDialog(context, asset),
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
        color: theme.auSuperTeal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "problem_nft".tr(),
              style: theme.textTheme.button,
            ),
            const SizedBox(
              width: 4,
            ),
            SvgPicture.asset(
              "assets/images/iconSharpFeedback.svg",
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
