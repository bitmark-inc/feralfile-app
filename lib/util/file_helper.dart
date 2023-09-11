import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileHelper {
  static Future<Directory> createAppFolderIfNeed() async {
    Directory directory = Directory("");
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0");
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    const appName = "Autonomy";
    final dirPath = '${directory.path}/$appName';
    if (await Directory(dirPath).exists()) {
      return Directory(dirPath);
    }
    return await Directory(dirPath).create();
  }

  static Future<File> writeFileToExternalStorage(
      Uint8List data, String name) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    final appFolder = await createAppFolderIfNeed();
    var filePath = '${appFolder.path}/$name';

    var bytes = ByteData.view(data.buffer);
    final buffer = bytes.buffer;
    final file = await File(filePath).create(recursive: true);
    return await file.writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}
