import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FeralFileBrowser extends ChromeSafariBrowser {
  FeralFileBrowser() : super();

  Future<void> openUrl(String url,
          {Color toolbarBackgroundColor = AppColor.primaryBlack}) =>
      open(
          url: WebUri(url),
          settings: ChromeSafariBrowserSettings(
              toolbarBackgroundColor: toolbarBackgroundColor,
              barCollapsingEnabled: true));
}
