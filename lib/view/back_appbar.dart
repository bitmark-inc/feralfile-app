import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

AppBar getBackAppBar(BuildContext context, {required Function() onBack}) {
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    leading: SizedBox(),
    leadingWidth: 0.0,
    automaticallyImplyLeading: true,
    title: GestureDetector(
      onTap: onBack,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.back, color: Colors.black),
          Text(
            "BACK",
            style: appTextTheme.caption,
          )
        ],
      ),
    ),
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
  );
}
