import 'dart:math';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:web3dart/web3dart.dart';

const _erc1155Topic =
    "0XC3D58168C5AE7397731D063D5BBF3D657854427343F4C083240F7AACAA2D0F62";
const _erc721Topic =
    "0XDDF252AD1BE2C89B69C2B068FC378DAA952BA7F163C4A11628F55A4DF523B3EF";

const _maxRetries = 5;

const _ethContractBlackList = [
  "0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85",
];

const _tezosContractBlacklist = [
  "KT1C9X9s5rpVJGxwVuHEVBLYEdAQ1Qw8QDjH", // TezDAO
  "KT1GBZmSxmnKJXGMdMLbugPfLyUPmuLSMwKS", // Tezos Domains NameRegistry
  "KT1A5P4ejnLix13jtadsfV9GCnXLMNnab8UT", // KALAM
  "KT1AFA2mwNUMNd4SsujE1YYp29vd8BZejyKW", // Hic et nunc DAO
];

extension FilterEventExt on FilterEvent {
  bool isERC721() {
    return topics?.firstOrNull?.toUpperCase() == _erc721Topic;
  }

  bool isErc1155() {
    return topics?.firstOrNull?.toUpperCase() == _erc1155Topic;
  }

  BigInt? getERC721TokenId() {
    if (topics?.length == 4) {
      return BigInt.tryParse(
        topics?.last.replacePrefix("0x", "") ?? "",
        radix: 16,
      );
    } else {
      return null;
    }
  }

  BigInt? getERC1155TokenId() {
    final tokenId = data?.replaceFirst("0x", "").substring(0, 64);
    return BigInt.tryParse(tokenId ?? "", radix: 16);
  }

  AssetToken? toAssetToken(String owner, DateTime timestamp) {
    String? contractType;
    BigInt? tokenId;

    if (isErc1155()) {
      contractType = "erc1155";
      tokenId = getERC1155TokenId();
    } else if (isERC721()) {
      contractType = "erc721";
      tokenId = getERC721TokenId();
    }

    if (contractType != null && tokenId != null) {
      final indexerId = "eth-${address?.hexEip55}-$tokenId";
      final token = AssetToken(
        artistName: null,
        artistURL: null,
        artistID: null,
        assetData: null,
        assetID: null,
        assetURL: null,
        basePrice: null,
        baseCurrency: null,
        blockchain: "ethereum",
        blockchainUrl: null,
        fungible: false,
        contractType: contractType,
        tokenId: "$tokenId",
        contractAddress: address?.hexEip55 ?? "",
        desc: null,
        edition: 0,
        editionName: "",
        id: indexerId,
        maxEdition: 1,
        medium: null,
        mimeType: null,
        mintedAt: null,
        previewURL: null,
        source: address?.hexEip55,
        sourceURL: null,
        thumbnailID: null,
        thumbnailURL: null,
        galleryThumbnailURL: null,
        title: "",
        ownerAddress: owner,
        balance: 0,
        owners: {
          owner: 1,
        },
        lastActivityTime: timestamp,
        pending: true,
        initialSaleModel: null,
        originTokenInfoId: null,
      );
      return token;
    }
    return null;
  }
}

extension TZKTTokenExtension on TZKTToken {
  AssetToken toAssetToken(
    String owner,
    DateTime timestamp,
  ) {
    return AssetToken(
      artistName:
          (metadata?["creators"] as List<dynamic>?)?.cast<String>().firstOrNull,
      artistURL: null,
      artistID: null,
      assetData: null,
      assetID: null,
      assetURL: null,
      basePrice: null,
      baseCurrency: null,
      blockchain: "tezos",
      blockchainUrl: null,
      fungible: false,
      contractType: standard,
      tokenId: tokenId,
      contractAddress: contract?.address,
      desc: null,
      edition: 0,
      editionName: "",
      id: "tez-${contract?.address}-$tokenId",
      maxEdition: 1,
      medium: null,
      mimeType: metadata?["formats"]?[0]?["mimeType"],
      mintedAt: null,
      previewURL: null,
      source: contract?.address,
      sourceURL: null,
      thumbnailID: null,
      thumbnailURL: null,
      galleryThumbnailURL: null,
      title: metadata?["name"] ?? "",
      balance: 0,
      ownerAddress: owner,
      owners: {
        owner: 1,
      },
      lastActivityTime: timestamp,
      pending: true,
      initialSaleModel: null,
      originTokenInfoId: null,
    );
  }
}

class PendingTokenService {
  final TZKTApi _tzktApi;
  final Web3Client _web3Client;
  final TokensService _tokenService;
  final AssetTokenDao _assetTokenDao;

