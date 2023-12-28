//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/participate_user_test_page.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HelpUsPage extends StatefulWidget {
  const HelpUsPage({super.key});

  @override
  State<HelpUsPage> createState() => _HelpUsPageState();
}

class _HelpUsPageState extends State<HelpUsPage> {
  String? _calendarLink;

  @override
  void initState() {
    super.initState();
    unawaited(_getCalendarLink());
  }

  Future<void> _getCalendarLink() async {
    final data = await injector<PubdocAPI>().getUserTestConfigs();
    final configs = jsonDecode(data) as Map<String, dynamic>;
    setState(() {
      _calendarLink = configs['calendar_link'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return Scaffold(
      appBar: getBackAppBar(context, title: 'help_us_improve'.tr(), onBack: () {
        Navigator.of(context).pop();
      }),
      body: SafeArea(
        child: Column(
          children: [
            addTitleSpace(),
            Column(children: [
              Padding(
                padding: padding,
                child: TappableForwardRow(
                    leftWidget: Text('p_bug_bounty'.tr(),
                        style: theme.textTheme.ppMori400Black16),
                    onTap: () async => Navigator.of(context)
                        .pushNamed(AppRouter.bugBountyPage)),
              ),
              addOnlyDivider(),
              if (_calendarLink != null && _calendarLink!.isNotEmpty)
                Padding(
                  padding: padding,
                  child: TappableForwardRow(
                      leftWidget: Text('p_user_test'.tr(),
                          style: theme.textTheme.ppMori400Black16),
                      onTap: () async => Navigator.of(context).pushNamed(
                          AppRouter.participateUserTestPage,
                          arguments: UserTestPayload(_calendarLink!))),
                ),
            ]
                // END HELP US IMPROVE
                )
          ],
        ),
      ),
    );
  }
}
