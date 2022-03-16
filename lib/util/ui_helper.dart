import 'dart:ffi';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share/share.dart';

enum ActionState { notRequested, loading, error, done }

const SHOW_DIALOG_DURATION = const Duration(seconds: 2);
const SHORT_SHOW_DIALOG_DURATION = const Duration(seconds: 1);

void doneOnboarding(BuildContext context) {
  injector<ConfigurationService>().setDoneOnboarding(true);
  Navigator.of(context)
      .pushNamedAndRemoveUntil(AppRouter.homePage, (route) => false);
}

class UIHelper {
  static Future<void> showDialog(
      BuildContext context, String title, Widget content,
      {bool isDismissible = false}) async {
    log.info("[UIHelper] showInfoDialog: $title");
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    await showModalBottomSheet<dynamic>(
        context: context,
        isDismissible: isDismissible,
        enableDrag: false,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            color: Color(0xFF737373),
            child: ClipPath(
              clipper: AutonomyTopRightRectangleClipper(),
              child: Container(
                color: theme.backgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.headline1),
                      SizedBox(height: 40),
                      content,
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  static Future<void> showInfoDialog(
    BuildContext context,
    String title,
    String description, {
    bool isDismissible = false,
    int autoDismissAfter = 0,
  }) async {
    log.info("[UIHelper] showInfoDialog: $title, $description");
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    if (autoDismissAfter > 0) {
      Future.delayed(
          Duration(seconds: autoDismissAfter), () => hideInfoDialog(context));
    }

    await showDialog(
        context,
        title,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              Text(
                description,
                style: theme.textTheme.bodyText1,
              ),
            ],
            SizedBox(height: 40),
          ],
        ),
        isDismissible: isDismissible);
  }

  static hideInfoDialog(BuildContext context) {
    Navigator.popUntil(context, (route) => route.settings.name != null);
  }

  // MARK: - Connection
  static Widget buildConnectionAppWidget(Connection connection, double size) {
    switch (connection.connectionType) {
      case 'dappConnect':
        final remotePeerMeta =
            connection.wcConnection?.sessionStore.remotePeerMeta;
        final appIcons = remotePeerMeta?.icons ?? [];
        if (appIcons.isEmpty) {
          return Container(
              width: size,
              height: size,
              child:
                  Image.asset("assets/images/walletconnect-alternative.png"));
        } else {
          return Image.network(
            appIcons.first,
            width: size,
            height: size,
          );
        }

      case 'beaconP2PPeer':
        final appIcon = connection.beaconConnectConnection?.peer.icon;
        if (appIcon == null || appIcon.isEmpty) {
          return SvgPicture.asset(
            "assets/images/tezos_social_icon.svg",
            width: size,
            height: size,
          );
        } else {
          return Image.network(
            appIcon,
            width: size,
            height: size,
          );
        }

      default:
        return SizedBox();
    }
  }

  // MARK: - Persona
  static showGeneratedPersonaDialog(BuildContext context,
      {required Function() onContinue}) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    showDialog(
        context,
        "Generated!",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MULTI-CHAIN ACCOUNT GENERATED WITH:',
                style: theme.textTheme.headline5),
            SizedBox(height: 16),
            Text('• Bitmark address', style: theme.textTheme.headline4),
            SizedBox(height: 16),
            Text('• Ethereum address', style: theme.textTheme.headline4),
            SizedBox(height: 16),
            Text('• Tezos address', style: theme.textTheme.headline4),
            SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "CONTINUE",
                    onPress: () => onContinue(),
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
            SizedBox(height: 15),
          ],
        ),
        isDismissible: false);
  }

  static showImportedPersonaDialog(BuildContext context,
      {required Function() onContinue}) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    showDialog(
        context,
        "Imported!",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MULTI-CHAIN ACCOUNT GENERATED WITH:',
                style: theme.textTheme.headline5),
            SizedBox(height: 16),
            Text('• Bitmark address', style: theme.textTheme.headline4),
            SizedBox(height: 16),
            Text('• Ethereum address', style: theme.textTheme.headline4),
            SizedBox(height: 16),
            Text('• Tezos address', style: theme.textTheme.headline4),
            SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "CONTINUE",
                    onPress: () => onContinue(),
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
            SizedBox(height: 15),
          ],
        ),
        isDismissible: false);
  }

  static showIdentityDetailDialog(BuildContext context,
      {required String name, required String address}) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    showDialog(
        context,
        "Identity",
        Flexible(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ALIAS', style: theme.textTheme.headline5),
            SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text(
                name,
                style: theme.textTheme.headline4,
                overflow: TextOverflow.ellipsis,
              )),
              GestureDetector(
                child: Text("Share", style: theme.textTheme.headline4),
                onTap: () => Share.share(address),
              )
            ]),
            SizedBox(height: 16),
            Text(
              address,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: "IBMPlexMono"),
            ),
            SizedBox(height: 56),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "CLOSE",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: "IBMPlexMono"),
              ),
            ),
            SizedBox(height: 15),
          ],
        )),
        isDismissible: false);
  }
}
