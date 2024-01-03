import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/mime_type.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

String _cacheKey = 'AUCache';

class Info {
  final String url;
  final String fileExt;
  final String taskId;
  final String localFile;
  final Completer<FileServiceResponse> task;

  Info(
    this.url,
    this.fileExt,
    this.taskId,
    this.localFile,
    this.task,
  );
}

class AUImageCacheManage extends CacheManager with ImageCacheManager {
  static final AUImageCacheManage _instance = AUImageCacheManage._();

  factory AUImageCacheManage() => _instance;

  AUImageCacheManage._()
      : super(
          Config(_cacheKey,
              fileService: AuFileService(),
              stalePeriod: const Duration(days: 30),
              maxNrOfCacheObjects: 10000),
        );
}

class AuFileServiceResponse extends FileServiceResponse {
  final File _localFile;
  final String fileExt;
  final DateTime _validTill = DateTime.now().add(const Duration(days: 30));

  AuFileServiceResponse({
    required String filePath,
    required this.fileExt,
  }) : _localFile = File(filePath);

  @override
  // ignore: discarded_futures
  Stream<List<int>> get content => _localFile.readAsBytes().asStream();

  @override
  int? get contentLength => _localFile.lengthSync();

  @override
  String? get eTag => null;

  @override
  String get fileExtension => '.$fileExt';

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => _validTill;
}

class AuFileService extends FileService {
  static final AuFileService _instance = AuFileService._();

  final Map<String, Info> _taskId2Info = {};

  final ReceivePort _port = ReceivePort();
  late String _saveDir;

  factory AuFileService() => _instance;

  AuFileService._();

  Future<dynamic> setup() async {
    String tempDir = (await getTemporaryDirectory()).path;
    _saveDir = '$tempDir/$_cacheKey/';
    await Directory(_saveDir).create(recursive: true);
    FlutterImageCompress.validator.ignoreCheckExtName = true;
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((data) async {
      String id = data[0];
      DownloadTaskStatus status = DownloadTaskStatus.fromInt(data[1] as int);
      int progress = data[2];
      await _downloadCallback(id, status, progress);
    });
  }

  Future _downloadCallback(
      String id, DownloadTaskStatus status, int progress) async {
    final info = _taskId2Info[id];
    if (info != null) {
      if (status == DownloadTaskStatus.complete) {
        File localFile = File(_saveDir + info.localFile);
        final fileSize = await localFile.length();
        if (fileSize <= 0) {
          log.info('File is empty ${info.url}');
          info.task.completeError(Exception('File is empty ${info.url}'));
        } else if (info.url.startsWith(Environment.cloudFlareImageUrlPrefix)) {
          info.task.complete(AuFileServiceResponse(
            filePath: _saveDir + info.localFile,
            fileExt: info.fileExt,
          ));
        } else {
          try {
            final originalFile = _saveDir + info.localFile;
            final compressedFile = '${_saveDir}resized_${info.localFile}.jpeg';
            await FlutterImageCompress.compressAndGetFile(
              originalFile,
              compressedFile,
              quality: 90,
            );
            if (await File(compressedFile).exists()) {
              await File(originalFile).delete();
              info.task.complete(AuFileServiceResponse(
                filePath: compressedFile,
                fileExt: 'jpeg',
              ));
            } else {
              info.task.complete(AuFileServiceResponse(
                filePath: originalFile,
                fileExt: info.fileExt,
              ));
            }
          } catch (e) {
            log.info('Compress image failed ${info.url} Error: $e');
            info.task.complete(AuFileServiceResponse(
              filePath: _saveDir + info.localFile,
              fileExt: info.fileExt,
            ));
          }
        }
        _taskId2Info.remove(id);
      } else if (status == DownloadTaskStatus.failed) {
        log.info('[AuFileService] Download failed: ${info.url}');
        info.task.completeError(Exception('Download failed ${info.url}'));
        _taskId2Info.remove(id);
      } else if (status == DownloadTaskStatus.canceled) {
        log.info('[AuFileService] Download canceled: ${info.url}');
        info.task.completeError(Exception('Download canceled ${info.url}'));
        _taskId2Info.remove(id);
      }
    }
  }

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    var info =
        _taskId2Info.values.firstWhereOrNull((element) => element.url == url);
    if (info == null) {
      final fileInfo = await getFileInfo(url);
      String? fallbackUrl;
      if (fileInfo.size <= 0 &&
          url.startsWith(Environment.autonomyIpfsPrefix)) {
        fallbackUrl = url.replacePrefix(
          Environment.autonomyIpfsPrefix,
          DEFAULT_IPFS_PREFIX,
        );
      }
      if (!(Uri.tryParse(fallbackUrl ?? url)?.hasAbsolutePath ?? false)) {
        return Future.error(Exception('Invalid url $url'));
      }

      final fileName = '${md5.convert(utf8.encode(url))}.${fileInfo.extension}';
      final taskId = await FlutterDownloader.enqueue(
        url: fallbackUrl ?? url,
        headers: headers ?? {},
        savedDir: _saveDir,
        fileName: fileName,
        showNotification: false,
        openFileFromNotification: false,
        timeout: 5000,
      );
      info = Info(url, fileInfo.extension, taskId ?? '', fileName, Completer());
      _taskId2Info[taskId ?? ''] = info;
    }
    return info.task.future;
  }
}
