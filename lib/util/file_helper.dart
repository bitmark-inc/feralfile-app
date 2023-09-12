import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileHelper {
  Future<bool> askPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  static Future<Directory> createAppFolderIfNeed() async {
    Directory directory = Directory("");
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/Download");
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    final dirPath = directory.path;
    if (await Directory(dirPath).exists()) {
      return Directory(dirPath);
    }
    return await Directory(dirPath).create();
  }

  static Future<File> writeFileToExternalStorage(
      Uint8List data, String name) async {
    final appFolder = await createAppFolderIfNeed();
    var filePath = '${appFolder.path}/$name';

    var bytes = ByteData.view(data.buffer);
    final buffer = bytes.buffer;
    final file = await File(filePath).create(recursive: true);
    return await file.writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}
