import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UXGuideView extends StatelessWidget {
  const UXGuideView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    return Stack(
      children: [
        Opacity(
          opacity: 0.8,
          child: Container(color: theme.backgroundColor),
        ),
        Column(
          children: [
            Stack(fit: StackFit.loose, children: [
              Container(
                alignment: Alignment.topCenter,
                padding: EdgeInsets.fromLTRB(7, 42, 12, 90),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(8, 7.5, 12, 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            "assets/images/iconQr.svg",
                            color: Colors.white,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                            child: SvgPicture.asset(
                              "assets/images/arrow.svg",
                              color: Colors.white,
                            ),
                          ),
                          Text('Scan QR code\nto connect apps',
                              style: theme.textTheme.bodyText1),
                        ],
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.fromLTRB(2, 8, 0, 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SvgPicture.asset(
                            "assets/images/iconCustomerSupport.svg",
                            color: Colors.white,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                            child: SvgPicture.asset(
                              "assets/images/arrow.svg",
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Reach out to\ncustomer support',
                            style: theme.textTheme.bodyText1,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 12),
                      child:
                          SvgPicture.asset("assets/images/guidedPenrose.svg"),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: SvgPicture.asset(
                      "assets/images/arrow_2.svg",
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Access\nsettings',
                    style: theme.textTheme.bodyText1,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ]),
            Expanded(child: SizedBox()),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  Expanded(
                    child: AuFilledButton(
                      text: "GOT IT".toUpperCase(),
                      color: Colors.white,
                      textStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: "IBMPlexMono"),
                      onPress: () {
                        injector<ConfigurationService>().setUXGuideStep(2);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
          ],
        ),
        Center(
            child: Text('How to Autonomy', style: theme.textTheme.headline1)),
      ],
    );
  }
}
