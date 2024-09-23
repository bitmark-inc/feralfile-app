import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileHelper {
  static Future<Directory> getDownloadDir() async =>
      await getApplicationDocumentsDirectory();

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
}
