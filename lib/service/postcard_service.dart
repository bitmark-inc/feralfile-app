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
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/model/postcard_bigmap.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/request_response.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/notification_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:collection/collection.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';

import 'account_service.dart';

abstract class PostcardService {
  Future<ReceivePostcardResponse> receivePostcard(
      {required String shareCode,
      required Location location,
      required String address});

  Future<ClaimPostCardResponse> claimEmptyPostcard(
      ClaimPostCardRequest request);

  Future<RequestPostcardResponse> requestPostcard(
      RequestPostcardRequest request);

  Future<SharePostcardResponse> sharePostcard(AssetToken asset);

  Future<void> cancelSharePostcard(AssetToken asset);

  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode);

  Future<AssetToken> getPostcard(String tokenId);

  Future<bool> stampPostcard(
      String tokenId,
      WalletStorage wallet,
      int index,
      File image,
      File metadata,
      Location? location,
      int counter,
      String contractAddress);

  Future<bool> isReceivedSuccess(
      {required contractAddress,
      required String address,
      required String tokenId,
      required int counter});

  Future<PostcardValue?> getPostcardValue({
    required contractAddress,
    required String tokenId,
  });

  List<StampingPostcard> getStampingPostcard();

  StampingPostcard? getStampingPostcardWithPath(
      StampingPostcard stampingPostcard);

  Future<void> updateStampingPostcard(List<StampingPostcard> values,
      {bool override = false, bool isRemove = false});

  Future<void> checkNotification();

  Future<PostcardLeaderboard> fetchPostcardLeaderboard();
}

class PostcardServiceImpl extends PostcardService {
  final PostcardApi _postcardApi;
  final TezosService _tezosService;
  final IndexerService _indexerService;
  final TZKTApi _tzktApi;
  final ConfigurationService _configurationService;
  final NotificationService _notificationService;

  PostcardServiceImpl(
      this._postcardApi,
      this._tezosService,
      this._indexerService,
      this._tzktApi,
      this._notificationService,
      this._configurationService);

  @override
  Future<ClaimPostCardResponse> claimEmptyPostcard(
      ClaimPostCardRequest request) async {
    return _postcardApi.claim(request);
  }

  @override
  Future<ReceivePostcardResponse> receivePostcard({
    required String shareCode,
    required Location location,
    required String address,
  }) async {
    try {
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final accountService = injector<AccountService>();
      final walletIndex = await accountService.getAccountByAddress(
          chain: "tezos", address: address);
      final publicKey =
          await walletIndex.wallet.getTezosPublicKey(index: walletIndex.index);
      final signature = await _tezosService.signMessage(walletIndex.wallet,
          walletIndex.index, Uint8List.fromList(utf8.encode(timestamp)));
      final body = {
        "shareCode": shareCode,
        "location": [location.lat, location.lon],
        "address": address,
        "publicKey": publicKey,
        "signature": signature,
        "timestamp": timestamp,
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
      throw Exception("Owner wallet is null");
    }
    final counter = asset.postcardMetadata.counter;
    final contractAddress = asset.contractAddress ?? '';
    final tokenId = asset.tokenId ?? '';
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
      "address": asset.owner,
      "contractAddress": asset.contractAddress,
      "signature": signature,
      "publicKey": publicKey,
      "counter": counter,
    };
    try {
      final response = await _postcardApi.share(tokenId, body);

      final deeplink = response["deeplink"];
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
    return assets.first;
  }

  @override
  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode) async {
    try {
      final response = await _postcardApi.claimShareCode(shareCode);
      response["shareCode"] = shareCode;
      final sharedPostcardInfor = SharedPostcardInfor.fromJson(response);
      return sharedPostcardInfor;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> stampPostcard(
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

      final ok = result["metadataCID"] as String;
      return ok.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isReceivedSuccess(
      {required contractAddress,
      required String address,
      required String tokenId,
      required int counter}) async {
    final postcardData = await getPostcardValue(
        contractAddress: contractAddress, tokenId: tokenId);
    if (postcardData == null) return false;
    if (postcardData.counter == counter && postcardData.postman == address) {
      return true;
    }
    return false;
  }

  @override
  Future<PostcardValue?> getPostcardValue({
    required contractAddress,
    required String tokenId,
  }) async {
    final ptr = await _tzktApi.getBigMapsId(contract: contractAddress);
    if (ptr.isEmpty) return null;
    final bigMapId = ptr.first;
    final result = await _tzktApi.getBigMaps(bigMapId, key: tokenId);
    if (result.isEmpty) return null;
    return result.first;
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
    final sep = utf8.encode("|");
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
      RequestPostcardRequest request) async {
    return await _postcardApi.request(request);
  }

  @override
  Future<void> checkNotification() async {
    final expiredPostcardShareLink =
        await _configurationService.getSharedPostcard().expiredPostcards;
    if (_configurationService.isNotificationEnabled() ?? false) {
      Timer.periodic(const Duration(seconds: 1), (timer) async {
        final index = timer.tick - 1;
        if (index >= expiredPostcardShareLink.length) {
          timer.cancel();
        } else {
          final expiredPostcard = expiredPostcardShareLink[index];
          await _notificationService.showPostcardWasnotDeliveredNotification(
              PostcardIdentity(
                  id: expiredPostcard.tokenID, owner: expiredPostcard.owner));
          await _configurationService
              .updateSharedPostcard([expiredPostcard], isRemoved: true);
        }
      });
      _configurationService.expiredPostcardSharedLinkTip.value = [];
    } else {
      _configurationService.expiredPostcardSharedLinkTip.value =
          expiredPostcardShareLink;
    }
  }

  @override
  Future<void> cancelSharePostcard(AssetToken asset) async {
    await sharePostcard(asset);
  }

  @override
  Future<PostcardLeaderboard> fetchPostcardLeaderboard() async {
    final leaderboardResponse = await _postcardApi
        .getLeaderboard(DistanceFormatter.getDistanceUnit.name);
    final ids = leaderboardResponse.items
        .map((e) => 'tez-${Environment.postcardContractAddress}-${e.id}')
        .toList();
    final request = QueryListTokensRequest(
      ids: ids,
    );
    final tokens = await _indexerService.getNftTokens(request);
    leaderboardResponse.items.map((e) {
      e.title = tokens
              .firstWhereOrNull((element) => element.tokenId == e.id)
              ?.title ??
          "Unknown";
      return e;
    }).toList();

    return PostcardLeaderboard(
        items: leaderboardResponse.items, lastUpdated: DateTime.now());
  }
}

enum DistanceUnit {
  km,
  mile;

  String get name {
    switch (this) {
      case DistanceUnit.km:
        return "km";
      case DistanceUnit.mile:
        return "mile";
    }
  }
}
