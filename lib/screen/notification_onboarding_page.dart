import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationOnboardingPage extends StatelessWidget {
  final IAPApi _iapApi;
  final AccountService _accountService;
  final ConfigurationService _configurationService;

  const NotificationOnboardingPage(
      this._iapApi, this._accountService, this._configurationService,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: null,
      ),
      body: Container(
        margin:
            EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notifications",
                      style: appTextTheme.headline1,
                    ),
                    SizedBox(height: 30),
                    Markdown(
                      data:
                          '''**Grant Autonomy permission to notify you when:** 
* An NFT is added to your collection or someone sends you an NFT 
* You receive a signing requests from a dapp or service 
* You receive a customer support message 

**We promise to never spam you.**''',
                      softLineBreak: true,
                      padding: EdgeInsets.only(bottom: 50),
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(AuThemeManager()
                          .getThemeData(AppTheme.markdownThemeBlack)),
                    ),
                    Center(
                        child: Padding(
                      child: SvgPicture.asset(
                          'assets/images/notification_onboarding.svg'),
                      padding: EdgeInsets.only(left: 25),
                    ))
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuFilledButton(
                  text: "ENABLE NOTIFICATIONS".toUpperCase(),
                  onPress: () async {
                    final environment = await getAppVariant();
                    final identityHash = (await _iapApi
                            .generateIdentityHash({"environment": environment}))
                        .hash;
                    final defaultDID =
                        await (await _accountService.getDefaultAccount())
                            .getAccountDID();
                    await OneSignal.shared
                        .setExternalUserId(defaultDID, identityHash);
                    _configurationService.setNotificationEnabled(true);
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "NOT NOW",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: "IBMPlexMono"),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
