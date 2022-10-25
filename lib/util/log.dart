//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
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
  const fileName = "app.log";

  return _createLogFile("$directory/$fileName");
}

Future<File> _createLogFile(canonicalLogFileName) async =>
    File(canonicalLogFileName).create(recursive: true);

int? decodeErrorResponse(dynamic e) {
  if (e is DioError && e.type == DioErrorType.response) {
    return e.response?.data['error']['code'] as int;
  }
  return null;
}

class FileLogger {
  static final _lock =
      synchronization.Lock(); // uses the “synchronized” package
  static late File _logFile;
  static const shrinkSize = 1024 * 1024; // 1MB

  static Future initializeLogging() async {
    shrinkLogFileIfNeeded();
  }

  static Future<File> shrinkLogFileIfNeeded() async {
    _logFile = await getLogFile();

    final current = await _logFile.readAsBytes();
    if (current.length > shrinkSize) {
      _logFile.writeAsBytes(current.sublist(current.length - shrinkSize), flush: true);
    }

    final text = '${DateTime.now()}: LOGGING STARTED\n';

    /// per its documentation, `writeAsString` “Opens the file, writes
    /// the string in the given encoding, and closes the file”
    _logFile.writeAsString(text, mode: FileMode.append, flush: true);

    return _logFile;
  }

  static Future log(LogRecord record) async {
    final text = '${record.toString()}\n';
    debugPrint(text);
    return _lock.synchronized(() async {
      await _logFile.writeAsString("${record.time}: $text",
          mode: FileMode.append, flush: true);
    });
  }
}

class SentryBreadcrumbLogger {
  static Future log(LogRecord record) async {
    if (record.loggerName == apiLog.name) {
      // do not send api breadcrumb here.
      return;
    }
    String? type;
    SentryLevel? level;
    if (record.level == Level.WARNING) {
      type = 'error';
      level = SentryLevel.warning;
    }
    Sentry.addBreadcrumb(Breadcrumb(
        message: '[${record.level}] ${record.message}',
        level: level,
        type: type));
  }
}
