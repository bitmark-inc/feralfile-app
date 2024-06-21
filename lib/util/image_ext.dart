import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

extension ImageExt on CachedNetworkImage {
  static CachedNetworkImage customNetwork(
    String src, {
    Duration fadeInDuration = const Duration(milliseconds: 300),
    BoxFit? fit,
    int? memCacheHeight,
    int? memCacheWidth,
    int? maxWidthDiskCache,
    int? maxHeightDiskCache,
    BaseCacheManager? cacheManager,
    PlaceholderWidgetBuilder? placeholder,
    LoadingErrorWidgetBuilder? errorWidget,
    bool shouldRefreshCache = false,
  }) {
    if (shouldRefreshCache) {
      unawaited(cacheManager?.removeFile(src));
    }
    return CachedNetworkImage(
      imageUrl: src,
      fadeInDuration: Duration.zero,
      fit: BoxFit.cover,
      memCacheHeight: memCacheHeight,
      memCacheWidth: memCacheWidth,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      cacheManager: cacheManager,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
