import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/badge_view.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
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
    return Scaffold(
      appBar: getCloseAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: pageEdgeInsets,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "How can we help?",
                style: appTextTheme.headline1,
              ),
              addTitleSpace(),
              _reportItemsWidget(context),
              SizedBox(height: 60),
              _resourcesWidget(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportItemsWidget(BuildContext context) {
    return Column(
      children: [
        ...ReportIssueType.getList.map((item) {
          return Column(
            children: [
              TappableForwardRow(
                leftWidget: Text(ReportIssueType.toTitle(item),
                    style: appTextTheme.headline4),
                onTap: () => Navigator.of(context).pushNamed(
                    AppRouter.supportThreadPage,
                    arguments: [item, null]),
              ),
              if (item != ReportIssueType.Other) ...[
                addDivider(),
              ]
            ],
          );
        })
      ],
    );
  }

  Widget _resourcesWidget(BuildContext context) {
    return ValueListenableBuilder<List<int>?>(
        valueListenable: injector<CustomerSupportService>().numberOfIssuesInfo,
        builder: (BuildContext context, List<int>? numberOfIssuesInfo,
            Widget? child) {
          if (numberOfIssuesInfo == null)
            return Center(child: CupertinoActivityIndicator());
          if (numberOfIssuesInfo[0] == 0) return SizedBox();

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RESOURCES', style: appTextTheme.headline4),
              SizedBox(height: 19),
              TappableForwardRow(
                  leftWidget:
                      Text('Support history', style: appTextTheme.headline4),
                  rightWidget: numberOfIssuesInfo[1] > 0
                      ? BadgeView(number: numberOfIssuesInfo[1])
                      : null,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRouter.supportListPage)),
              addDivider(),
            ],
          );
        });
  }
}
