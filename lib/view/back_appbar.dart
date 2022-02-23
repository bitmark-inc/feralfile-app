import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

AppBar getBackAppBar(BuildContext context,
    {String title = "", required Function()? onBack}) {
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    leading: SizedBox(),
    leadingWidth: 0.0,
    automaticallyImplyLeading: true,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onBack,
          child: Row(
            children: [
              if (onBack != null) ...[
                Row(
                  children: [
                    Icon(CupertinoIcons.back, color: Colors.black),
                    Text(
                      "BACK",
                      style: appTextTheme.caption,
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(width: 60),
              ],
            ],
          ),
        ),
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: appTextTheme.caption,
        ),
        SizedBox(width: 60),
      ],
    ),
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
  );
}
