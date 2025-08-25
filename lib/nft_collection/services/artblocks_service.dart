import 'package:autonomy_flutter/nft_collection/graphql/clients/artblocks_client.dart';
import 'package:autonomy_flutter/nft_collection/nft_collection.dart';
import 'package:autonomy_flutter/nft_collection/models/artblocks_artist.dart'; // Import ArtBlockArtist

class ArtBlockService {
  final ArtblocksClient _artblocksClient;

  ArtBlockService(this._artblocksClient);

  // GraphQL query to get artist name by public address
  static const String _artistQuery = r'''
    query Artists(
        $public_address: String!
    ) {
        artists(
            where: { public_address: { _eq: $public_address } }
        ) {
            public_address
            user {
                display_name
            }
        }
    }
  ''';

  Future<ArtBlockArtist?> getArtistByAddress(String address) async {
    try {
      final result = await _artblocksClient.query(
        doc: _artistQuery,
        vars: {'public_address': address},
      );

      if (result != null && (result['artists'] as List<dynamic>).isNotEmpty) {
        final artist = result['artists'][0];
        final artistAddress = artist['public_address'] as String?;
        final displayName = artist['user']['display_name'] as String?;

        if (artistAddress != null && displayName != null) {
          return ArtBlockArtist(
            address: artistAddress,
            name: displayName,
          );
        }
      }
      return null;
    } catch (e) {
      NftCollection.logger.info('Error getting artist by address: $e');
      return null;
    }
  }

  Future<ArtBlockArtist?> getArtistByToken({
    required String contractAddress,
    required String tokenId,
  }) async {
    try {
      final result = await _artblocksClient.queryProjectMetadata(
        contractAddress: contractAddress,
        tokenId: tokenId,
      );

      if (result != null &&
          (result['projects_metadata'] as List<dynamic>).isNotEmpty) {
        final projectMetadata = result['projects_metadata'][0];
        final artistName = projectMetadata['artist_name'] as String?;
        final artistAddress = projectMetadata['artist_address'] as String?;

        if (artistName != null && artistAddress != null) {
          return ArtBlockArtist(
            address: artistAddress,
            name: artistName,
          );
        }
      }
      return null;
    } catch (e) {
      NftCollection.logger.info('Error getting artist by token: $e');
      return null;
    }
  }
}
