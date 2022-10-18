import 'dart:isolate';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/data/api/tzkt_api.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/database/dao/provenance_dao.dart';
import 'package:nft_collection/database/dao/token_owner_dao.dart';
import 'package:nft_collection/database/nft_collection_database.dart';
import 'package:nft_collection/models/asset.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_collection/models/token_owner.dart';
import 'package:nft_collection/services/configuration_service.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:rxdart/rxdart.dart';

import 'tokens_service_test.mocks.dart';

@GenerateMocks([
  SendPort,
  NftCollectionDatabase,
  NftCollectionPrefs,
  IndexerApi,
  AssetTokenDao,
  TokenOwnerDao,
  ProvenanceDao,
  TZKTApi
])
main() async {
  //late Persona persona;
  //const phrase = "field fiscal play pole name occur concert palm wheat actor fall magnet";
  late TokensServiceImpl tokenService;
  late SendPort sendPort;
  late NftCollectionDatabase database;
  late NftCollectionPrefs collectionPrefs;
  late IndexerApi indexerApi;
  late MockAssetTokenDao assetTokenDao;
  late TZKTApi tzktApi;
  late MockTokenOwnerDao tokenOwnerDao;
  late MockProvenanceDao provenanceDao;
  const txAddress = ["tz1hotTARbXBb71aPRWqp2QT5BgfYGacDoev"];
  group('tokens service test', () {
    setup() async {

      collectionPrefs = MockNftCollectionPrefs();
      indexerApi = MockIndexerApi();
      tzktApi = MockTZKTApi();
      sendPort = MockSendPort();
      assetTokenDao = MockAssetTokenDao();
      tokenOwnerDao = MockTokenOwnerDao();
      provenanceDao = MockProvenanceDao();
      database = MockNftCollectionDatabase();
      when(database.assetDao).thenReturn(assetTokenDao);
      when(database.tokenOwnerDao).thenReturn(tokenOwnerDao);
      when(database.provenanceDao).thenReturn(provenanceDao);
      tokenService = TokensServiceImpl(
          "https://nft-indexer.bitmark.com/", database, collectionPrefs);
      tokenService.setMocktestService(tzktApi, indexerApi);
    }

    test('fetch latest assets', () async {
      await setup();
      DateTime now = DateTime.now();
      const size = 1;
      TokenOwner tokenOwner = TokenOwner("id", txAddress[0], size, now);
      Provenance provenance = Provenance(
          type: "type",
          blockchain: "blockchain",
          txID: "txID",
          owner: "owner",
          timestamp: now,
          txURL: "txURL",
          tokenID: "tokenID");
      Asset asset1 = Asset(
          id: "id",
          edition: 11,
          blockchain: "blockchain",
          fungible: true,
          mintedAt: now,
          contractType: "contractType",
          tokenId: "tokenId",
          contractAddress: "contractAddress",
          blockchainURL: "blockchainURL",
          owner: "owner",
          owners: {txAddress[0]: 1},
          thumbnailID: '',
          lastActivityTime: now,
          projectMetadata: ProjectMetadata(
            origin: ProjectMetadataData(
                artistName: "artistName",
                artistUrl: "artistUrl",
                assetId: "assetId",
                title: "title",
                description: "description",
                medium: 'medium',
                mimeType: 'mimeType',
                maxEdition: 1,
                baseCurrency: "baseCurrency",
                basePrice: 2,
                source: "source",
                sourceUrl: "sourceUrl",
                previewUrl: "previewUrl",
                thumbnailUrl: "thumbnailUrl",
                galleryThumbnailUrl: "galleryThumbnailUrl",
                assetData: "assetData",
                assetUrl: "assetUrl",
                artistId: "artistId",
                originalFileUrl: "originalFileUrl"),
            latest: ProjectMetadataData(
                artistName: "artistName",
                artistUrl: "artistUrl",
                assetId: "assetId",
                title: "title",
                description: "description",
                medium: 'medium',
                mimeType: 'mimeType',
                maxEdition: 1,
                baseCurrency: "baseCurrency",
                basePrice: 2,
                source: "source",
                sourceUrl: "sourceUrl",
                previewUrl: "previewUrl",
                thumbnailUrl: "thumbnailUrl",
                galleryThumbnailUrl: "galleryThumbnailUrl",
                assetData: "assetData",
                assetUrl: "assetUrl",
                artistId: "artistId",
                originalFileUrl: "originalFileUrl"),
          ),
          provenance: [
            provenance
          ]);
      AssetToken assetToken = AssetToken.fromAsset(asset1);

      when(indexerApi.getNftTokensByOwner(txAddress[0], 0, size)).thenAnswer((_) async => [asset1]);

      final tokens = await tokenService.fetchLatestAssets(txAddress, size);

      var a = verify(tokenOwnerDao.insertTokenOwners(captureAny)).captured.first as List<TokenOwner>;
      expect(a.first.indexerId, tokenOwner.indexerId);
      expect(a.first.owner, tokenOwner.owner);
      expect(a.first.quantity, tokenOwner.quantity);
      expect(a.first.updateTime, tokenOwner.updateTime);
      verify(assetTokenDao.insertAssets([assetToken])).called(1);
      verify(provenanceDao.insertProvenance([provenance])).called(1);

      expect(tokens[0], asset1);

    });
  });
}

