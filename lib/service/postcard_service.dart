//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/request_response.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_exception_ext.dart';
import 'package:autonomy_flutter/util/file_helper.dart';
import 'package:autonomy_flutter/util/http_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';
import 'package:path_provider/path_provider.dart';

import 'account_service.dart';

abstract class PostcardService {
  Future<ReceivePostcardResponse> receivePostcard(
      {required String shareCode, Location? location, required String address});

  Future<ClaimPostCardResponse> claimEmptyPostcard(
      ClaimPostCardRequest request);

  Future<RequestPostcardResponse> requestPostcard(
      RequestPostcardRequest request);

  Future<SharePostcardResponse> sharePostcard(AssetToken asset);

  Future<void> cancelSharePostcard(AssetToken asset);

  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode);

  Future<AssetToken> getPostcard(String tokenId);

  Future<bool?> stampPostcard(
      String tokenId,
      WalletStorage wallet,
      int index,
      File image,
      File metadata,
      Location? location,
      int counter,
      String contractAddress);

  List<StampingPostcard> getStampingPostcard();

  StampingPostcard? getStampingPostcardWithPath(
      StampingPostcard stampingPostcard);

  Future<void> updateStampingPostcard(List<StampingPostcard> values,
      {bool override = false, bool isRemove = false});

  Future<PostcardLeaderboard> fetchPostcardLeaderboard(
      {required String unit, required int size, required int offset});

  Future<void> downloadStamp({
    required String tokenId,
    required int stampIndex,
  });

  Future<void> downloadPostcard(String tokenId);

  String getTokenId(String id);

  Future<AssetToken> claimEmptyPostcardToAddress(
      {required String address,
      required RequestPostcardResponse requestPostcardResponse});

  Future<AssetToken> claimSharedPostcardToAddress({
    required String address,
    required AssetToken assetToken,
    required String shareCode,
    required Location location,
  });

  Future<bool> finalizeStamp(AssetToken asset, String imagePath,
      String metadataPath, Location location);
}

class PostcardServiceImpl extends PostcardService {
  final PostcardApi _postcardApi;
  final TezosService _tezosService;
  final IndexerService _indexerService;
  final ConfigurationService _configurationService;
  final AccountService _accountService;
  final TokensService _tokensService;
  final MetricClientService _metricClientService;
  final ChatService _chatService;

  PostcardServiceImpl(
    this._postcardApi,
    this._tezosService,
    this._indexerService,
    this._configurationService,
    this._accountService,
    this._tokensService,
    this._metricClientService,
    this._chatService,
  );

  @override
  Future<ClaimPostCardResponse> claimEmptyPostcard(
      ClaimPostCardRequest request) async {
    log.info('claimEmptyPostcard request: ${request.toJson()}');
    return _postcardApi.claim(request);
  }

