import 'dart:convert';
import 'dart:io';
import 'dart:core';
import 'package:autonomy_flutter/util/device.dart';
import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart' as synchronization;
import 'package:path_provider/path_provider.dart';

import 'package:logging/logging.dart';

final log = Logger('AutonomyLogs');

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

class FileLogger {
  static final _lock =
      synchronization.Lock(); // uses the “synchronized” package
  static late File _logFile;

  static Future initializeLogging() async {
    DateTime now = new DateTime.now();
    final directory = await getLogFolderPath();
    final fileName =
        "${await getDeviceID() ?? ""}_${now.year}${now.month}${now.day}.log";
    print(directory);
    _logFile = await _createLogFile("$directory/$fileName");
    final text = '${new DateTime.now()}: LOGGING STARTED\n';

    /// per its documentation, `writeAsString` “Opens the file, writes
    /// the string in the given encoding, and closes the file”
    return _logFile.writeAsString(text, mode: FileMode.write, flush: true);
  }

  static Future log(String s) async {
    final text = '$s\n';
    return _lock.synchronized(() async {
      await _logFile.writeAsString(text, mode: FileMode.append, flush: true);
    });
  }

  static Future<File> _createLogFile(canonicalLogFileName) async =>
      File(canonicalLogFileName).create(recursive: true);
}

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    final curl = cURLRepresentation(err.requestOptions);
    final message = err.message;
    log.info("API Request: $curl");
    log.warning("Respond error: $message");
    return handler.next(err);
  }

  @override
  Future onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    final curl = cURLRepresentation(response.requestOptions);
    final message = response.toString();
    log.info("API Request: $curl");
    log.info("API Response: $message");

    return handler.next(response);
  }

  String cURLRepresentation(RequestOptions options) {
    List<String> components = ["\$ curl -i"];
    if (options.method != null && options.method.toUpperCase() == "GET") {
      components.add("-X ${options.method}");
    }

    if (options.headers != null) {
      options.headers.forEach((k, v) {
        if (k != "Cookie") {
          components.add("-H \"$k: $v\"");
        }
      });
    }

    var data = json.encode(options.data);
    if (data != null) {
      data = data.replaceAll('\"', '\\\"');
      components.add("-d \"$data\"");
    }

    components.add("\"${options.uri.toString()}\"");

    return components.join('\\\n\t');
  }
}
