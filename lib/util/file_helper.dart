import 'dart:io';
import 'dart:typed_data';

import 'package:autonomy_flutter/util/log.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class FileHelper {
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
    log.info('File saved to: ${file.path}');
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
