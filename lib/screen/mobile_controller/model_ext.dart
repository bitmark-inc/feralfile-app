import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/screen/mobile_controller/model.dart';
import 'package:autonomy_flutter/util/constants.dart';

extension PlaylistDP1CallExtension on PlaylistDP1Call {
  static PlaylistDP1Call fromCompactedAssetToken(
      {required List<CompactedAssetToken> tokens,
      String? playlistId,
      required Duration duration,
      required ArtworkDisplayLicense license}) {
    final items = tokens
        .map((token) => DP1PlaylistItemExtension.fromCompactedAssetToken(
            token: token, duration: duration, license: license))
        .toList();
    return PlaylistDP1CallExtension.fromItems(
      items: items,
      playlistId: playlistId,
    );
  }

  static PlaylistDP1Call fromItems(
      {required List<DP1PlaylistItem> items, String? playlistId}) {
    return PlaylistDP1Call(
      dpVersion: DP_VERSION,
      id: playlistId ?? '',
      created: DateTime.now(),
      items: items,
      defaults: {},
      signature: '0x17794533e25b08',
    );
  }
}

extension DP1PlaylistItemExtension on DP1PlaylistItem {
  static DP1PlaylistItem fromCompactedAssetToken({
    required CompactedAssetToken token,
    Duration duration = Duration.zero,
    ArtworkDisplayLicense license = ArtworkDisplayLicense.open,
  }) {
    return DP1PlaylistItem(
      id: token.id,
      title: token.title!,
      source: token.previewURL!,
      duration: duration.inSeconds,
      license: license,
    );
  }
}
