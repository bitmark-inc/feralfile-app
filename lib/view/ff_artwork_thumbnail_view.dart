import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FFArtworkThumbnailView extends StatelessWidget {
  const FFArtworkThumbnailView(
      {required this.artwork,
      this.cacheWidth = 0,
      this.cacheHeight = 0,
      super.key,
      this.onTap});

  final Artwork artwork;
  final Function? onTap;
  final int cacheWidth;
  final int cacheHeight;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () => onTap?.call(),
      child: CachedNetworkImage(
        cacheManager: injector<CacheManager>(),
        imageUrl: artwork.thumbnailURL,
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
