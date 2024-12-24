import 'dart:async';
import 'dart:math';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';
import 'package:nft_collection/data/api/tzkt_api.dart';
import 'package:nft_collection/database/dao/dao.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/models/pending_tx_params.dart';
import 'package:nft_collection/models/tzkt_operation.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:web3dart/web3dart.dart';

const _erc1155Topic =
    '0XC3D58168C5AE7397731D063D5BBF3D657854427343F4C083240F7AACAA2D0F62';
const _erc721Topic =
    '0XDDF252AD1BE2C89B69C2B068FC378DAA952BA7F163C4A11628F55A4DF523B3EF';

const _maxRetries = 5;

const _ethContractBlackList = [
  '0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85',
];

const _tezosContractBlacklist = [
  'KT1C9X9s5rpVJGxwVuHEVBLYEdAQ1Qw8QDjH', // TezDAO
  'KT1GBZmSxmnKJXGMdMLbugPfLyUPmuLSMwKS', // Tezos Domains NameRegistry
  'KT1A5P4ejnLix13jtadsfV9GCnXLMNnab8UT', // KALAM
  'KT1AFA2mwNUMNd4SsujE1YYp29vd8BZejyKW', // Hic et nunc DAO
];

extension FilterEventExt on FilterEvent {
  bool isERC721() => topics?.firstOrNull?.toUpperCase() == _erc721Topic;

  bool isErc1155() => topics?.firstOrNull?.toUpperCase() == _erc1155Topic;

  BigInt? getERC721TokenId() {
    if (topics?.length == 4) {
      return BigInt.tryParse(
        topics?.last?.replacePrefix('0x', '') ?? '',
        radix: 16,
      );
    } else {
      return null;
    }
  }

  BigInt? getERC1155TokenId() {
    final tokenId = data?.replaceFirst('0x', '').substring(0, 64);
    return BigInt.tryParse(tokenId ?? '', radix: 16);
  }

