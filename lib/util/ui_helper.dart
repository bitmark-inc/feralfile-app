import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';

enum ActionState { notRequested, loading, error, done }

const SHOW_DIALOG_DURATION = const Duration(seconds: 2);
const SHORT_SHOW_DIALOG_DURATION = const Duration(seconds: 1);

void doneOnboarding(BuildContext context) {
  injector<ConfigurationService>().setDoneOnboarding(true);
  Navigator.of(context)
      .pushNamedAndRemoveUntil(AppRouter.homePage, (route) => false);
}

class UIHelper {
  static showInfoDialog(
    BuildContext context,
    String title,
    String description, {
    bool isDismissible = false,
  }) {
    log.info("[UIHelper] showInfoDialog: $title, $description");
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    showModalBottomSheet(
        context: context,
        isDismissible: isDismissible,
        enableDrag: false,
        builder: (context) {
          return Container(
            color: Color(0xFF737373),
            child: ClipPath(
              clipper: AutonomyTopRightRectangleClipper(),
              child: Container(
                color: theme.backgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headline1),
                    if (description.isNotEmpty) ...[
                      SizedBox(height: 40),
                      Text(
                        description,
                        style: theme.textTheme.bodyText1,
                      ),
                    ],
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        });
  }

  static hideInfoDialog(BuildContext context) {
    Navigator.popUntil(context, (route) => route.settings.name != null);
  }
}
