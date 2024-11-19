import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FFArtworkThumbnailView extends StatelessWidget {
  const FFArtworkThumbnailView(
      {required this.url,
      this.cacheWidth,
      this.cacheHeight,
      super.key,
      this.onTap});

  final String url;
  final Function? onTap;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () => onTap?.call(),
      child: FFCacheNetworkImage(
        cacheManager: injector<CacheManager>(),
        imageUrl: url,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        maxWidthDiskCache: cacheWidth,
        maxHeightDiskCache: cacheHeight,
        fit: BoxFit.cover,
        placeholder: (context, url) => const GalleryThumbnailPlaceholder(),
        errorWidget: (context, url, error) =>
            const GalleryThumbnailErrorWidget(),
      ));
}
