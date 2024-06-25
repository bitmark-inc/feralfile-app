import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/image_background.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FFArtworkThumbnailView extends StatelessWidget {
  const FFArtworkThumbnailView(
      {required this.artwork, this.cacheSize = 0, super.key, this.onTap});

  final Artwork artwork;
  final Function? onTap;
  final int cacheSize;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap?.call(),
        child: Image.network(
          artwork.thumbnailURL,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return ImageBackground(child: child);
            }
            return const GalleryThumbnailPlaceholder();
          },
          errorBuilder: (context, url, error) =>
              const GalleryThumbnailErrorWidget(),
        ),
      );
}
