//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/customer_support/tutorial_videos_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/badge_view.dart';
import 'package:autonomy_flutter/view/important_note_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SupportCustomerPage extends StatefulWidget {
  const SupportCustomerPage({super.key});

  @override
  State<SupportCustomerPage> createState() => _SupportCustomerPageState();
}

class _SupportCustomerPageState extends State<SupportCustomerPage>
    with RouteAware, WidgetsBindingObserver {
  bool isCustomerSupportAvailable = true;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchCustomerSupportAvailability());
    unawaited(injector<CustomerSupportService>().getIssues());
    unawaited(fetchAnnouncements());
  }

  Future<void> fetchAnnouncements() async {
    await injector<CustomerSupportService>().fetchAnnouncement();
    await injector<CustomerSupportService>().getIssuesAndAnnouncement();
  }

  Future<void> _fetchCustomerSupportAvailability() async {
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
    unawaited(injector<CustomerSupportService>().getIssuesAndAnnouncement());
    super.didPopNext();
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    final orderIds = injector<ConfigurationService>().getMerchandiseOrderIds();
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: 'how_can_we_help'.tr(),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCustomerSupportAvailable)
              addTitleSpace()
            else
              Padding(
                padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    ImportantNoteView(note: 'inform_remove_cs'.tr()),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _reportItemsWidget(),
            ),
            const SizedBox(height: 30),
            addOnlyDivider(),
            _resourcesWidget(),
            _transactionHistoryTap(context, orderIds),
            _videoTutorials(),
          ],
        ),
      ),
    );
  }

  Widget _reportItemsWidget() => Column(
        children: [
          ...ReportIssueType.getSuggestList.map((item) => Column(
                children: [
                  AuSecondaryButton(
                    text: ReportIssueType.toTitle(item),
                    onPressed: () async {
                      if (isCustomerSupportAvailable) {
                        await Navigator.of(context).pushNamed(
                          AppRouter.supportThreadPage,
                          arguments: NewIssuePayload(reportIssueType: item),
                        );
                      }
                    },
                    backgroundColor: Colors.white,
                    borderColor: isCustomerSupportAvailable
                        ? AppColor.primaryBlack
                        : AppColor.auGrey,
                    textColor: isCustomerSupportAvailable
                        ? AppColor.primaryBlack
                        : AppColor.auGrey,
                  ),
                  const SizedBox(height: 10),
                ],
              ))
        ],
      );

  Widget _resourcesWidget() {
    final theme = Theme.of(context);

    return ValueListenableBuilder<List<int>?>(
        valueListenable: injector<CustomerSupportService>().numberOfIssuesInfo,
        builder: (BuildContext context, List<int>? numberOfIssuesInfo,
            Widget? child) {
          if (numberOfIssuesInfo == null) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (numberOfIssuesInfo[0] == 0) {
            return const SizedBox();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                onTap: () async {
                  await Navigator.of(context)
                      .pushNamed(AppRouter.supportListPage);
                },
                padding: ResponsiveLayout.tappableForwardRowEdgeInsets,
              ),
              addOnlyDivider(),
            ],
          );
        });
  }

  Widget _transactionHistoryTap(BuildContext context, List<String> orderIds) {
    final theme = Theme.of(context);
    if (orderIds.isEmpty) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TappableForwardRow(
          leftWidget: Text('transaction_history'.tr(),
              style: theme.textTheme.ppMori400Black14),
          rightWidget: BadgeView(number: orderIds.length),
          onTap: () async {
            await Navigator.of(context).pushNamed(AppRouter.merchOrdersPage);
          },
          padding: ResponsiveLayout.tappableForwardRowEdgeInsets,
        ),
        addOnlyDivider(),
      ],
    );
  }

  Widget _videoTutorials() {
    final theme = Theme.of(context);
    return FutureBuilder<List<VideoData>>(
        // ignore: discarded_futures
        future: injector<PubdocAPI>().getTutorialVideosFromGithub(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TappableForwardRow(
                  leftWidget: Text('tutorial_videos'.tr(),
                      style: theme.textTheme.ppMori400Black14),
                  onTap: () async {
                    await Navigator.of(context).pushNamed(TutorialVideo.tag,
                        arguments:
                            TutorialVideosPayload(videos: snapshot.data!));
                  },
                  padding: ResponsiveLayout.tappableForwardRowEdgeInsets,
                ),
                addOnlyDivider(),
              ],
            );
          } else {
            return const SizedBox();
          }
        });
  }
}
