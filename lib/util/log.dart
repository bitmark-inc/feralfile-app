//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:synchronized/synchronized.dart' as synchronization;

final log = Logger('App');
final apiLog = Logger('API');

enum APIErrorCode {
  invalidToken,
  notLoggedIn,
  expiredSubscription,
  ffNotConnected
}

APIErrorCode? getAPIErrorCode(int code) {
  switch (code) {
    case 7001:
      return APIErrorCode.invalidToken;
    case 1002:
      return APIErrorCode.notLoggedIn;
    case 1041:
      return APIErrorCode.expiredSubscription;
    case 2013:
      return APIErrorCode.ffNotConnected;
    default:
      return null;
  }
}

Future<File> getLogFile() async {
  final directory = (await getTemporaryDirectory()).path;
  const fileName = 'app.log';

  return _createLogFile('$directory/$fileName');
}

Future<File> _createLogFile(canonicalLogFileName) async =>
    File(canonicalLogFileName).create(recursive: true);

class FileLogger {
  static final _lock =
      synchronization.Lock(); // uses the “synchronized” package
  static late File _logFile;
  static const shrinkSize = 1024 * 896; // 1MB characters

  static Future initializeLogging() async {
    await shrinkLogFileIfNeeded();
  }

  static Future<File> shrinkLogFileIfNeeded() async {
    _logFile = await getLogFile();

    final current = await _logFile.readAsString();
    if (current.length > shrinkSize) {
      await _logFile.writeAsString(
          current.substring(current.length - shrinkSize),
          flush: true);
    }

    final text = '${DateTime.now()}: LOGGING STARTED\n';

    /// per its documentation, `writeAsString` “Opens the file, writes
    /// the string in the given encoding, and closes the file”
    await _logFile.writeAsString(text, mode: FileMode.append, flush: true);

    return _logFile;
  }

  static void setLogFile(File file) {
    _logFile = file;
  }

  static File get logFile => _logFile;

  static Future log(LogRecord record) async {
    var text = '$record\n';

    text = _filterLog(text);

    debugPrint(text);
    return _lock.synchronized(() async {
      await _logFile.writeAsString('${record.time}: $text',
          mode: FileMode.append, flush: true);
    });
  }

  static Future<void> clear() async {
    await _logFile.writeAsString('');
  }

  static String _filterLog(String logText) {
    String filteredLog = logText;

    RegExp combinedRegex = RegExp('("message":".*?")|'
        '("Authorization: Bearer .*?")|'
        '("X-Api-Signature: .*?")|'
        r'(signature: [^,\}]*)|'
        r'(location: \[.*?,.*?\])|'
        r'(\\"signature\\":\\".*?\\")|'
        r'(\\"location\\":\[.*?,.*?\])|'
        r'(0x[A-Fa-f0-9]{64}[\s\W])|'
        r'(0x[A-Fa-f0-9]{128,144}[\s\W])|'
        r'(eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_.+/]*)'
        r'(\\"receipt\\":\{[^{}]*\})');

    filteredLog = filteredLog.replaceAllMapped(combinedRegex, (match) {
      if (match[1] != null) {
        return '"message":"REDACTED_MESSAGE"';
      }
      if (match[2] != null) {
        return '"Authorization: Bearer REDACTED_AUTH_TOKEN"';
      }
      if (match[3] != null) {
        return '"X-Api-Signature: REDACTED_X_API_SIGNATURE"';
      }
      if (match[4] != null) {
        return 'signature: REDACTED_SIGNATURE';
      }
      if (match[5] != null) {
        return 'location: REDACTED_LOCATION';
      }
      if (match[6] != null) {
        return r'\"signature\":\"REDACTED_SIGNATURE\"';
      }
      if (match[7] != null) {
        return r'\"location\":REDACTED_LOCATION';
      }
      if (match[8] != null || match[9] != null) {
        return 'REDACTED_SIGNATURE';
      }
      if (match[10] != null) {
        return 'REDACTED_JWT_TOKEN';
      }
      if (match[11] != null) {
        return r'\"receipt\": REDACTED_RECEIPT';
      }
      return '';
    });

    return filteredLog;
  }
}

class SentryBreadcrumbLogger {
  static Future log(LogRecord record) async {
    if (record.loggerName == apiLog.name) {
      // do not send api breadcrumb here.
      return;
    }
    if (record.level == Level.FINE ||
        record.level == Level.FINER ||
        record.level == Level.FINEST) {
      return;
    }
    String? type;
    SentryLevel? level;
    if (record.level == Level.WARNING) {
      type = 'error';
      level = SentryLevel.warning;
    }
    await Sentry.addBreadcrumb(
      Breadcrumb(
          message: '[${record.level}] ${record.message}',
          level: level,
          type: type),
    );
  }

  static Future<void> clear() async {
    await Sentry.configureScope((scope) => scope.clearBreadcrumbs());
  }
}
