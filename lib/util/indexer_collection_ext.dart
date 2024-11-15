import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:nft_collection/models/user_collection.dart';

extension IndexerCollectionExt on UserCollection {
  String get thumbnailUrl {
    final url = thumbnailURL.isEmpty ? imageURL : thumbnailURL;
    return url.replacePrefix(IPFS_PREFIX, '$DEFAULT_IPFS_PREFIX/ipfs/');
  }
}
