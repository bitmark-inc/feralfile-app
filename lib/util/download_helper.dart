import 'dart:io';

import 'package:autonomy_flutter/util/file_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class DownloadHelper {
  static final _dio = Dio();

  static Future<int> _getFileSize(Map<String, String> headers) async =>
      int.parse(headers['content-length'] ?? '0');

  static Future<String> _getFileName(Map<String, String> headers) async {
    final fileName = headers['content-disposition']
            ?.split(';')
            .firstWhereOrNull((element) => element.contains('filename'))
            ?.split('=')[1]
            .replaceAll('"', '') ??
        'file';
    return fileName;
  }

  static String _getPartFilePath(String filePath, int partNum) =>
      '$filePath.part$partNum';

  static Future<void> _clearPartFiles(String filePath, int numParts) async {
    for (int i = 0; i < numParts; i++) {
      final partFile = File(_getPartFilePath(filePath, i));
      if (partFile.existsSync()) {
        await partFile.delete();
      }
    }
  }

  static int _getChunkSize(int fileSize) {
    const int maxChunkSize = 1024 * 1024;
    return fileSize > maxChunkSize ? maxChunkSize : fileSize;
  }

  static Future<File?> fileChunkedDownload(String fullUrl,
      {Function(int received, int total)? onReceiveProgress}) async {
    log.info('Downloading file: $fullUrl');
    final dir = await FileHelper.getDownloadDir();
    final savePath = '${dir.path}/Downloads/';
    final request = http.MultipartRequest('GET', Uri.parse(fullUrl));
    final response = await request.send();

    // Get the file size
    final int fileSize = await _getFileSize(response.headers);
    final String fileName = await _getFileName(response.headers);
    final filePath = savePath + fileName;
    int received = 0;

    // Calculate the number of parts
    final partSize = _getChunkSize(fileSize);

    final int numParts = (fileSize / partSize).ceil();
    try {
      // Perform multipart download
      final downloadFeatures = List.generate(numParts, (i) => i).map((i) async {
        final int start = i * partSize;
        final int end = (i + 1) * partSize - 1;

        await _dio.download(
          fullUrl,
          _getPartFilePath(filePath, i),
          options: Options(
            headers: {
              HttpHeaders.rangeHeader: 'bytes=$start-$end',
            },
          ),
        );
        received += partSize;
        if (onReceiveProgress != null) {
          onReceiveProgress(received, fileSize);
        }

        log.info('Downloaded part $i/$numParts');
      });

      const batchSize = 10;
      final batches = <List<Future<void>>>[];
      List<Future<void>> batch = <Future<void>>[];
      for (final future in downloadFeatures) {
        batch.add(future);
        if (batch.length == batchSize) {
          batches.add(batch);
          batch = <Future<void>>[];
        }
      }
      if (batch.isNotEmpty) {
        batches.add(batch);
      }
      for (final batch in batches) {
        await Future.wait(batch);
      }

      // Concatenate parts to create the final file
      final outputFile = File(filePath);
      final IOSink sink = outputFile.openWrite(mode: FileMode.writeOnlyAppend);
      for (int i = 0; i < numParts; i++) {
        final File partFile = File(_getPartFilePath(filePath, i));
        await sink.addStream(partFile.openRead());
      }
      await sink.close();
      await _clearPartFiles(filePath, numParts);
      return outputFile;
    } catch (e) {
      log.info('Error downloading file: $e');
      await _clearPartFiles(filePath, numParts);
    }
    return null;
  }

  static Future<File> downloadFile(
    String fullUrl,
  ) async {
    final response = await http.get(Uri.parse(fullUrl));
    final bytes = response.bodyBytes;
    final header = response.headers;
    final filename = header['x-amz-meta-filename'] ??
        header['content-disposition']
            ?.split(';')
            .firstWhereOrNull((element) => element.contains('filename'))
            ?.split('=')[1]
            .replaceAll('"', '') ??
        'file';
    final file = await FileHelper.saveFileToDownloadDir(bytes, filename);
    return file;
  }
}
