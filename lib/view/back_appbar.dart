import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

AppBar getBackAppBar(BuildContext context, {required Function() onBack}) {
  return AppBar(
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
            style: Theme.of(context).textTheme.caption,
          )
        ],
      ),
    ),
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
  );
}
