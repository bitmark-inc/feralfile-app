import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const eulaURL = "https://bitmark.com/terms";
const privacyURL = "https://bitmark.com/privacy";

Widget eulaAndPrivacyView() {
  final customLinkStyle = linkStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      GestureDetector(
        child: Text(
          "EULA",
          style: customLinkStyle,
        ),
        onTap: () => launch(eulaURL, forceSafariVC: true),
      ),
      Text(
        " and ",
        style: TextStyle(
            fontFamily: "AtlasGrotesk", fontSize: 12, color: Colors.black),
      ),
      GestureDetector(
        child: Text(
          "Privacy Policy",
          style: customLinkStyle,
        ),
        onTap: () => launch(privacyURL, forceSafariVC: true),
      ),
    ],
  );
}
