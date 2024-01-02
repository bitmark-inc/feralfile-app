import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:flutter/material.dart';

class FFArtworkThumbnailView extends StatelessWidget {
  const FFArtworkThumbnailView({required this.artwork, super.key, this.onTap});

  final Artwork artwork;
  final Function? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap?.call(),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(artwork.thumbnailURL),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
}
