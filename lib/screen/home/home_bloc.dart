//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/database/dao/provenance_dao.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/gateway/indexer_api.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:autonomy_flutter/util/log.dart';

class HomeBloc extends AuBloc<HomeEvent, HomeState> {
  TokensService _tokensService;
  WalletConnectService _walletConnectService;
  TezosBeaconService _tezosBeaconService;
  NetworkConfigInjector _networkConfigInjector;
  CloudDatabase _cloudDB;
  ConfigurationService _configurationService;
  FeedService _feedService;

  AssetTokenDao get _assetTokenDao =>
      _networkConfigInjector.I<AppDatabase>().assetDao;
  ProvenanceDao get _provenanceDao =>
      _networkConfigInjector.I<AppDatabase>().provenanceDao;
  IndexerApi get _indexerApi => _networkConfigInjector.I<IndexerApi>();

  List<String> _hiddenOwners = [];

  Future<List<String>> fetchManuallyTokens() async {
    final tokenIndexerIDs = (await _cloudDB.connectionDao.getConnectionsByType(
            ConnectionType.manuallyIndexerTokenID.rawValue))
        .map((e) => e.key)
        .toList();
    if (tokenIndexerIDs.isEmpty) return [];

    final manuallyAssets =
        (await _indexerApi.getNftTokens({"ids": tokenIndexerIDs}));
    await _tokensService.insertAssetsWithProvenance(manuallyAssets);
    return tokenIndexerIDs;
  }

  HomeBloc(
    this._tokensService,
    this._walletConnectService,
    this._tezosBeaconService,
    this._networkConfigInjector,
    this._cloudDB,
    this._configurationService,
    this._feedService,
  ) : super(HomeState()) {
    on<HomeConnectWCEvent>((event, emit) {
      log.info('[HomeConnectWCEvent] connect ${event.uri}');
      _walletConnectService.connect(event.uri);
    });

    on<HomeConnectTZEvent>((event, emit) {
      log.info('[HomeConnectTZEvent] addPeer ${event.uri}');
      _tezosBeaconService.addPeer(event.uri);
    });

    on<SubRefreshTokensEvent>((event, emit) async {
      if (!memoryValues.inGalleryView) return;
      final assetTokens =
          await _assetTokenDao.findAllAssetTokensWhereNot(_hiddenOwners);
      emit(state.copyWith(tokens: assetTokens, fetchTokenState: event.state));
      log.info('[SubRefreshTokensEvent] load ${assetTokens.length} tokens');
    });

    on<RefreshTokensEvent>((event, emit) async {
      log.info("[HomeBloc] RefreshTokensEvent start");

      try {
        late List<String> allAccountNumbers;
        if (_configurationService.isDemoArtworksMode()) {
          allAccountNumbers = [await getDemoAccount()];
        } else {
          final allAddresses = await _getPersonaAddresses();
          final linkedAccounts =
              await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
          var linkedAccountNumbers =
              linkedAccounts.expand((e) => e.accountNumbers).toList();

          allAccountNumbers = List.from(linkedAccountNumbers)
            ..addAll(allAddresses['personaBitmark'] ?? [])
            ..addAll(allAddresses['personaEthereum'] ?? [])
            ..addAll(allAddresses['personaTezos'] ?? []);
        }

        //Clear and refresh all assets if no contractAddress & tokenId
        final tokens = await _assetTokenDao.findAllAssetTokens();
        if (tokens.every((element) =>
            element.contractAddress == null && element.tokenId == null)) {
          await _assetTokenDao.removeAll();
        }

        await _assetTokenDao.deleteAssetsNotBelongs(allAccountNumbers);

        _hiddenOwners = await _getHiddenAddressesInGallery();

        add(SubRefreshTokensEvent(ActionState.notRequested));

        final latestAssets = await _tokensService.fetchLatestAssets(
            allAccountNumbers, INDEXER_TOKENS_MAXIMUM);
        await _tokensService.insertAssetsWithProvenance(latestAssets);

        log.info("[HomeBloc] fetch ${latestAssets.length} latest NFTs");

        if (latestAssets.length < INDEXER_TOKENS_MAXIMUM) {
          // Delete obsoleted assets
          if (latestAssets.isNotEmpty) {
            final tokenIDs = latestAssets.map((e) => e.id).toList();
            await _assetTokenDao.deleteAssetsNotIn(tokenIDs);
            await _provenanceDao.deleteProvenanceNotBelongs(tokenIDs);
          } else {
            await _assetTokenDao.removeAll();
            await _provenanceDao.removeAll();
          }

          await fetchManuallyTokens();

          add(SubRefreshTokensEvent(ActionState.done));
          _feedService.refreshFollowings();
        } else {
          final debutTokenIDs = await fetchManuallyTokens();
          add(SubRefreshTokensEvent(ActionState.loading));
          log.info("[HomeBloc][start] _tokensService.refreshTokensInIsolate");

          final stream = await _tokensService.refreshTokensInIsolate(
              allAccountNumbers, debutTokenIDs);
          stream.listen((event) async {
            log.info("[Stream.refreshTokensInIsolate] getEvent");
            add(SubRefreshTokensEvent(ActionState.loading));
          }, onDone: () async {
            log.info("[Stream.refreshTokensInIsolate] getEvent Done");
            add(SubRefreshTokensEvent(ActionState.done));
            _feedService.refreshFollowings();
          });
        }
      } catch (exception) {
        if ((state.tokens ?? []).isEmpty) {
          rethrow;
        } else {
          Sentry.captureException(exception);
        }
      }
    });

    on<ReindexIndexerEvent>((event, emit) async {
      try {
        final addresses = await _getPersonaAddresses();

        for (var ethAddress in addresses['personaEthereum'] ?? []) {
          log.info("[HomeBloc] RequestIndex for $ethAddress");
          _indexerApi.requestIndex({"owner": ethAddress});
        }

        for (var tezosAddress in addresses['personaTezos'] ?? []) {
          log.info("[HomeBloc] RequestIndex for $tezosAddress");
          _indexerApi
              .requestIndex({"owner": tezosAddress, "blockchain": "tezos"});
        }

        final linkedAccounts =
            await _cloudDB.connectionDao.getUpdatedLinkedAccounts();

        for (var linkAccount in linkedAccounts) {
          switch (linkAccount.connectionType) {
            case 'walletConnect':
            case 'walletBrowserConnect':
              final ethAddress = linkAccount.accountNumber;
              log.info("[HomeBloc] RequestIndex for linked $ethAddress");
              _indexerApi.requestIndex({"owner": ethAddress});
              break;

            case 'walletBeacon':
              final tezosAddress = linkAccount.accountNumber;
              log.info("[HomeBloc] RequestIndex for linked $tezosAddress");
              _indexerApi
                  .requestIndex({"owner": tezosAddress, "blockchain": "tezos"});
              break;

            case 'ledger':
              final data = linkAccount.ledgerConnection;
              final ethAddress = data?.etheremAddress.firstOrNull;
              final tezosAddress = data?.tezosAddress.firstOrNull;

              if (ethAddress != null) {
                log.info(
                    "[HomeBloc] RequestIndex for linked ledger $ethAddress");
                _indexerApi.requestIndex({"owner": ethAddress});
              }

              if (tezosAddress != null) {
                log.info("[HomeBloc] RequestIndex for linked $tezosAddress");
                _indexerApi.requestIndex(
                    {"owner": tezosAddress, "blockchain": "tezos"});
              }

              break;

            case 'manuallyAddress':
              final address = linkAccount.accountNumber;

              if (address.startsWith("tz")) {
                _indexerApi
                    .requestIndex({"owner": address, "blockchain": "tezos"});
              } else if (address.startsWith("0x")) {
                _indexerApi.requestIndex({"owner": address});
              }

              break;

            case 'feralFileWeb3':
            case 'feralFileToken':
              final ffAccount = linkAccount.ffConnection?.ffAccount ??
                  linkAccount.ffWeb3Connection?.ffAccount;
              final ethereumAddress = ffAccount?.ethereumAddress;
              final tezosAddress = ffAccount?.tezosAddress;

              if (ethereumAddress != null) {
                _indexerApi.requestIndex({"owner": ethereumAddress});
              }

              if (tezosAddress != null) {
                _indexerApi.requestIndex(
                    {"owner": tezosAddress, "blockchain": "tezos"});
              }

              break;

            default:
              break;
          }
        }
      } catch (exception) {
        log.info("[HomeBloc] error when request index");
        Sentry.captureException(exception);
      }
    });
  }

