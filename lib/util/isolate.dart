import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

Future<img.Image> compositeImage(List<Uint8List> images) async =>
    await compute(compositeImages, images);

img.Image compositeImages(List<Uint8List> images) => img.compositeImage(
    img.decodePng(images.first)!, img.decodePng(images.last)!,
    center: true);

class CompositeImageParams {
  final img.Image dst;
  final img.Image src;
  final int x;
  final int y;
  final int index;
  final int w;
  final int h;

  CompositeImageParams(
      this.dst, this.src, this.x, this.y, this.index, this.w, this.h);
}

class ResizeImageParams {
  final img.Image image;
  final int width;
  final int height;

  ResizeImageParams(this.image, this.width, this.height);
}

Future<img.Image> compositeImageAt(
        CompositeImageParams compositeImages) async =>
    await compute(compositeImagesAt, compositeImages);

img.Image compositeImagesAt(CompositeImageParams param) {
  final row = param.index ~/ 9;
  final col = param.index % 9;
  final dstX = param.x + col * param.w;
  final dstY = param.y + row * param.h;

  return img.compositeImage(param.dst, param.src, dstX: dstX - 10, dstY: dstY);
}

Future<img.Image> resizeImage(ResizeImageParams resizeImageParams) async =>
    await compute(resizeImageAt, resizeImageParams);

img.Image resizeImageAt(ResizeImageParams param) =>
    img.copyResize(param.image, width: param.width, height: param.height);

Future<img.Image> decodeFuture(Uint8List data) async =>
    await compute(_decodeImage, data);

img.Image _decodeImage(Uint8List data) => img.decodeImage(data)!;

// isolate encodeImage
Future<Uint8List> encodeImage(img.Image image) async =>
    await compute(_encodeImage, image);

Uint8List _encodeImage(img.Image image) => img.encodePng(image);
