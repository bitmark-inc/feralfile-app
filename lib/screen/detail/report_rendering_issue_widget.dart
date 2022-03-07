import 'package:autonomy_flutter/screen/report/sentry_report.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

class ReportRenderingIssueWidget extends StatefulWidget {
  final String tokenID;
  final Function onReported;

  const ReportRenderingIssueWidget(
      {Key? key, required this.tokenID, required this.onReported})
      : super(key: key);

  @override
  State<ReportRenderingIssueWidget> createState() =>
      _ReportRenderingIssueWidgetState();
}

class _ReportRenderingIssueWidgetState
    extends State<ReportRenderingIssueWidget> {
  List<String> _selectedTopices = [];

  final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

  @override
  Widget build(BuildContext context) {
    const topics = [
      'Playback',
      'Thumbnail (gallery)',
      'Thumbnail (details page)',
      'Rights',
      'Metadata',
      'Provenance'
    ];

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Select a TOPIC BELOW:'.toUpperCase(),
                  style: theme.textTheme.headline5),
              SizedBox(height: 16),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(topics[index],
                                style: theme.textTheme.headline4),
                            RoundCheckBox(
                              uncheckedColor: Colors.transparent,
                              checkedColor: Colors.white,
                              checkedWidget: Icon(Icons.check,
                                  color: Colors.black, size: 16),
                              animationDuration: Duration(milliseconds: 100),
                              isChecked:
                                  _selectedTopices.contains(topics[index]),
                              size: 24,
                              onTap: (_) {
                                setState(() {
                                  if (_selectedTopices
                                      .contains(topics[index])) {
                                    _selectedTopices.remove(topics[index]);
                                  } else {
                                    _selectedTopices.add(topics[index]);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (index != topics.length - 1) ...[
                          const Divider(height: 30.0, color: Colors.white),
                        ]
                      ],
                    );
                  }),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: AuFilledButton(
                      text: "REPORT ISSUE",
                      onPress: () => _reportIssue(),
                      color: theme.primaryColor,
                      textStyle: TextStyle(
                          color: theme.backgroundColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: "IBMPlexMono"),
                    ),
                  ),
                ],
              ),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("CANCEL",
                      style:
                          appTextTheme.button?.copyWith(color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }

  void _reportIssue() async {
    await reportRenderingIssue(widget.tokenID, _selectedTopices);
    Navigator.pop(context);
    widget.onReported();
  }
}
