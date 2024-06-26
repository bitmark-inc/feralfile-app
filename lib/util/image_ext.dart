import 'dart:async';

import 'package:autonomy_flutter/view/image_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

extension ImageExt on CachedNetworkImage {
  static Widget customNetwork(
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
      final imageProvider = ResizeImage.resizeIfNeeded(
          memCacheWidth, memCacheHeight, NetworkImage(src));
      unawaited(
          imageProvider.evict(cache: PaintingBinding.instance.imageCache));

      Image.network(
        src,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget!(context, src, error),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return ImageBackground(child: child);
          }
          if (placeholder != null) {
            return placeholder(context, src);
          }
          return const ImageBackground(child: SizedBox());
        },
        cacheHeight: memCacheHeight,
        cacheWidth: memCacheWidth,
      );
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
