//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:synchronized/synchronized.dart' as synchronization;
import 'package:sentry/sentry.dart';

import 'package:autonomy_flutter/util/device.dart';

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

Future<String> getLogFolderPath() async {
  Directory tempDir = await getTemporaryDirectory();
  return tempDir.path + "/logs";
}

Future<List<String>> getLogFiles() async {
  final directory = await getLogFolderPath();
  return Directory(directory).listSync().map((e) => e.path).toList();
}

Future<String> getLatestLogFile() async {
  final directory = await getLogFolderPath();
  final fileList = Directory(directory).listSync();
  fileList.sort(((a, b) => b.path.compareTo(a.path)));

  return fileList.map((e) => e.path).toList().first;
}

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

  static Future initializeLogging() async {
    DateTime now = new DateTime.now();
    final directory = await getLogFolderPath();
    final fileName =
        "${await getDeviceID() ?? ""}_${now.year}${now.month}${now.day}.log";
    _logFile = await _createLogFile("$directory/$fileName");
    final text = '${new DateTime.now()}: LOGGING STARTED\n';

    /// per its documentation, `writeAsString` “Opens the file, writes
    /// the string in the given encoding, and closes the file”
    return _logFile.writeAsString(text, mode: FileMode.write, flush: true);
  }

  static Future log(LogRecord record) async {
    final text = '${record.toString()}\n';
    return _lock.synchronized(() async {
      await _logFile.writeAsString(text, mode: FileMode.append, flush: true);
    });
  }

  static Future<File> _createLogFile(canonicalLogFileName) async =>
      File(canonicalLogFileName).create(recursive: true);
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