  Future<Map<String, List<String>>> _getPersonaAddresses() async {
    final personas = await _cloudDB.personaDao.getPersonas();

    List<String> bitmarkAddresses = [];
    List<String> ethAddresses = [];
    List<String> tezosAddresses = [];

    for (var persona in personas) {
      final ethAddress = await persona.wallet().getETHEip55Address();
      if (ethAddress.isEmpty)
        continue; // ignore persona when there is no keys in Keychain
      final tezosWallet = await persona.wallet().getTezosWallet();
      final tezosAddress = tezosWallet.address;
      final bitmarkAddress = await persona.wallet().getBitmarkAddress();

      bitmarkAddresses += [bitmarkAddress];
      ethAddresses += [ethAddress];
      tezosAddresses += [tezosAddress];
    }

    return {
      'personaBitmark': bitmarkAddresses,
      'personaEthereum': ethAddresses,
      'personaTezos': tezosAddresses,
    };
  }

  Future<List<String>> _getHiddenAddressesInGallery() async {
    List<String> hiddenAddresses = [];
    final personaUUIDs = _configurationService.getPersonaUUIDsHiddenInGallery();
    for (var personaUUID in personaUUIDs) {
      final personaWallet = Persona.newPersona(uuid: personaUUID).wallet();
      final ethAddress = await personaWallet.getETHEip55Address();

      if (ethAddress.isEmpty) continue;
      hiddenAddresses.add(ethAddress);
      hiddenAddresses.add((await personaWallet.getTezosWallet()).address);
      hiddenAddresses.add(await personaWallet.getBitmarkAddress());
    }

    final hiddenLinkedAccounts =
        _configurationService.getLinkedAccountsHiddenInGallery();

    for (final hiddenLinkedAccount in hiddenLinkedAccounts) {
      if (hiddenLinkedAccount.startsWith('ledger_')) {
        final linkedLedgerKey =
            hiddenLinkedAccount.replacePrefix('ledger_', '');
        final connection =
            await _cloudDB.connectionDao.findById(linkedLedgerKey);

        if (connection != null)
          hiddenAddresses.addAll(connection.accountNumbers);
      } else {
        hiddenAddresses.add(hiddenLinkedAccount);
      }
    }

    return hiddenAddresses;
  }
}