  @override
  Future<ReceivePostcardResponse> receivePostcard({
    required String shareCode,
    Location? location,
    required String address,
  }) async {
    log.info('receivePostcard shareCode: $shareCode, address: $address');
    try {
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final accountService = injector<AccountService>();
      final walletIndex = await accountService.getAccountByAddress(
          chain: 'tezos', address: address);
      final publicKey =
          await walletIndex.wallet.getTezosPublicKey(index: walletIndex.index);
      final signature = await _tezosService.signMessage(walletIndex.wallet,
          walletIndex.index, Uint8List.fromList(utf8.encode(timestamp)));
      final body = {
        'shareCode': shareCode,
        'location': (location?.lat == null || location?.lon == null)
            ? []
            : [location?.lat, location?.lon],
        'address': address,
        'publicKey': publicKey,
        'signature': signature,
        'timestamp': timestamp,
      };
      final response = await _postcardApi.receive(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SharePostcardResponse> sharePostcard(AssetToken asset) async {
    final owner = await asset.getOwnerWallet();
    final ownerWallet = owner?.first;
    final addressIndex = owner?.second;
    if (ownerWallet == null) {
      throw Exception('Owner wallet is null');
    }
    final counter = asset.numberOwners;
    final contractAddress = asset.contractAddress ?? '';
    final tokenId = asset.tokenId ?? '';
    log.info('''
        sharePostcard contractAddress: $contractAddress, tokenId: $tokenId, 
        counter: $counter
        ''');
    final data = [
      TezosPack.packAddress(contractAddress),
      TezosPack.packInteger(int.parse(tokenId)),
      TezosPack.packInteger(counter),
    ].toList();

    final message2sign = getMessage2Sign(data);
    final publicKey = await ownerWallet.getTezosPublicKey(index: addressIndex!);
    final signature = await _tezosService.signMessage(
        ownerWallet, addressIndex, Uint8List.fromList(message2sign));
    final body = {
      'address': asset.owner,
      'contractAddress': asset.contractAddress,
      'signature': signature,
      'publicKey': publicKey,
      'counter': counter,
    };
    try {
      final response = await _postcardApi.share(tokenId, body);

      final deeplink = response['deeplink'];
      return SharePostcardResponse(deeplink: deeplink);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AssetToken> getPostcard(String tokenId) async {
    final request = QueryListTokensRequest(
      ids: [tokenId],
    );
    final assets = await _indexerService.getNftTokens(request);
    log.info('getPostcard assets: ${assets.first.asset?.artworkMetadata}');
    return assets.first;
  }

  @override
  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode) async {
    try {
      final response = await _postcardApi.claimShareCode(shareCode);
      response['shareCode'] = shareCode;
      final sharedPostcardInfor = SharedPostcardInfor.fromJson(response);
      return sharedPostcardInfor;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool?> stampPostcard(
      String tokenId,
      WalletStorage wallet,
      int index,
      File image,
      File metadata,
      Location? location,
      int counter,
      String contractAddress) async {
    try {
      final data = [
        TezosPack.packAddress(contractAddress),
        TezosPack.packInteger(int.parse(tokenId)),
        TezosPack.packInteger(counter)
      ].toList();

      final message2sign = getMessage2Sign(data);

      final signature = await _tezosService.signMessage(
          wallet, index, Uint8List.fromList(message2sign));
      final address = await wallet.getTezosAddress(index: index);
      final publicKey = await wallet.getTezosPublicKey(index: index);
      final lat = location?.lat;
      final lon = location?.lon;
      log.info('''
        stampPostcard tokenId: $tokenId, address: $address, 
         lat: $lat, lon: $lon, counter: $counter
        ''');
      final result = await _postcardApi.updatePostcard(
          tokenId: tokenId,
          data: image,
          metadata: metadata,
          signature: signature,
          address: address,
          publicKey: publicKey,
          lat: lat,
          lon: lon,
          counter: counter) as Map<String, dynamic>;

      final ok = result['metadataCID'] as String;
      final isStampSuccess = ok.isNotEmpty;
      if (isStampSuccess) {
        _metricClientService.addEvent(MixpanelEvent.postcardStamp, data: {
          'postcardId': tokenId,
          'index': counter,
        });
        if (counter == MAX_STAMP_IN_POSTCARD) {
          try {
            _chatService.sendPostcardCompleteMessage(
              address,
              getTokenId(tokenId),
              Pair(wallet, index),
            );
          } catch (e) {
            log.info('[Postcard Service] sendPostcardCompleteMessage $e');
          }
        }
      }
      return isStampSuccess;
    } catch (e) {
      if (e is DioException) {
        final isAlreadyStamped = e.isPostcardAlreadyStamped;
        if (isAlreadyStamped) {
          return null;
        }
      }
      return false;
    }
  }

  @override
  List<StampingPostcard> getStampingPostcard() {
    return _configurationService.getStampingPostcard();
  }

  @override
  Future<void> updateStampingPostcard(List<StampingPostcard> values,
      {bool override = false, bool isRemove = false}) async {
    await _configurationService.updateStampingPostcard(values,
        override: override, isRemove: isRemove);
    if (isRemove) {
      Future.delayed(const Duration(seconds: 2), () async {
        for (var element in values) {
          final imageFile = File(element.imagePath);
          if (await imageFile.exists()) {
            imageFile.deleteSync();
          }
          final metadataFile = File(element.metadataPath);
          if (await metadataFile.exists()) {
            metadataFile.deleteSync();
          }
        }
      });
    }
  }

  List<int> getMessage2Sign(List<Uint8List> data) {
    final prefix = utf8.encode(POSTCARD_SIGN_PREFIX);
    final sep = utf8.encode('|');
    final lst = data.mapIndexed((index, e) {
      if (index == data.length - 1) {
        return e;
      }
      return e.toList()..addAll(sep);
    }).toList();

    final message2sign = prefix.toList()
      ..addAll(
        lst.reduce(
          (value, element) {
            return value + element;
          },
        ),
      );
    return message2sign;
  }

  @override
  StampingPostcard? getStampingPostcardWithPath(
      StampingPostcard stampingPostcard) {
    final stampingPostcards = getStampingPostcard();
    return stampingPostcards
        .firstWhereOrNull((element) => element == stampingPostcard);
  }

  @override
  Future<RequestPostcardResponse> requestPostcard(
          RequestPostcardRequest request) async =>
      await _postcardApi.request(request);

  @override
  Future<void> cancelSharePostcard(AssetToken asset) async {
    await sharePostcard(asset);
  }

  @override
  Future<PostcardLeaderboard> fetchPostcardLeaderboard(
      {required String unit, required int size, required int offset}) async {
    final leaderboardResponse =
        await _postcardApi.getLeaderboard(unit, size, offset);
    final ids = leaderboardResponse.items
        .map((e) => 'tez-${Environment.postcardContractAddress}-${e.id}')
        .toList();
    final request = QueryListTokensRequest(ids: ids, size: ids.length);
    final tokens = await _indexerService.getNftTokens(request);
    leaderboardResponse.items.map((e) {
      final token =
          tokens.firstWhereOrNull((element) => element.tokenId == e.id);
      if (token == null) {
        return e;
      }
      e
        ..title = token.title ?? 'unknown'.tr()
        ..creators =
            token.getArtists.map((e) => e.id).toList().whereNotNull().toList()
        ..rank = e.rank + offset;
      return e;
    }).toList();

    return PostcardLeaderboard(
        items: leaderboardResponse.items, lastUpdated: DateTime.now());
  }

  Future<File> _downloadStamp({
    required String tokenId,
    required int stampIndex,
  }) async {
    final tempFilePath =
        '${(await getTemporaryDirectory()).path}/Postcard/$tokenId/$stampIndex.png';
    final tempFile = File(tempFilePath);
    final isFileExist = await tempFile.exists();
    if (!isFileExist) {
      final path = '/v1/postcard/$tokenId/stamp/$stampIndex/download';
      final secretKey = Environment.auClaimSecretKey;
      final response = await HttpHelper.hmacAuthenticationGet(
        host: Environment.auClaimAPIURL,
        path: path,
        secretKey: secretKey,
      );
      if (response.statusCode != StatusCode.success.value) {
        throw Exception(response.reasonPhrase);
      }
      final bodyByte = response.bodyBytes;
      await tempFile.create(recursive: true);
      log.info('Created file $tempFilePath');
      await tempFile.writeAsBytes(bodyByte);
    }
    return tempFile;
  }

  Future<File> _downloadPostcard(String tokenId) async {
    final tempFilePath =
        '${(await getTemporaryDirectory()).path}/Postcard/$tokenId/postcard.png';
    final tempFile = File(tempFilePath);
    final isFileExist = await tempFile.exists();

    final path = '/v1/postcard/$tokenId/download';
    final secretKey = Environment.auClaimSecretKey;
    final response = await HttpHelper.hmacAuthenticationGet(
      host: Environment.auClaimAPIURL,
      path: path,
      secretKey: secretKey,
    );
    if (response.statusCode != StatusCode.success.value) {
      throw Exception(response.reasonPhrase);
    }
    final bodyByte = response.bodyBytes;
    if (!isFileExist) {
      await tempFile.create(recursive: true);
    }
    log.info('Created file $tempFilePath');
    await tempFile.writeAsBytes(bodyByte);
    log.info('Write file $tempFilePath');

    return tempFile;
  }

  @override
  Future<void> downloadStamp({
    required String tokenId,
    required int stampIndex,
    bool isOverride = false,
  }) async {
    log.info('[Postcard Service] download stamp $tokenId $stampIndex');
    final imageFile =
        await _downloadStamp(tokenId: tokenId, stampIndex: stampIndex);
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final imageName = 'postcard-$tokenId-$stampIndex-$timestamp.png';
    final isSuccess =
        await FileHelper.saveFileToGallery(imageFile.path, imageName);
    if (!isSuccess) {
      throw MediaPermissionException('Permission is not granted');
    }
  }

  @override
  Future<void> downloadPostcard(String tokenId) async {
    log.info('[Postcard Service] download postcard $tokenId');
    final imageFile = await _downloadPostcard(tokenId);
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final imageName = 'postcard-$tokenId-$timestamp.png';
    final isSuccess =
        await FileHelper.saveFileToGallery(imageFile.path, imageName);
    if (!isSuccess) {
      throw MediaPermissionException('Permission is not granted');
    }
    await imageFile.delete();
  }

  @override
  String getTokenId(String id) =>
      'tez-${Environment.postcardContractAddress}-$id';

  @override
  Future<AssetToken> claimEmptyPostcardToAddress(
      {required String address,
      required RequestPostcardResponse requestPostcardResponse}) async {
    final tezosService = injector.get<TezosService>();
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final account = await _accountService.getAccountByAddress(
      chain: 'tezos',
      address: address,
    );
    final signature = await tezosService.signMessage(account.wallet,
        account.index, Uint8List.fromList(utf8.encode(timestamp)));
    final publicKey =
        await account.wallet.getTezosPublicKey(index: account.index);
    final claimRequest = ClaimPostCardRequest(
      address: address,
      claimID: requestPostcardResponse.claimID,
      timestamp: timestamp,
      publicKey: publicKey,
      signature: signature,
      location: [moMAGeoLocation.position.lat, moMAGeoLocation.position.lon],
    );
    final result = await claimEmptyPostcard(claimRequest);
    _metricClientService.addEvent(MixpanelEvent.postcardClaimEmpty, data: {
      'postcardId': result.tokenID,
    });
    final tokenID = 'tez-${result.contractAddress}-${result.tokenID}';
    final postcardMetadata = PostcardMetadata(
      locationInformation: [],
    );
    final token = AssetToken(
      asset: Asset.init(
        indexID: tokenID,
        artistName: 'MoMa',
        maxEdition: 1,
        mimeType: 'image/png',
        title: requestPostcardResponse.name,
        previewURL: requestPostcardResponse.previewURL,
        source: 'postcard',
        artworkMetadata: jsonEncode(postcardMetadata.toJson()),
        medium: 'software',
      ),
      blockchain: 'tezos',
      fungible: true,
      contractType: 'fa2',
      tokenId: result.tokenID,
      contractAddress: result.contractAddress,
      edition: 0,
      editionName: '',
      id: tokenID,
      balance: 1,
      owner: address,
      lastActivityTime: DateTime.now(),
      lastRefreshedTime: DateTime(1),
      pending: true,
      originTokenInfo: [],
      provenance: [],
      owners: {
        address: 1,
      },
    );

    await _tokensService.setCustomTokens([token]);
    _tokensService.reindexAddresses([address]);
    injector.get<ConfigurationService>().setListPostcardMint([tokenID]);
    NftCollectionBloc.eventController.add(
      GetTokensByOwnerEvent(pageKey: PageKey.init()),
    );
    return token;
  }

  @override
  Future<AssetToken> claimSharedPostcardToAddress(
      {required String address,
      required AssetToken assetToken,
      required String shareCode,
      required Location location}) async {
    await receivePostcard(
      shareCode: shareCode,
      location: location,
      address: address,
    );
    var postcardMetadata = assetToken.postcardMetadata;
    log.info(
        'claimSharedPostcardToAddress metadata ${postcardMetadata.toJson()}');
    var newAsset = assetToken.asset;
    newAsset?.artworkMetadata = jsonEncode(postcardMetadata.toJson());
    newAsset?.maxEdition = newAsset.maxEdition! + 1;
    final newOwners = assetToken.owners..addEntries([MapEntry(address, 1)]);
    final pendingToken = assetToken.copyWith(
      owner: address,
      asset: newAsset,
      balance: 1,
      owners: newOwners,
    );

    final tokenService = injector<TokensService>();
    await tokenService.setCustomTokens([pendingToken]);
    tokenService.reindexAddresses([address]);
    NftCollectionBloc.eventController.add(
      GetTokensByOwnerEvent(pageKey: PageKey.init()),
    );
    return pendingToken;
  }

  @override
  Future<bool> finalizeStamp(AssetToken asset, String imagePath,
      String metadataPath, Location location) async {
    File imageFile = File(imagePath);
    File metadataFile = File(metadataPath);

    final tokenId = asset.tokenId ?? '';
    final address = asset.owner;
    final counter = asset.numberOwners;
    final contractAddress = Environment.postcardContractAddress;

    final walletIndex = await asset.getOwnerWallet();
    if (walletIndex == null) {
      log.info('[POSTCARD] Wallet index not found. address: $address');
      return false;
    }
    final processingStampPostcard = asset.processingStampPostcard ??
        ProcessingStampPostcard(
          indexId: tokenId,
          address: address,
          imagePath: imagePath,
          metadataPath: metadataPath,
          counter: counter,
          timestamp: DateTime.now(),
          location: location,
        );
    await _configurationService.setProcessingStampPostcard([
      processingStampPostcard,
    ]);
    final isStampSuccess = await stampPostcard(
      tokenId,
      walletIndex.first,
      walletIndex.second,
      imageFile,
      metadataFile,
      location,
      counter,
      contractAddress,
    );
    if (isStampSuccess != false) {
      await _configurationService.setProcessingStampPostcard(
        [processingStampPostcard],
        isRemove: true,
      );

      await updateStampingPostcard([
        StampingPostcard(
          indexId: asset.id,
          address: address,
          imagePath: imagePath,
          metadataPath: metadataPath,
          counter: counter,
        ),
      ]);
      final postcardMetadata = asset.postcardMetadata;
      final stampedLocation = location;
      postcardMetadata.locationInformation.add(stampedLocation);
      final newAsset = asset.asset;
      newAsset?.artworkMetadata = jsonEncode(postcardMetadata.toJson());
      final pendingToken = asset.copyWith(asset: newAsset);
      await _tokensService.setCustomTokens([pendingToken]);
      _tokensService.reindexAddresses([address]);
      NftCollectionBloc.eventController.add(
        GetTokensByOwnerEvent(pageKey: PageKey.init()),
      );
    }
    return isStampSuccess != false;
  }
}

enum DistanceUnit {
  km,
  mile;

  String get name {
    switch (this) {
      case DistanceUnit.km:
        return 'km';
      case DistanceUnit.mile:
        return 'mile';
    }
  }
}

class PostcardException implements Exception {
  final String message;

  PostcardException(this.message);
}

class MediaPermissionException extends PostcardException {
  MediaPermissionException(super.message);
}
