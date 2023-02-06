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
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/badge_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
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
  bool isCustomerSupportAvailable = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomerSupportAvailability();
    injector<CustomerSupportService>().getIssues();
  }

  Future<void> fetchAnnouncements() async {
    await injector<CustomerSupportService>().fetchAnnouncement();
    await injector<CustomerSupportService>().getIssuesAndAnnouncement();
  }

  _fetchCustomerSupportAvailability() async {
    final device = DeviceInfo.instance;
    final isAvailable = await device.isSupportOS();
    setState(() {
      isCustomerSupportAvailable = isAvailable;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    injector<CustomerSupportService>().getIssuesAndAnnouncement();
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
      appBar: getBackAppBar(
        context,
        title: "how_can_we_help".tr(),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isCustomerSupportAvailable
                ? addTitleSpace()
                : Padding(
                    padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColor.auSuperTeal,
                            borderRadius: BorderRadiusGeometry.lerp(
                                const BorderRadius.all(Radius.circular(5)),
                                const BorderRadius.all(Radius.circular(5)),
                                5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'important'.tr(),
                                  style: theme.textTheme.ppMori700Black14,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  'inform_remove_cs'.tr(),
                                  style: theme.textTheme.ppMori400Black14,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _reportItemsWidget(context),
            ),
            const SizedBox(height: 30),
            _resourcesWidget(context),
          ],
        ),
      ),
    );
  }

  Widget _reportItemsWidget(BuildContext context) {
    return Column(
      children: [
        ...ReportIssueType.getSuggestList.map((item) {
          return Column(
            children: [
              AuSecondaryButton(
                text: ReportIssueType.toTitle(item),
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRouter.supportThreadPage,
                  arguments: NewIssuePayload(reportIssueType: item),
                ),
                backgroundColor: Colors.white,
                borderColor: Colors.black,
                textColor: Colors.black,
              ),
              const SizedBox(height: 10),
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
              addOnlyDivider(),
              TappableForwardRow(
                leftWidget: Row(
                  children: [
                    Text('support_history'.tr(),
                        style: theme.textTheme.ppMori400Black14),
                    if (numberOfIssuesInfo[1] > 0) ...[
                      const SizedBox(
                        width: 7,
                      ),
                      redDotIcon(),
                    ]
                  ],
                ),
                rightWidget: numberOfIssuesInfo[1] > 0
                    ? BadgeView(number: numberOfIssuesInfo[1])
                    : null,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.supportListPage),
                padding: ResponsiveLayout.tappableForwardRowEdgeInsets,
              ),
              addOnlyDivider(),
            ],
          );
        });
  }
}
