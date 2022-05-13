import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/rand.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
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
    if (mounted)
      setState(() {
        _issues = issues;
      });
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
    final issues = _issues;
    if (issues == null) return Center(child: CupertinoActivityIndicator());

    if (issues.length == 0) return SizedBox();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Container(
            padding: pageEdgeInsets.copyWith(bottom: 40),
            child: Text(
              "Support history",
              style: appTextTheme.headline1,
            )),
      ),
      SliverList(
          delegate: SliverChildBuilderDelegate(
        (context, index) {
          final issue = issues[index];

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: pageEdgeInsets.left),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              child: _contentRow(issue),
              onTap: () => Navigator.of(context).pushNamed(
                  AppRouter.supportThreadPage,
                  arguments: DetailIssuePayload(
                      reportIssueType: issue.reportIssueType,
                      issueID: issue.issueID)),
            ),
          );
        },
        childCount: issues.length,
      )),
    ]);
  }

  Widget _contentRow(Issue issue) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  ReportIssueType.toTitle(issue.reportIssueType),
                  style: appTextTheme.headline4,
                ),
                if (issue.unread > 0) ...[
                  SizedBox(width: 8),
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.black, shape: BoxShape.circle),
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
                SizedBox(width: 14),
                SvgPicture.asset('assets/images/iconForward.svg'),
              ],
            ),
          ],
        ),
        SizedBox(height: 17),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Text(
            getLastMessage(issue),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: appTextTheme.bodyText1,
          ),
        ),
        addDivider(),
      ],
    );
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

    if (lastMessage.filteredMessage.isNotEmpty)
      return lastMessage.filteredMessage;

    final attachment = lastMessage.attachments.last;
    final attachmentTitle =
        ReceiveAttachment.extractSizeAndRealTitle(attachment.title)[1];
    if (attachment.contentType.contains('image')) {
      return 'Image sent: $attachmentTitle';
    } else {
      return 'File sent: $attachmentTitle';
    }
  }
}
