//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/rand.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SupportListPage extends StatefulWidget {
  const SupportListPage({Key? key}) : super(key: key);

  @override
  State<SupportListPage> createState() => _SupportListPageState();
}

class _SupportListPageState extends State<SupportListPage>
    with RouteAware, WidgetsBindingObserver {
  List<Issue>? _issues;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    loadIssues();
    injector<CustomerSupportService>()
        .triggerReloadMessages
        .addListener(loadIssues);
  }

  @override
  void didPopNext() {
    loadIssues();
    super.didPopNext();
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    injector<CustomerSupportService>()
        .triggerReloadMessages
        .removeListener(loadIssues);
  }

  void loadIssues() async {
    final issues = await injector<CustomerSupportService>().getIssues();
    issues.sort((a, b) =>
        (b.draft?.createdAt ?? b.lastMessage?.timestamp ?? b.timestamp)
            .compareTo(
                a.draft?.createdAt ?? a.lastMessage?.timestamp ?? a.timestamp));
    if (mounted) {
      setState(() {
        _issues = issues;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: _issuesWidget(),
    );
  }

  Widget _issuesWidget() {
    final theme = Theme.of(context);

    final issues = _issues;
    if (issues == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (issues.isEmpty) return const SizedBox();

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Container(
            padding: ResponsiveLayout.pageEdgeInsets.copyWith(bottom: 40),
            child: Text(
              "support_history".tr(),
              style: theme.textTheme.headline1,
            )),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final issue = issues[index];
            final status = issue.status;
            final lastMessage = getLastMessage(issue);
            final isRated = (lastMessage.contains(STAR_RATING) ||
                    lastMessage.contains(RATING_MESSAGE_START)) &&
                issue.rating > 0;
            bool hasDivider = (index < issues.length - 1);
            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveLayout.pageEdgeInsets.left),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: _contentRow(issue, hasDivider),
                onTap: () => Navigator.of(context).pushNamed(
                    AppRouter.supportThreadPage,
                    arguments: DetailIssuePayload(
                        reportIssueType: issue.reportIssueType,
                        issueID: issue.issueID,
                        status: status,
                        isRated: isRated)),
              ),
            );
          },
          childCount: issues.length,
        ),
      ),
    ]);
  }

  Widget _contentRow(Issue issue, bool hasDivider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  ReportIssueType.toTitle(issue.reportIssueType),
                  style: theme.textTheme.headline4,
                ),
                if (issue.unread > 0) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      width: 10,
                      height: 10,
                    ),
                  ),
                ]
              ],
            ),
            Row(
              children: [
                Text(getVerboseDateTimeRepresentation(
                    issue.lastMessage?.timestamp.toLocal() ??
                        issue.timestamp.toLocal())),
                const SizedBox(width: 14),
                SvgPicture.asset('assets/images/iconForward.svg'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 17),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Text(
            getPreviewMessage(issue),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyText1,
          ),
        ),
        hasDivider
            ? addDivider()
            : const SizedBox(
                height: 32,
              ),
      ],
    );
  }

  String getPreviewMessage(Issue issue) {
    final lastMessage = getLastMessage(issue);
    if (issue.status == "closed") {
      if (lastMessage.contains(RATING_MESSAGE_START)) {
        return lastMessage.substring(RATING_MESSAGE_START.length);
      }
      if (lastMessage.contains(STAR_RATING)) return "care_to_share".tr();
      return "rate_issue".tr();
    }
    return lastMessage;
  }

  String getLastMessage(Issue issue) {
    var lastMessage = issue.lastMessage;
    if (issue.draft != null) {
      final draft = issue.draft!;
      final draftData = draft.draftData;

      List<ReceiveAttachment> attachments = [];
      if (draftData.attachments != null) {
        final contentType =
            draft.type == CSMessageType.PostPhotos.rawValue ? 'image' : 'logs';
        attachments = draftData.attachments!
            .map((e) => ReceiveAttachment(
                  title: e.fileName,
                  name: '',
                  contentType: contentType,
                ))
            .toList();
      }

      lastMessage = Message(
        id: random.nextInt(100000),
        read: true,
        from: "did:key:user",
        message: draftData.text ?? '',
        attachments: attachments,
        timestamp: draft.createdAt,
      );
    }

    if (lastMessage == null) return '';

    if (lastMessage.filteredMessage.isNotEmpty) {
      return lastMessage.filteredMessage;
    }
    if (lastMessage.attachments.isEmpty) return "";
    final attachment = lastMessage.attachments.last;
    final attachmentTitle =
        ReceiveAttachment.extractSizeAndRealTitle(attachment.title)[1];
    if (attachment.contentType.contains('image')) {
      return "image_sent"
          .tr(args: [attachmentTitle]); //'Image sent: $attachmentTitle';
    } else {
      return "file_sent"
          .tr(args: [attachmentTitle]); //'File sent: $attachmentTitle';
    }
  }
}