  PendingTokenService(
    this._tzktApi,
    this._web3Client,
    this._tokenService,
    this._assetTokenDao,
  );

  Future<bool> checkPendingEthereumTokens(String owner, String tx) async {
    log.info(
        "[PendingTokenService] Check pending Ethereum tokens: $owner, $tx");
    int retryCount = 0;
    TransactionReceipt? receipt;
    do {
      await Future.delayed(_getRetryDelayDuration(retryCount));
      receipt = await _web3Client.getTransactionReceipt(tx);
      log.info("[PendingTokenService] Receipt: $receipt");
      if (receipt != null) {
        break;
      } else {
        retryCount++;
      }
    } while ((receipt == null && retryCount < _maxRetries));
    if (receipt != null) {
      final pendingTokens = receipt.logs
          .where((log) => !_ethContractBlackList.contains(log.address?.hex))
          .map((e) => e.toAssetToken(owner, DateTime.now()))
          .where((element) => element != null)
          .map((e) => e as AssetToken)
          .toList();
      log.info(
          "[PendingTokenService] Pending Tokens: ${pendingTokens.map((e) => e.id).toList()}");
      if (pendingTokens.isNotEmpty) {
        await _tokenService.setCustomTokens(pendingTokens);
        await _tokenService.reindexAddresses([owner]);
      }
      return pendingTokens.isNotEmpty;
    } else {
      return false;
    }
  }

  Future<bool> checkPendingTezosTokens(String owner, {int? maxRetries}) async {
    if (Environment.appTestnetConfig) return false;
    log.info("[PendingTokenService] Check pending Tezos tokens: $owner");
    int retryCount = 0;
    final pendingTokens = List<AssetToken>.empty(growable: true);
    final ownedTokenIds = await getTokenIDs(owner);

    do {
      await Future.delayed(_getRetryDelayDuration(retryCount));
      final operations = await _tzktApi.getTokenTransfer(
        anyOf: owner,
        sort: "timestamp",
        limit: 5,
        lastTime:
            DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      );
      final transfers = <TZKTTokenTransfer>[];
      for (final operation in operations.reversed) {
        if (operation.to?.address == owner) {
          transfers.add(operation);
        } else if (operation.from?.address == owner) {
          transfers.removeWhere((e) =>
              e.token?.tokenId == operation.token?.tokenId &&
              e.token?.contract?.address == operation.token?.contract?.address);
        }
      }
      final tokens = transfers
          .where((e) =>
              !_tezosContractBlacklist.contains(e.token?.contract?.address))
          .map((e) => e.token?.toAssetToken(owner, DateTime.now()))
          .where((e) => e != null)
          .map((e) => e as AssetToken)
          .toList();

      // Check if pending tokens are transferred out, then remove from local database.
      final currentPendingTokens = (await _assetTokenDao.findAllPendingTokens())
          .where((e) => e.ownerAddress == owner)
          .whereNot((e) => e.isAirdrop);
      final removedPending = currentPendingTokens.where((e) =>
          tokens.firstWhereOrNull((element) => e.id == element.id) == null);
      log.info("[PendingTokenService] Delete transferred out pending tokens: "
          "${removedPending.map((e) => e.id).toList()}");
      for (AssetToken token in removedPending) {
        await _assetTokenDao.deleteAsset(token);
      }

      final newTokens =
          tokens.where((e) => !ownedTokenIds.contains(e.id)).toList();
      pendingTokens.addAll(newTokens);
      if (pendingTokens.isNotEmpty) {
        log.info(
            "[PendingTokenService] Found ${pendingTokens.length} new tokens.");
        log.info(
            "[PendingTokenService] Pending IDs: ${pendingTokens.map((e) => e.id).toList()}");
        break;
      } else {
        log.info("[PendingTokenService] Not found any new tokens.");
        retryCount++;
      }
    } while (pendingTokens.isEmpty && retryCount < (maxRetries ?? _maxRetries));

    if (pendingTokens.isNotEmpty) {
      await _tokenService.setCustomTokens(pendingTokens);
      await _tokenService.reindexAddresses([owner]);
    }
    return pendingTokens.isNotEmpty;
  }

  Future<List<String>> getTokenIDs(String owner) async {
    return _assetTokenDao.findAllAssetTokenIDsByOwner(owner);
  }

  Duration _getRetryDelayDuration(int n) {
    final delayMs = min(60 * 1000, 5000 * pow(2, n));
    return Duration(milliseconds: delayMs.toInt());
  }
}
