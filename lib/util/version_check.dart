import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

typedef GetStoreVersionAndUrl = Future<StoreVersionAndUrl?> Function(
    String packageName);
typedef ShowUpdateDialog = void Function(VersionCheck versionCheck);

class StoreVersionAndUrl {
  final String storeVersion;
  final String storeUrl;

  StoreVersionAndUrl(this.storeVersion, this.storeUrl);
}

String _country = 'us';

class VersionCheck {
  String? packageName;
  String? packageVersion;
  String? storeVersion;
  String? storeUrl;
  String? country;

  GetStoreVersionAndUrl? getStoreVersionAndUrl;
  ShowUpdateDialog? showUpdateDialog;

  /// VersionCheck constructor
  ///
  /// optional packageName : uses package_info if not provided.
  /// optional packageVersion : uses package_info if not provided.
  /// optional getStoreVersionUrl : function for getting version and url from store. (too override default implementation)
  /// optional showUpdateDialog : function for displaying custom update dialog.
  /// optional country : for ios/mac version check (default: 'us').
  VersionCheck({
    this.packageName,
    this.packageVersion,
    this.getStoreVersionAndUrl,
    this.showUpdateDialog,
    this.country,
  });

  /// check version from iOS/Android/Mac store and
  /// provide update dialog if update is available.
  Future<void> checkVersion(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();

    packageName ??= packageInfo.packageName;
    packageVersion ??= packageInfo.version;
    _country = country ?? 'us';

    if (getStoreVersionAndUrl == null) {
      switch (Platform.operatingSystem) {
        case 'android':
          getStoreVersionAndUrl = _getAndroidStoreVersionAndUrl;
          break;
        case 'ios':
          getStoreVersionAndUrl = _getIOSStoreVersionAndUrl;
          break;
        case 'macos':
          getStoreVersionAndUrl = _getMacStoreVersionAndUrl;
          break;
        default:
          throw "Platform ${Platform.operatingSystem} not supported.";
      }
    }

    final storeVersionAndUrl = await getStoreVersionAndUrl!(packageName!);
    if (storeVersionAndUrl != null) {
      storeVersion = storeVersionAndUrl.storeVersion;
      storeUrl = storeVersionAndUrl.storeUrl;

      if (hasUpdate) {
        showUpdateDialog ??= _showUpdateDialog;
        showUpdateDialog!(this);
      }
    }
  }

  /// check if update is available
  bool get hasUpdate {
    if (packageVersion == null) return false;
    if (storeVersion == null) return false;
    return _shouldUpdate(packageVersion, storeVersion);
  }

  /// launch store for update
  Future<void> launchStore() async {
    final url = Uri.parse(storeUrl!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// compare packageVersion and storeVersion and return true if update is needed.
  static bool shouldUpdate(String? packageVersion, String? storeVersion) {
    return _shouldUpdate(packageVersion, storeVersion);
  }
}

Future<StoreVersionAndUrl?> _getIOSStoreVersionAndUrl(String bundleId) async {
  var params = {'bundleId': bundleId, 'country': _country};
  final uri = Uri.https('itunes.apple.com', '/lookup', params);
  final resp = await http.get(uri);

  if (resp.statusCode == 200) {
    final j = json.decode(resp.body);
    final version = j['results'][0]['version'];
    final url = j['results'][0]['trackViewUrl'];
    return StoreVersionAndUrl(version, url);
  }

  return null;
}

Future<StoreVersionAndUrl?> _getAndroidStoreVersionAndUrl(
    String packageName) async {
  final uri = Uri.https('play.google.com', '/store/apps/details',
      {'id': packageName, 'hl': 'en'});

  final resp = await http.get(uri, headers: {
    'referer': 'http://www.google.com',
    'user-agent':
        "Mozilla/5.0 (Windows; U; WindowsNT 5.1; en-US; rv1.8.1.6) Gecko/20070725 Firefox/2.0.0.6",
  });

  if (resp.statusCode == 200) {
    final doc = parse(resp.body);
    final url = 'https://play.google.com/store/apps/details?id=$packageName';

    try {
      final elements = doc.querySelectorAll('.hAyfc .BgcNfc');

      final cv =
          elements.firstWhere((element) => element.text == 'Current Version');
      final version = cv.nextElementSibling!.text;
      return StoreVersionAndUrl(version, url);
    } catch (_) {}
    try {
      final elements = doc.getElementsByTagName('script');

      for (var e in elements) {
        var match = RegExp('"(\\d+\\.\\d+\\.\\d+)"').firstMatch(e.text);
        if (match != null) {
          return StoreVersionAndUrl(match.group(1)!, url);
        }
      }
    } catch (_) {}

    try {
      final elements = doc.querySelectorAll('div');

      final cv =
          elements.firstWhere((element) => element.text == 'Current Version');
      final version = cv.nextElementSibling!.text;
      return StoreVersionAndUrl(version, url);
    } catch (_) {}
  }

  return null;
}

Future<StoreVersionAndUrl?> _getMacStoreVersionAndUrl(String bundleId) async {
  var params = {'bundleId': bundleId, 'country': _country};
  final uri = Uri.https('itunes.apple.com', '/lookup', params);
  final resp = await http.get(uri);

  if (resp.statusCode == 200) {
    final j = json.decode(resp.body);
    // print(j);
    final version = j['results'][0]['version'];
    final url = j['results'][0]['trackViewUrl'];
    return StoreVersionAndUrl(version, url);
  }

  return null;
}

bool _shouldUpdate(String? packageVersion, String? storeVersion) {
  if (packageVersion == storeVersion) return false;

  final arr1 = packageVersion!.split('.');
  final arr2 = storeVersion!.split('.');

  for (var i = 0; i < math.min(arr1.length, arr2.length); i++) {
    var v1 = int.tryParse(arr1[i]);
    var v2 = int.tryParse(arr2[i]);

    if (v1 == null || v2 == null) {
      if (arr2[i].compareTo(arr1[i]) > 0) {
        return true;
      } else if (arr2[i].compareTo(arr1[i]) < 0) {
        return false;
      }
    } else if (v2 > v1) {
      return true;
    } else if (v2 < v1) {
      return false;
    }
  }

  if (arr2.length > arr1.length) return true;

  return false;
}

void _showUpdateDialog(VersionCheck versionCheck) {
  showDialog(
    context: injector<NavigationService>().navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('update_available'.tr()),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('want_to_update'.tr(
              args: [versionCheck.storeVersion!],
            )),
            Text('current_version'.tr(
              args: [versionCheck.packageVersion!],
            )),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('update'.tr()),
          onPressed: () async {
            Navigator.of(context).pop();
            await versionCheck.launchStore();
          },
        ),
        TextButton(
          child: Text('close'.tr()),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}
