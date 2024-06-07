import 'dart:async';

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

  static void cleanCacheByKey(ImageProvider<Object> image) {
    unawaited(image.evict(cache: PaintingBinding.instance.imageCache));
  }
}
