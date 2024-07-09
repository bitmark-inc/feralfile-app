import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
        child: Image.network(
          artwork.thumbnailURL,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return const GalleryThumbnailPlaceholder();
          },
          errorBuilder: (context, url, error) =>
              const GalleryThumbnailErrorWidget(),
        ),
      );
}
