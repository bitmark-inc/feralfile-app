import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class PlaylistItemCard extends StatelessWidget {
  const PlaylistItemCard({
    required this.asset,
    this.playlistTitle,
    super.key,
  });

  final AssetToken asset;
  final String? playlistTitle;

  @override
  Widget build(BuildContext context) {
    final title = asset.title ?? '';
    final artist = asset.artistName ?? '';
    return GestureDetector(
      onTap: () {
        injector<NavigationService>().navigateTo(
          AppRouter.artworkDetailsPage,
          arguments: ArtworkDetailPayload(
            ArtworkIdentity(asset.id, asset.owner),
            useIndexer: true,
            backTitle: playlistTitle,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Center(
                child: FFCacheNetworkImage(
                  imageUrl: asset.galleryThumbnailURL ?? '',
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist,
                  style: Theme.of(context).textTheme.ppMori700White12,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  // italic
                  style: Theme.of(context)
                      .textTheme
                      .ppMori700White12
                      .copyWith(fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
