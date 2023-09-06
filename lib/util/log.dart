//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
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

Future<String> _getLogFilePath() async {
  final directory = (await getTemporaryDirectory()).path;
  const fileName = "app.log";
  debugPrint("Log file: $directory/$fileName");

  return "$directory/$fileName";
}

Future<File> getLogFile() async {
  return _createLogFile(await _getLogFilePath());
}

Future<File> _createLogFile(canonicalLogFileName) async =>
    File(canonicalLogFileName).create(recursive: true);

int? decodeErrorResponse(dynamic e) {
  if (e is DioException && e.type == DioExceptionType.badResponse) {
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
      _logFile.writeAsBytes(current.sublist(current.length - shrinkSize),
          flush: true);
    }

    final text = '${DateTime.now()}: LOGGING STARTED\n';

    /// per its documentation, `writeAsString` “Opens the file, writes
    /// the string in the given encoding, and closes the file”
    _logFile.writeAsString(text, mode: FileMode.append, flush: true);

    return _logFile;
  }

  static setLogFile(File file) {
    _logFile = file;
  }

  static get logFile => _logFile;

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

class BackgroundFileLogger {
  static const _maxLines = 1000; // Maximum number of log lines

  static final _logStreamController = StreamController<LogRecord>();
  static late IOSink _fileSink;
  static int _currentLineCount = 0;

  static void initialize() async {
    final logFile = await getLogFile();
    _fileSink = logFile.openWrite(mode: FileMode.append);

    _logStreamController.stream.listen(_writeLog);

    // Start processing logs in the background
    await for (var logRecord in _logStreamController.stream) {
      _logStreamController.add(logRecord);
    }
  }

  static void _writeLog(LogRecord record) {
    final logLine =
        '${record.time}: [${record.level.name}] ${record.message}\n';

    if (_currentLineCount >= _maxLines) {
      _removeOldestLogs(1);
    }

    _fileSink.write(logLine);
    _currentLineCount++;
  }

  static void _removeOldestLogs(int linesToRemove) async {
    final logFile = await getLogFile();

    final lines = logFile.readAsLinesSync();
    final newLines = lines.skip(linesToRemove).toList();

    _currentLineCount = newLines.length;
    logFile.writeAsStringSync(newLines.join('\n'));
  }

  static Future<void> log(LogRecord record) async {
    _logStreamController.add(record);
  }

  static Future<void> dispose() async {
    await _fileSink.close();
    await _logStreamController.close();
  }
}
