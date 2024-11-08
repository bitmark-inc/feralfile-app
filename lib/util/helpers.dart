//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;

int compareVersion(String version1, String version2) {
  final ver1 =
      version1.split(".").map((e) => int.tryParse(e)).whereNotNull().toList();
  final ver2 =
      version2.split(".").map((e) => int.tryParse(e)).whereNotNull().toList();

  var i = 0;
  while (i < ver1.length && i < ver2.length) {
    final result = ver1[i] - ver2[i];
    if (result != 0) {
      return result;
    }
    i++;
  }
  return ver1.length - ver2.length;
}

Future<http.Response> callRequest(Uri uri) async {
  return await http.get(uri, headers: {
    "Connection": "Keep-Alive",
    "Keep-Alive": "timeout=5, max=1000"
  });
}

String? getVariantFromCloudFlareImageUrl(String url) {
  final RegExp regex = RegExp(r'^https?://[^/]+/[^/]+/[^/]+/([^/]+)$');
  final Match? match = regex.firstMatch(url);
  if (match != null && match.groupCount == 1) {
    return match.group(1);
  } else {
    return null;
  }
}
