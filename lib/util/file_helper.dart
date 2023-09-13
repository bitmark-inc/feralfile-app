import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';

class FileHelper {
  static Future<bool> saveImageToGallery(Uint8List data, String name) async {
    final response = await ImageGallerySaver.saveImage(data,
        name: name, isReturnImagePathOfIOS: true);
    return response['isSuccess'];
  }
}
