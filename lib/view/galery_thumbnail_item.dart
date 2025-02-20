import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';

class GaleryThumbnailItem extends StatefulWidget {
  const GaleryThumbnailItem(
      {required this.assetToken,
      super.key,
      this.onTap,
      this.usingThumbnailID = false});

  final CompactedAssetToken assetToken;
  final bool usingThumbnailID;
  final Function? onTap;

  @override
  State<StatefulWidget> createState() => _GaleryThumbnailItemState();
}

class _GaleryThumbnailItemState extends State<GaleryThumbnailItem> {
  final _cachedImageSize = 200;

  @override
  Widget build(BuildContext context) {
    final asset = widget.assetToken;

    return GestureDetector(
      child: asset.pending == true && !asset.hasMetadata
          ? PendingTokenWidget(
              thumbnail: asset.galleryThumbnailURL,
              tokenId: asset.tokenId,
              shouldRefreshCache: asset.shouldRefreshThumbnailCache,
            )
          : tokenGalleryThumbnailWidget(
              context,
              asset,
              _cachedImageSize,
              usingThumbnailID: widget.usingThumbnailID,
            ),
      onTap: () {
        widget.onTap?.call();
      },
    );
  }
}
