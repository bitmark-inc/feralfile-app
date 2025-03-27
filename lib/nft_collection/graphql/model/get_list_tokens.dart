import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/utils/constants.dart';

class QueryListTokensResponse {
  QueryListTokensResponse({
    required this.tokens,
  });

  factory QueryListTokensResponse.fromJson(Map<String, dynamic> map) {
    return QueryListTokensResponse(
      tokens: map['tokens'] != null
          ? List<AssetToken>.from(
              (map['tokens'] as List<dynamic>).map<AssetToken>(
                (x) => AssetToken.fromJsonGraphQl(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }

  List<AssetToken> tokens;
}

class QueryListTokensRequest {
  QueryListTokensRequest({
    this.owners = const [],
    this.ids = const [],
    this.lastUpdatedAt,
    this.offset = 0,
    this.size = indexerTokensPageSize,
  }) : burnedIncluded = ids.any((id) => id.startsWith('bmk'));

  final List<String> owners;
  final List<String> ids;
  final DateTime? lastUpdatedAt;
  final int offset;
  final int size;
  final bool burnedIncluded;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'owners': owners,
      'ids': ids,
      'lastUpdatedAt': lastUpdatedAt?.toUtc().toIso8601String(),
      'offset': offset,
      'size': size,
      'burnedIncluded': burnedIncluded,
    };
  }
}