  AssetToken? toAssetToken(String owner, DateTime timestamp) {
    String? contractType;
    String? toAddressStr;
    BigInt? tokenId;

    if (isErc1155()) {
      contractType = 'erc1155';
      tokenId = getERC1155TokenId();
      toAddressStr = topics![3]?.substring(26);
    } else if (isERC721()) {
      contractType = 'erc721';
      tokenId = getERC721TokenId();
      toAddressStr = topics![2]?.substring(26);
    }

    if (toAddressStr == null) {
      return null;
    }
    if (owner.toLowerCase() != '0x$toAddressStr'.toLowerCase()) {
      return null;
    }

    if (contractType != null && tokenId != null) {
      final indexerId = 'eth-${address?.hexEip55}-$tokenId';
      final token = AssetToken(
        asset: Asset.init(
          indexID: indexerId,
          maxEdition: 1,
          source: address?.hexEip55,
        ),
        blockchain: 'ethereum',
        fungible: false,
        contractType: contractType,
        tokenId: '$tokenId',
        contractAddress: address?.hexEip55 ?? '',
        edition: 0,
        editionName: '',
        id: indexerId,
        owner: owner,
        balance: 1,
        owners: {
          owner: 1,
        },
        lastActivityTime: timestamp,
        lastRefreshedTime: DateTime(1),
        pending: true,
        originTokenInfo: [],
        provenance: [],
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
  ) =>
      AssetToken(
        asset: Asset.init(
          indexID: 'tzkt-${contract?.address}-$tokenId',
          artistName: (metadata?['creators'] as List<dynamic>?)
              ?.cast<String>()
              .firstOrNull,
          maxEdition: 1,
          mimeType: metadata?['formats']?[0]?['mimeType'] as String?,
          source: contract?.address,
          title: metadata?['name'] as String? ?? '',
        ),
        blockchain: 'tezos',
        fungible: false,
        contractType: standard ?? '',
        tokenId: tokenId,
        contractAddress: contract?.address,
        edition: 0,
        editionName: '',
        id: 'tez-${contract?.address}-$tokenId',
        balance: 1,
        owner: owner,
        owners: {
          owner: 1,
        },
        lastActivityTime: timestamp,
        lastRefreshedTime: DateTime(1),
        pending: true,
        originTokenInfo: [],
        provenance: [],
      );
}

class PendingTokenService {
  PendingTokenService(
    this._tzktApi,
    this._web3Client,
    this._tokenService,
    this._assetTokenDao,
    this._tokenDao,
    this._assetDao,
  );

  final TZKTApi _tzktApi;
  final Web3Client _web3Client;
  final TokensService _tokenService;
  final AssetTokenDao _assetTokenDao;
  final TokenDao _tokenDao;
  final AssetDao _assetDao;

  Future<List<AssetToken>> checkPendingEthereumTokens(
    String owner,
    String tx,
    String timestamp,
    String signature,
  ) async {
    log.info(
      '[PendingTokenService] Check pending Ethereum tokens: $owner, $tx',
    );
    var retryCount = 0;
    TransactionReceipt? receipt;
    do {
      await Future.delayed(_getRetryDelayDuration(retryCount));
      receipt = await _web3Client.getTransactionReceipt(tx);
      log.info('[PendingTokenService] Receipt: $receipt');
      if (receipt != null) {
        break;
      } else {
        retryCount++;
      }
    } while (receipt == null && retryCount < _maxRetries);
    if (receipt != null) {
      final pendingTokens = receipt.logs
          .where((log) => !_ethContractBlackList.contains(log.address?.hex))
          .map((e) => e.toAssetToken(owner, DateTime.now()))
          .where((element) => element != null)
          .map((e) => e!)
          .toList();
      log.info('[PendingTokenService] Pending Tokens:'
          ' ${pendingTokens.map((e) => e.id).toList()}');
      if (pendingTokens.isNotEmpty) {
        for (final e in pendingTokens) {
          final element = PendingTxParams(
            blockchain: e.blockchain,
            id: e.tokenId ?? '',
            contractAddress: e.contractAddress ?? '',
            ownerAccount: e.owner,
            pendingTx: tx,
            timestamp: timestamp,
            signature: signature,
          );
          unawaited(injector<TokensService>().postPendingToken(element));
        }

        await _tokenService.setCustomTokens(pendingTokens);
        await _tokenService.reindexAddresses([owner]);
      }

      final localPendingToken =
          (await _assetTokenDao.findAllPendingAssetTokens())
              .where((e) => e.owner == owner)
              .whereNot((e) => e.isAirdrop)
              .toList();

      return localPendingToken;
    } else {
      return [];
    }
  }

  Future<List<AssetToken>> checkPendingTezosTokens(
    String owner, {
    int? maxRetries,
  }) async {
    if (Environment.appTestnetConfig) {
      return [];
    }
    log.info('[PendingTokenService] Check pending Tezos tokens: $owner');
    var retryCount = 0;
    final pendingTokens = List<AssetToken>.empty(growable: true);
    final ownedTokenIds = await getTokenIDs(owner);

    do {
      await Future.delayed(_getRetryDelayDuration(retryCount));
      final operations = await _tzktApi.getTokenTransfer(
        anyOf: owner,
        sort: 'timestamp',
        limit: 5,
        lastTime: DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
      );
      final transfers = <TZKTTokenTransfer>[];
      for (final operation in operations.reversed) {
        if (operation.to?.address == owner) {
          transfers.add(operation);
        } else if (operation.from?.address == owner) {
          transfers.removeWhere(
            (e) =>
                e.token?.tokenId == operation.token?.tokenId &&
                e.token?.contract?.address ==
                    operation.token?.contract?.address,
          );
        }
      }
      final tokens = transfers
          .where(
            (e) =>
                !_tezosContractBlacklist.contains(e.token?.contract?.address),
          )
          .map((e) => e.token?.toAssetToken(owner, DateTime.now()))
          .where((e) => e != null)
          .map((e) => e!)
          .toList();

      // Check if pending tokens are transferred out,
      // then remove from local database.
      final currentPendingTokens =
          (await _assetTokenDao.findAllPendingAssetTokens())
              .where((e) => e.owner == owner)
              .whereNot((e) => e.isAirdrop);
      final removedPending = currentPendingTokens.where(
        (e) => tokens.firstWhereOrNull((element) => e.id == element.id) == null,
      );
      log.info('[PendingTokenService] Delete transferred out pending tokens: '
          '${removedPending.map((e) => e.id).toList()}');
      for (final token in removedPending) {
        if (token.asset?.indexID != null) {
          await _assetDao.deleteAssetByIndexID(token.asset!.indexID!);
        }
        await _tokenDao.deleteTokenByID(token.id);
      }

      final newTokens =
          tokens.where((e) => !ownedTokenIds.contains(e.id)).toList();
      pendingTokens.addAll(newTokens);
      if (pendingTokens.isNotEmpty) {
        log
          ..info(
            '[PendingTokenService] Found ${pendingTokens.length} new tokens.',
          )
          ..info('[PendingTokenService] Pending IDs: '
              '${pendingTokens.map((e) => e.id).toList()}');
        break;
      } else {
        log.info('[PendingTokenService] Not found any new tokens.');
        retryCount++;
      }
    } while (pendingTokens.isEmpty && retryCount < (maxRetries ?? _maxRetries));

    if (pendingTokens.isNotEmpty) {
      await _tokenService.setCustomTokens(pendingTokens);
      await _tokenService.reindexAddresses([owner]);
    }
    final localPendingToken = (await _assetTokenDao.findAllPendingAssetTokens())
        .where((e) => e.owner == owner)
        .whereNot((e) => e.isAirdrop)
        .toList();
    return localPendingToken;
  }

  Future<List<String>> getTokenIDs(String owner) async =>
      _assetTokenDao.findAllAssetTokenIDsByOwner(owner);

  Duration _getRetryDelayDuration(int n) {
    final delayMs = min(60 * 1000, 5000 * pow(2, n));
    return Duration(milliseconds: delayMs.toInt());
  }
}
