import 'dart:io';
import 'dart:typed_data';

import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';

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
    String dir = (await DownloadsPathProvider.downloadsDirectory)!.path;
    File file = File('$dir/$filename');
    await file.writeAsBytes(data);
    return file;
  }

  static Future<File> downloadFile(
    String fullUrl,
  ) async {
    final response = await http.get(Uri.parse(fullUrl));
    final bytes = response.bodyBytes;
    final header = response.headers;
    final filename = header['x-amz-meta-filename'] ?? '';
    final file = await FileHelper.saveFileToDownloadDir(bytes, filename);
    return file;
  }
}
