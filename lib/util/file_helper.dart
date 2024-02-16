import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class FileHelper {
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
      if (await Permission.storage.request().isGranted) {
        await file.create(recursive: true);
      }
    }
    await file.writeAsBytes(data);
    return file;
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
      await file.delete();
    }
    return result;
  }
}
