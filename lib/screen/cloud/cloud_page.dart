import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';

class CloudPage extends StatelessWidget {
  final String section;
  const CloudPage({Key? key, required this.section}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: canPop == true
            ? () {
                Navigator.of(context).pop();
              }
            : null,
      ),
      body: _contentWidget(context),
    );
  }

  Widget _contentWidget(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: injector<CloudService>().isAvailableNotifier,
        builder: (BuildContext context, bool isAvailable, Widget? child) {
          return Container(
            margin: pageEdgeInsetsWithSubmitButton,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAvailable ? "Backed up" : "Sign in to iCloud",
                            style: appTextTheme.headline1,
                          ),
                          addTitleSpace(),
                          Text(
                            "Autonomy will automatically back up all of your account information securely, including cryptographic material from accounts you manage as well as links to your accounts. If you ever lose your phone, you will be able to recover everything.",
                            style: appTextTheme.bodyText1,
                          ),
                          if (isAvailable) ...[
                            SizedBox(height: 40),
                            Center(
                                child: SvgPicture.asset(
                                    "assets/images/cloudOn.svg")),
                          ] else ...[
                            SizedBox(height: 16),
                            Text(
                              "iCloud is currently turned off on your device. We recommend you enable it so we can safely back up your account.",
                              style: appTextTheme.headline4,
                            ),
                            SizedBox(height: section == "settings" ? 40 : 80),
                            Center(
                                child: SvgPicture.asset(
                                    "assets/images/icloudKeychainGuide.svg")),
                            SizedBox(height: 20),
                          ],
                        ]),
                  ),
                ),
                _buttonsGroup(context, isAvailable),
              ],
            ),
          );
        });
  }

  Widget _buttonsGroup(BuildContext context, bool isAvailable) {
    switch (section) {
      case "nameAlias":
        if (isAvailable) {
          return Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  text: "CONTINUE".toUpperCase(),
                  onPress: () => _continue(context),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AuFilledButton(
                      text: "CONTINUE WITHOUT ICLOUD".toUpperCase(),
                      onPress: () => _continue(context),
                    ),
                  ),
                ],
              ),
              TextButton(
                  onPressed: () => openAppSettings(),
                  child: Text("OPEN ICLOUD SETTINGS",
                      style:
                          appTextTheme.button?.copyWith(color: Colors.black))),
            ],
          );
        }

      case "settings":
        if (isAvailable) {
          return SizedBox();
        } else {
          return Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  text: "OPEN ICLOUD SETTINGS".toUpperCase(),
                  onPress: () => openAppSettings(),
                ),
              ),
            ],
          );
        }

      default:
        return SizedBox();
    }
  }

  void _continue(BuildContext context) {
    if (injector<ConfigurationService>().isDoneOnboarding()) {
      Navigator.of(context).popUntil((route) =>
          route.settings.name == AppRouter.settingsPage ||
          route.settings.name == AppRouter.wcConnectPage ||
          route.settings.name == AppRouter.homePage ||
          route.settings.name == AppRouter.homePageNoTransition);
    } else {
      doneOnboarding(context);
    }
  }
}
