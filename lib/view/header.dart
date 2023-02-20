//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/cupertino.dart';

class HeaderView extends StatelessWidget {
  final double paddingTop;
  final bool isWhite;

  const HeaderView({Key? key, required this.paddingTop, this.isWhite = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.fromLTRB(0, paddingTop, 0, 40),
        child: Column(
          children: [
            headDivider(),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: isWhite ? autonomyWhiteLogo : autonomyLogo,
            ),
          ],
        ),
      ),
    );
  }
}
