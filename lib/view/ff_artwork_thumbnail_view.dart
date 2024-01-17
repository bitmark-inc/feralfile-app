import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FFArtworkThumbnailView extends StatelessWidget {
  const FFArtworkThumbnailView({required this.artwork, super.key, this.onTap});

  final Artwork artwork;
  final Function? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap?.call(),
        child: CachedNetworkImage(
          imageUrl: artwork.thumbnailURL,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          placeholder: (context, url) => const GalleryThumbnailPlaceholder(),
          errorWidget: (context, url, error) =>
              const GalleryThumbnailErrorWidget(),
        ),
      );
}
