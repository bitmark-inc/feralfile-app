import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const eulaURL = "https://bitmark.com/terms";
const privacyURL = "https://bitmark.com/privacy";

Widget eulaAndPrivacyView() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      GestureDetector(
        child: Text(
          "EULA",
          style: TextStyle(
              fontFamily: "AtlasGrotesk",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black),
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
          style: TextStyle(
              fontFamily: "AtlasGrotesk",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),
        onTap: () => launch(privacyURL, forceSafariVC: true),
      ),
    ],
  );
}
