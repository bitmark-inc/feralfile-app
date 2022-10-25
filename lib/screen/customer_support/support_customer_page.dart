//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/badge_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SupportCustomerPage extends StatefulWidget {
  const SupportCustomerPage({Key? key}) : super(key: key);

  @override
  State<SupportCustomerPage> createState() => _SupportCustomerPageState();
}

class _SupportCustomerPageState extends State<SupportCustomerPage>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    injector<CustomerSupportService>().getIssues();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    injector<CustomerSupportService>().getIssues();
    super.didPopNext();
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getCloseAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "how_can_we_help".tr(),
                style: theme.textTheme.headline1,
              ),
              addTitleSpace(),
              _reportItemsWidget(context),
              _resourcesWidget(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportItemsWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ...ReportIssueType.getSuggestList.map((item) {
          return Column(
            children: [
              TappableForwardRow(
                leftWidget: Text(ReportIssueType.toTitle(item),
                    style: theme.textTheme.headline4),
                onTap: () => Navigator.of(context).pushNamed(
                    AppRouter.supportThreadPage,
                    arguments: NewIssuePayload(reportIssueType: item)),
              ),
              addOnlyDivider(),
            ],
          );
        })
      ],
    );
  }

  Widget _resourcesWidget(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<List<int>?>(
        valueListenable: injector<CustomerSupportService>().numberOfIssuesInfo,
        builder: (BuildContext context, List<int>? numberOfIssuesInfo,
            Widget? child) {
          if (numberOfIssuesInfo == null) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (numberOfIssuesInfo[0] == 0) return const SizedBox();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TappableForwardRow(
                  leftWidget: Text('support_history'.tr(),
                      style: theme.textTheme.headline4),
                  rightWidget: numberOfIssuesInfo[1] > 0
                      ? BadgeView(number: numberOfIssuesInfo[1])
                      : null,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRouter.supportListPage)),
              const SizedBox(
                height: 18,
              )
            ],
          );
        });
  }
}
