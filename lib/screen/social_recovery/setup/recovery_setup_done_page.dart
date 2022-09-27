//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RecoverySetupDonePage extends StatelessWidget {
  const RecoverySetupDonePage({Key? key}) : super(key: key);

  final _name = "John Smith";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getTrailingCloseAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recovery network active!",
                      style: theme.textTheme.headline2,
                    ),
                    const SizedBox(height: 60),
                    Text(
                      "You are now protected by collaborative recovery: \n\n 1. Apple (platform collaborator)\n 2. Feral File (institional collaborator)\n 3. $_name (personal collaborator)\n\nIf you ever lose access to your device, install Autonomy on a new device then tap the “Restore” button on the start screen. ",
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child:
                          SvgPicture.asset("assets/images/setup_recovery.svg"),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "DONE".toUpperCase(),
                    onPress: () {
                      injector<NavigationService>().popUntilHomeOrSettings();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
