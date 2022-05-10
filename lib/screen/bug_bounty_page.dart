import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BugBountyPage extends StatelessWidget {
  const BugBountyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Map<String, String> _guidelines = {
      "Critical":
          "Key leaks or invalid transactions resulting in asset loss: Up to \$5,000",
      "High": "Crashes or user data loss: \$100 - \$500",
      "Medium":
          "Incorrect flows or incompatibility with protocol or dapps: \$50 - \$100",
      "Low": "UI typos, alignment errors: \$10 - \$50",
    };

    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: Container(
          margin: pageEdgeInsetsNotBottom,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bug bounty",
                  style: appTextTheme.headline1,
                ),
                addTitleSpace(),
                Text(
                  "We greatly value feedback from our customers and the work done by security researchers in improving the usability and security of Autonomy. We are committed to quickly verify, reproduce, and respond to legitimate reported interface issues and vulnerabilities. ",
                  style: appTextTheme.bodyText1,
                ),
                SizedBox(height: 32),
                Text('Scope', style: appTextTheme.headline4),
                SizedBox(height: 16),
                RichText(
                    text: TextSpan(
                        style: appTextTheme.bodyText1,
                        children: <TextSpan>[
                      TextSpan(
                        text:
                            'We only accept new bug reports for our iPhone or Android Apps; please check our ',
                      ),
                      TextSpan(
                          recognizer: new TapGestureRecognizer()
                            ..onTap = () =>
                                launch(KNOWN_BUGS_LINK, forceSafariVC: true),
                          text: 'Known Bugs',
                          style: linkStyle),
                      TextSpan(
                        text:
                            ' before submitting. Bug reports for web applications or any other projects are out of scope and will not be considered for rewards.',
                      ),
                    ])),
                SizedBox(height: 32),
                Text('Rewards', style: appTextTheme.headline4),
                Text(
                  'We pay rewards ranging from \$10 to \$5,000, administered according to the following guidelines:',
                  style: appTextTheme.bodyText1,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(10),
                  color: AppColorTheme.secondaryDimGreyBackground,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Guidelines',
                            style: TextStyle(
                                color: AppColorTheme.secondaryDimGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: "AtlasGrotesk",
                                height: 1.377)),
                        SizedBox(height: 5),
                        ..._guidelines.keys
                            .map((e) => Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ' •  ',
                                        style: appTextTheme.bodyText1,
                                        textAlign: TextAlign.start,
                                      ),
                                      Expanded(
                                        child: RichText(
                                            text: TextSpan(
                                                style: appTextTheme.bodyText1,
                                                children: <TextSpan>[
                                              TextSpan(
                                                  text: e,
                                                  style: appTextTheme.bodyText1!
                                                      .copyWith(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14,
                                                  )),
                                              TextSpan(
                                                  text: " – " + _guidelines[e]!,
                                                  style: appTextTheme.bodyText1!
                                                      .copyWith(
                                                    fontSize: 14,
                                                  )),
                                            ])),
                                      ),
                                    ]))
                            .toList(),
                      ]),
                ),
                SizedBox(height: 12),
                Text(
                  'Rewards will be paid out in USDC into Feral File accounts.',
                  style: appTextTheme.bodyText1,
                ),
                SizedBox(height: 32),
                Text('Disclosure policy', style: appTextTheme.headline4),
                SizedBox(height: 16),
                Text(
                    'We support the open publication of security research. We do ask that you give us a heads-up before any publication so we can do a final sync-up and check. ',
                    style: appTextTheme.bodyText1),
                SizedBox(height: 56),
                AuFilledButton(
                  text: "REPORT A BUG".toUpperCase(),
                  onPress: () => Navigator.of(context).pushNamed(
                      AppRouter.supportThreadPage,
                      arguments: NewIssuePayload(
                          reportIssueType: ReportIssueType.Bug)),
                ),
                SizedBox(height: 56),
              ],
            ),
          ),
        ));
  }
}
