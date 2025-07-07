import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

extension DP1PlaylistItemExtension on DP1Item {
  static DP1Item fromCompactedAssetToken({
    required CompactedAssetToken token,
    Duration duration = Duration.zero,
    ArtworkDisplayLicense license = ArtworkDisplayLicense.open,
  }) {
    return DP1Item(
      id: token.id,
      title: token.title!,
      source: token.previewURL!,
      duration: duration.inSeconds,
      license: license,
    );
  }

  static DP1Item fromArtwork({
    required Artwork artwork,
    Duration duration = Duration.zero,
    ArtworkDisplayLicense license = ArtworkDisplayLicense.open,
  }) {
    return DP1Item(
      id: artwork.indexerTokenId!,
      title: artwork.series!.title,
      source: artwork.previewURL,
      duration: duration.inSeconds,
      license: license,
    );
  }
}
