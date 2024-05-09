import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/image_background.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FFArtworkThumbnailView extends StatelessWidget {
  const FFArtworkThumbnailView({required this.artwork, super.key, this.onTap});

  final Artwork artwork;
  final Function? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap?.call(),
        child: ImageBackground(
          child: Image.network(
            artwork.thumbnailURL,
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
        ),
      );
}
