import 'dart:io';
import 'dart:typed_data';

import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class FileHelper {
  static final dio = Dio();

  static Future<Directory> getDownloadDir() async =>
      await getApplicationDocumentsDirectory();

  static Future<bool> saveImageToGallery(Uint8List data, String name) async {
    final response = await ImageGallerySaver.saveImage(data,
        name: name, isReturnImagePathOfIOS: true);
    return response['isSuccess'];
  }

  static Future<bool> saveFileToGallery(String path, String name) async {
    final response = await ImageGallerySaver.saveFile(path, name: name);
    return response['isSuccess'];
  }

  static Future<File> saveFileToDownloadDir(
      Uint8List data, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    File file = File('${dir.path}/Downloads/$filename');
    if (!file.existsSync()) {
      if (Platform.isAndroid || await Permission.storage.request().isGranted) {
        await file.create(recursive: true);
      }
    }
    await file.writeAsBytes(data);
    return file;
  }

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

  static Future<File?> downloadFileMultipart(String fullUrl) async {
    log.info('Downloading file: $fullUrl');
    final dir = await getDownloadDir();
    final savePath = '${dir.path}/Downloads/';
    final request = http.MultipartRequest('GET', Uri.parse(fullUrl));
    final response = await request.send();

    // Get the file size
    final int fileSize = await _getFileSize(response.headers);
    final String fileName = await _getFileName(response.headers);
    final filePath = savePath + fileName;

    // Calculate the number of parts
    const partSize = 5 * 1024 * 1024;

    final int numParts = (fileSize / partSize).ceil();
    try {
      // Perform multipart download
      await Future.wait(List.generate(numParts, (i) => i).map((i) async {
        final int start = i * partSize;
        final int end = (i + 1) * partSize - 1;

        await dio.download(
          fullUrl,
          _getPartFilePath(filePath, i),
          options: Options(
            headers: {
              HttpHeaders.rangeHeader: 'bytes=$start-$end',
            },
          ),
        );
        log.info('Downloaded part $i/$numParts');
      }));

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

  static Future<ShareResult> shareFile(File file,
      {bool deleteAfterShare = false, Function? onShareSuccess}) async {
    final result = await Share.shareXFiles([XFile(file.path)]);
    if (result.status == ShareResultStatus.success) {
      onShareSuccess?.call();
    }
    if (deleteAfterShare) {
      try {
        await file.delete();
      } catch (_) {
        // ignore when file is not found
      }
    }
    return result;
  }
}
