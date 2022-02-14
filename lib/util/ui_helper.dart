import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';

class UIHelper {
  static showInfoDialog(
      BuildContext context, String title, String description) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

    showModalBottomSheet(
        context: context,
        // isDismissible: false,
        enableDrag: false,
        // isScrollControlled: false,
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
    Navigator.of(context).pop();
  }
}
