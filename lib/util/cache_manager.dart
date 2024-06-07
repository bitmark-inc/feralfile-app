import 'package:flutter/material.dart';

class CacheManager {
  static void cleanCache() {
    ImageCacheManager.cleanCache();
  }
}

class ImageCacheManager {
  static void cleanCache() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }

  static void cleanCacheByUrl(String url, {bool includeLiveImages = false}) {
    PaintingBinding.instance.imageCache
        .evict(Uri.parse(url), includeLive: includeLiveImages);
  }
}
