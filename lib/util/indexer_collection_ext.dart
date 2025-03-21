import 'package:autonomy_flutter/nft_collection/models/user_collection.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';

extension IndexerCollectionExt on UserCollection {
  String get thumbnailUrl {
    final url = imageURL;
    return url.replacePrefix(IPFS_PREFIX, '$DEFAULT_IPFS_PREFIX/ipfs/');
  }
}
