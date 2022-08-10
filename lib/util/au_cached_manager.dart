//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:autonomy_flutter/util/au_cache_info_repository.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart' as l;
import 'package:flutter_cache_manager/src/storage/cache_object.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

CacheLogger cacheLogger = AUCacheLogger();

class FileDownloadInfo {
  final String? key;
  final String url;
  final String localOriginalFile;
  final String localCompressedFile;
  final BehaviorSubject<FileResponse> progress;

  FileDownloadInfo(
      this.url, this.localOriginalFile, this.localCompressedFile, this.progress,
      {this.key});
}

/// Use [AUCacheManager] if you want to download files from firebase storage
/// and store them in your local cache.
class AUCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'AUCache';
  static const reiszedPrefix = 'resized_';
  final ReceivePort _port = ReceivePort();

  static final AUCacheManager _instance = AUCacheManager._();
  final Map<String, FileDownloadInfo> _memCache = {};
  final HashMap<String, BehaviorSubject<FileResponse>> _requestedUrls =
      HashMap.identity();

  late String savedDir;

  factory AUCacheManager() {
    return _instance;
  }

  AUCacheManager._()
      : super(Config(key,
            stalePeriod: const Duration(days: 30),
            repo: AUCacheInfoRepository(),
            maxNrOfCacheObjects: 10000));

  Future<dynamic> setup() async {
    String tempDir = (await getTemporaryDirectory()).path;
    savedDir = "$tempDir/$key/";

    FlutterImageCompress.validator.ignoreCheckExtName = true;
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      downloadCallback(id, status, progress);
    });
  }

  /// Get the file from the cache and/or online, depending on availability and age.
  /// Downloaded form [url], [headers] can be used for example for authentication.
  /// The files are returned as stream. First the cached file if available, when the
  /// cached file is too old the newly downloaded file is returned afterwards.
  ///
  /// The [FileResponse] is either a [FileInfo] object for fully downloaded files
  /// or a [DownloadProgress] object for when a file is being downloaded.
  /// The [DownloadProgress] objects are only dispatched when [withProgress] is
  /// set on true and the file is not available in the cache. When the file is
  /// returned from the cache there will be no progress given, although the file
  /// might be outdated and a new file is being downloaded in the background.
  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool withProgress = false}) {
    key ??= url;
    final streamController = StreamController<FileResponse>();
    _pushFileToStream(streamController, url, key, headers, withProgress);
    return streamController.stream;
  }

  Future<void> _pushFileToStream(StreamController streamController, String url,
      String? key, Map<String, String>? headers, bool withProgress) async {
    key ??= url;
    FileInfo? cacheFile;
    try {
      cacheFile = await getFileFromCache(key);
      if (cacheFile != null) {
        streamController.add(cacheFile);
        withProgress = false;
      }
    } catch (e) {
      cacheLogger.log(
          'CacheManager: Failed to load cached file for $url with error:\n$e',
          CacheManagerLogLevel.debug);
    }
    if (cacheFile == null || cacheFile.validTill.isBefore(DateTime.now())) {
      try {
        await for (var response
            in await _downloadFile(url, key: key, authHeaders: headers)) {
          if (response is DownloadProgress && withProgress) {
            streamController.add(response);
          }
          if (response is FileInfo) {
            streamController.add(response);
          }
        }
      } catch (e) {
        cacheLogger.log(
            'CacheManager: Failed to download file from $url with error:\n$e',
            CacheManagerLogLevel.debug);
        if (cacheFile == null && streamController.hasListener) {
          streamController.addError(e);
        }
      }
    }
    unawaited(streamController.close());
  }

  ///Download the file and add to cache
  @override
  Future<FileInfo> downloadFile(String url,
      {String? key,
      Map<String, String>? authHeaders,
      bool force = false}) async {
    key ??= url;

    return (await _downloadFile(
      url,
      key: key,
      authHeaders: authHeaders,
      ignoreMemCache: force,
    ))
        .firstWhere((r) => r is FileInfo) as Future<FileInfo>;
  }

  Future<Stream<FileResponse>> _downloadFile(String url,
      {String? key,
      Map<String, String>? authHeaders,
      bool ignoreMemCache = false}) async {
    key ??= url;

    final oldCallback = _requestedUrls[url];
    if (oldCallback != null) {
      return oldCallback;
    }

    final ext = p.extension(url);
    String fileName = md5.convert(utf8.encode(url)).toString() + ext;
    String resizedFileName = reiszedPrefix + fileName;

    final fileDownloadInfo = FileDownloadInfo(
        url, fileName, resizedFileName, BehaviorSubject<FileResponse>(),
        key: key);
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      fileName: fileName,
      headers: authHeaders,
      savedDir: savedDir,
      showNotification:
          false, // show download progress in status bar (for Android)
      openFileFromNotification: false,
    );
    if (taskId != null) {
      _memCache[taskId] = fileDownloadInfo;
      _requestedUrls[url] = fileDownloadInfo.progress;
    }

    return fileDownloadInfo.progress;
  }

  void downloadCallback(
      String id, DownloadTaskStatus status, int progress) async {
    final fileDownloadInfo = _memCache[id];
    if (fileDownloadInfo != null && status == DownloadTaskStatus.complete) {
      final key = fileDownloadInfo.key ?? fileDownloadInfo.url;

      // If the file is already in Cloudflare image service, not resize
      if (fileDownloadInfo.url.startsWith(CLOUDFLAREIMAGEURLPREFIX)) {
        // Store the original file
        await store.putFile(CacheObject(fileDownloadInfo.url,
            key: key,
            relativePath: fileDownloadInfo.localOriginalFile,
            validTill: DateTime.now().add(const Duration(days: 30))));
      } else {
        // Store the resized file
        await FlutterImageCompress.compressAndGetFile(
          savedDir + fileDownloadInfo.localOriginalFile,
          savedDir + fileDownloadInfo.localCompressedFile,
          minWidth: 400,
          minHeight: 400,
          quality: 90,
        );

        await store.putFile(CacheObject(fileDownloadInfo.url,
            key: key,
            relativePath: fileDownloadInfo.localCompressedFile,
            validTill: DateTime.now().add(const Duration(days: 30))));

        // delete the original file
        cacheLogger.log(
            'deleted ${savedDir + fileDownloadInfo.localOriginalFile}',
            CacheManagerLogLevel.debug);
        File(savedDir + fileDownloadInfo.localOriginalFile).delete();
      }
      final file = await store.getFile(key);
      if (file != null) {
        fileDownloadInfo.progress.add(file);
      }

      cacheLogger.log(
          'downloaded ${fileDownloadInfo.url}', CacheManagerLogLevel.debug);
    }
  }
}

class AUCacheLogger extends CacheLogger {
  Level logLevel(CacheManagerLogLevel level) {
    switch (level) {
      case CacheManagerLogLevel.debug:
        return Level.FINE;
      case CacheManagerLogLevel.none:
        return Level.OFF;
      case CacheManagerLogLevel.verbose:
        return Level.FINEST;
      case CacheManagerLogLevel.warning:
        return Level.WARNING;
    }
  }

  /// Function to log a message on a certain loglevel
  @override
  void log(String message, CacheManagerLogLevel level) {
    l.log.log(logLevel(level), message);
  }
}
