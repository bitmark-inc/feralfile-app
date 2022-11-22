//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/gateway/autonomy_api.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/mixPanel_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/android_backup_channel.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:libauk_dart/libauk_dart.dart';
// ignore: depend_on_referenced_packages
import 'package:elliptic/elliptic.dart';
import 'package:metric_client/metric_client.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/wallet_connect.dart';
import 'package:web3dart/crypto.dart';
import 'package:synchronized/synchronized.dart';

import 'wallet_connect_dapp_service/wc_connected_session.dart';

abstract class AccountService {
  Future<WalletStorage> getDefaultAccount();
  Future<WalletStorage?> getCurrentDefaultAccount();

  Future androidBackupKeys();

  Future<bool?> isAndroidEndToEndEncryptionAvailable();

  Future androidRestoreKeys();

  Future<List<Persona>> getPersonas();

  Future<Persona> createPersona({String name = ""});

  Future<Persona> importPersona(String words);

  Future<Persona> namePersona(Persona persona, String name);

  Future<Connection> nameLinkedAccount(Connection connection, String name);

  Future<Connection> linkETHWallet(WCConnectedSession session);

  Future<Connection> linkETHBrowserWallet(String address, WalletApp walletApp);

  Future linkManuallyAddress(String address);

  Future<bool> isLinkedIndexerTokenID(String indexerTokenID);

  Future deletePersona(Persona persona);

  Future deleteLinkedAccount(Connection connection);

  Future linkIndexerTokenID(String indexerTokenID);

  Future setHidePersonaInGallery(String personaUUID, bool isEnabled);

  Future setHideLinkedAccountInGallery(String address, bool isEnabled);

  bool isPersonaHiddenInGallery(String personaUUID);

  bool isLinkedAccountHiddenInGallery(String address);

  Future<List<String>> getAllAddresses();
  Future<List<String>> getAddress(String blockchain);
  Future<List<String>> getHiddenAddresses();
  Future<List<String>> getShowedAddresses();
  Future<String> authorizeToViewer();
}

class AccountServiceImpl extends AccountService {
  final CloudDatabase _cloudDB;
  final WalletConnectService _walletConnectService;
  final TezosBeaconService _tezosBeaconService;
  final ConfigurationService _configurationService;
  final AndroidBackupChannel _backupChannel = AndroidBackupChannel();
  final AuditService _auditService;
  final AutonomyService _autonomyService;
  final BackupService _backupService;
  final AutonomyApi _autonomyApi;

  final _defaultAccountLock = Lock();

  AccountServiceImpl(
    this._cloudDB,
    this._walletConnectService,
    this._tezosBeaconService,
    this._configurationService,
    this._auditService,
    this._autonomyService,
    this._backupService,
    this._autonomyApi,
  );

  @override
  Future<List<Persona>> getPersonas() {
    return _cloudDB.personaDao.getPersonas();
  }

  @override
  Future<Persona> createPersona(
      {String name = "", bool isDefault = false}) async {
    final uuid = const Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.createKey(name);

    final persona =
        Persona.newPersona(uuid: uuid, defaultAccount: isDefault ? 1 : null);
    await _cloudDB.personaDao.insertPersona(persona);
    await androidBackupKeys();
    await _auditService.auditPersonaAction('create', persona);
    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent("create_full_account", hashedData: {"id": uuid});

    final mixPanelClient = injector.get<MixPanelClientService>();
    mixPanelClient.trackEvent(
        "create_full_account",
        data: {"isDefault": isDefault},
        hashedData: {"id": persona.uuid}
    );
    _autonomyService.postLinkedAddresses();

    return persona;
  }

  @override
  Future<Persona> importPersona(String words) async {
    final personas = await _cloudDB.personaDao.getPersonas();
    for (final persona in personas) {
      final mnemonic = await persona.wallet().exportMnemonicWords();
      if (mnemonic == words) {
        throw AccountImportedException(persona: persona);
      }
    }

    final uuid = const Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.importKey(
        words, "", DateTime.now().microsecondsSinceEpoch);

    final persona = Persona.newPersona(uuid: uuid);
    await _cloudDB.personaDao.insertPersona(persona);
    await androidBackupKeys();
    await _auditService.auditPersonaAction('import', persona);
    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent("import_full_account", hashedData: {"id": uuid});

    final mixPanelClient = injector.get<MixPanelClientService>();
    mixPanelClient.trackEvent(
        "import_full_account",
        hashedData: {"id": persona.uuid}
    );
    _autonomyService.postLinkedAddresses();

    return persona;
  }

  @override
  Future<WalletStorage> getDefaultAccount() async {
    return _defaultAccountLock.synchronized(() async {
      return await _getDefaultAccount();
    });
  }

  @override
  Future<WalletStorage?> getCurrentDefaultAccount() async {
    var personas = await _cloudDB.personaDao.getDefaultPersonas();
    if (personas.isEmpty) return null;
    final defaultWallet = personas.first.wallet();

    return await defaultWallet.isWalletCreated() ? defaultWallet : null;
  }

  Future<WalletStorage> _getDefaultAccount() async {
    var personas = await _cloudDB.personaDao.getDefaultPersonas();

    if (personas.isEmpty) {
      await MigrationUtil(_configurationService, _cloudDB, this, injector(),
              _auditService, _backupService)
          .migrationFromKeychain();
      await androidRestoreKeys();

      await Future.delayed(const Duration(seconds: 1));
      personas = await _cloudDB.personaDao.getDefaultPersonas();
    }

    final Persona defaultPersona;
    if (personas.isEmpty) {
      personas = await _cloudDB.personaDao.getPersonas();
      if (personas.isNotEmpty) {
        defaultPersona = personas.first;
        defaultPersona.defaultAccount = 1;
        await _cloudDB.personaDao.updatePersona(defaultPersona);
      } else {
        log.info("[AccountService] create default account");
        defaultPersona = await createPersona(name: "Default", isDefault: true);
      }
    } else {
      defaultPersona = personas.first;
    }

    return LibAukDart.getWallet(defaultPersona.uuid);
  }

  @override
  Future deletePersona(Persona persona) async {
    await _cloudDB.personaDao.deletePersona(persona);
    await _auditService.auditPersonaAction('delete', persona);
    await LibAukDart.getWallet(persona.uuid).removeKeys();
    await androidBackupKeys();

    final connections = await _cloudDB.connectionDao.getConnections();
    Set<WCPeerMeta> wcPeers = {};
    Set<P2PPeer> bcPeers = {};

    for (var connection in connections) {
      switch (connection.connectionType) {
        case 'dappConnect':
          if (persona.uuid == connection.wcConnection?.personaUuid) {
            await _cloudDB.connectionDao.deleteConnection(connection);

            final wcPeer = connection.wcConnection?.sessionStore.peerMeta;
            if (wcPeer != null) wcPeers.add(wcPeer);
          }
          break;

        case 'beaconP2PPeer':
          if (persona.uuid == connection.beaconConnectConnection?.personaUuid) {
            await _cloudDB.connectionDao.deleteConnection(connection);

            final bcPeer = connection.beaconConnectConnection?.peer;
            if (bcPeer != null) bcPeers.add(bcPeer);
          }
          break;

        // Note: Should app delete feralFileWeb3 too ??
      }
    }

    try {
      for (var peer in wcPeers) {
        await _walletConnectService.disconnect(peer);
      }

      for (var peer in bcPeers) {
        await _tezosBeaconService.removePeer(peer);
      }

      if ((await _cloudDB.personaDao.getDefaultPersonas()).isNotEmpty) {
        await setHidePersonaInGallery(persona.uuid, false);
      }
    } catch (exception) {
      Sentry.captureException(exception);
    }
    final metricClient = injector.get<MetricClientService>();
    metricClient
        .addEvent("delete_full_account", hashedData: {"id": persona.uuid});

    final mixPanelClient = injector.get<MixPanelClientService>();
    mixPanelClient
        .trackEvent("delete_full_account", hashedData: {"id": persona.uuid});
  }

  @override
  Future deleteLinkedAccount(Connection connection) async {
    await _cloudDB.connectionDao.deleteConnection(connection);
    await setHideLinkedAccountInGallery(connection.hiddenGalleryKey, false);

    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent("delete_linked_account",
        hashedData: {"address": connection.accountNumber});

    final mixPanelClient = injector.get<MixPanelClientService>();
    mixPanelClient.trackEvent(
      "delete_linked_account",
      hashedData: {
        "address": connection.accountNumber
      }
    );
  }

  @override
  Future linkManuallyAddress(String address) async {
    final connection = Connection(
      key: address,
      name: '',
      data: '',
      connectionType: ConnectionType.manuallyAddress.rawValue,
      accountNumber: address,
      createdAt: DateTime.now(),
    );

    await _cloudDB.connectionDao.insertConnection(connection);
    _autonomyService.postLinkedAddresses();
  }

  @override
  Future linkIndexerTokenID(String indexerTokenID) async {
    final connection = Connection(
      key: indexerTokenID,
      name: '',
      data: '',
      connectionType: ConnectionType.manuallyIndexerTokenID.rawValue,
      accountNumber: '',
      createdAt: DateTime.now(),
    );

    await _cloudDB.connectionDao.insertConnection(connection);
  }

  @override
  Future<bool> isLinkedIndexerTokenID(String indexerTokenID) async {
    final connection = await _cloudDB.connectionDao.findById(indexerTokenID);
    if (connection == null) return false;

    return connection.connectionType ==
        ConnectionType.manuallyIndexerTokenID.rawValue;
  }

  @override
  Future<Connection> linkETHWallet(WCConnectedSession session) async {
    final connection = Connection.fromETHWallet(session);
    final alreadyLinkedAccount =
        await getExistingAccount(connection.accountNumber);
    if (alreadyLinkedAccount != null) {
      throw AlreadyLinkedException(alreadyLinkedAccount);
    }

    await _cloudDB.connectionDao.insertConnection(connection);
    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent("link_eth_wallet",
        hashedData: {"address": connection.accountNumber});

    final mixPanelClient = injector.get<MixPanelClientService>();
    mixPanelClient.trackEvent("link_wallet", data: {
      "wallet": connection.appName,
      "type": "app",
      "connectionType": connection.connectionType
    }, hashedData: {
      "address": connection.accountNumber
    });
    _autonomyService.postLinkedAddresses();
    return connection;
  }

  @override
  Future<Connection> linkETHBrowserWallet(
      String address, WalletApp walletApp) async {
    final alreadyLinkedAccount = await getExistingAccount(address);
    if (alreadyLinkedAccount != null) {
      throw AlreadyLinkedException(alreadyLinkedAccount);
    }

    final connection = Connection(
      key: address,
      name: '',
      data: walletApp.rawValue,
      connectionType: ConnectionType.walletBrowserConnect.rawValue,
      accountNumber: address,
      createdAt: DateTime.now(),
    );

    await _cloudDB.connectionDao.insertConnection(connection);
    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent("link_eth_wallet_browser",
        hashedData: {"address": connection.accountNumber});

    final mixPanelClient = injector.get<MixPanelClientService>();
    mixPanelClient.trackEvent("link_wallet",
        data: {
          "wallet": walletApp.name,
          "type": "browser",
          "connectionType": connection.connectionType
        },
        hashedData: {"address": address});
    _autonomyService.postLinkedAddresses();
    return connection;
  }

  @override
  bool isPersonaHiddenInGallery(String personaUUID) {
    return _configurationService.isPersonaHiddenInGallery(personaUUID);
  }

  @override
  bool isLinkedAccountHiddenInGallery(String address) {
    return _configurationService.isLinkedAccountHiddenInGallery(address);
  }

  @override
  Future setHidePersonaInGallery(String personaUUID, bool isEnabled) async {
    await _configurationService
        .setHidePersonaInGallery([personaUUID], isEnabled);
    await injector<SettingsDataService>().backup();
  }

  @override
  Future setHideLinkedAccountInGallery(String address, bool isEnabled) async {
    await _configurationService
        .setHideLinkedAccountInGallery([address], isEnabled);
    injector<SettingsDataService>().backup();
    final metricClient = injector.get<MetricClientService>();
    metricClient
        .addEvent("hide_linked_account", hashedData: {"address": address});

    final mixPanelClient = injector.get<MixPanelClientService>();
    mixPanelClient
        .trackEvent("hide_linked_account", hashedData: {"address": address});
  }

  @override
  Future androidBackupKeys() async {
    if (Platform.isAndroid) {
      final accounts = await _cloudDB.personaDao.getPersonas();
      final uuids = accounts.map((e) => e.uuid).toList();

      await _backupChannel.backupKeys(uuids);
    }
  }

  @override
  Future androidRestoreKeys() async {
    if (Platform.isAndroid) {
      final accounts = await _backupChannel.restoreKeys();

      final personas = await _cloudDB.personaDao.getPersonas();
      if (personas.length == accounts.length &&
          personas.every((element) =>
              accounts.map((e) => e.uuid).contains(element.uuid))) {
        //Database is up-to-date, skip migrating
        return;
      }

      //Import persona to database if needed
      for (var account in accounts) {
        final existingAccount =
            await _cloudDB.personaDao.findById(account.uuid);
        if (existingAccount == null) {
          final backupVersion = await _backupService
              .fetchBackupVersion(LibAukDart.getWallet(account.uuid));
          final defaultAccount = backupVersion.isNotEmpty ? 1 : null;

          final persona = Persona.newPersona(
            uuid: account.uuid,
            name: account.name,
            createdAt: DateTime.now(),
            defaultAccount: defaultAccount,
          );
          await _cloudDB.personaDao.insertPersona(persona);
          await _auditService.auditPersonaAction(
              '[androidRestoreKeys] insert', persona);
        }
      }

      //Cleanup broken personas
      final currentPersonas = await _cloudDB.personaDao.getPersonas();
      var shouldBackup = false;
      for (var persona in currentPersonas) {
        if (!(await persona.wallet().isWalletCreated())) {
          await _cloudDB.personaDao.deletePersona(persona);
          shouldBackup = true;
        }
      }

      if (shouldBackup || (personas.isNotEmpty && accounts.isEmpty)) {
        await androidBackupKeys();
      }
    }
  }

  @override
  Future<Persona> namePersona(Persona persona, String name) async {
    await persona.wallet().updateName(name);
    final updatedPersona = persona.copyWith(name: name);
    await _cloudDB.personaDao.updatePersona(updatedPersona);
    await _auditService.auditPersonaAction('name', updatedPersona);

    return updatedPersona;
  }

  @override
  Future<Connection> nameLinkedAccount(
      Connection connection, String name) async {
    connection.name = name;
    await _cloudDB.connectionDao.updateConnection(connection);
    return connection;
  }

  Future<Connection?> getExistingAccount(String accountNumber) async {
    final existingConnections = await _cloudDB.connectionDao
        .getConnectionsByAccountNumber(accountNumber);

    if (existingConnections.isEmpty) return null;

    return existingConnections.first;
  }

  @override
  Future<bool?> isAndroidEndToEndEncryptionAvailable() {
    return _backupChannel.isEndToEndEncryptionAvailable();
  }

  @override
  Future<List<String>> getAllAddresses() async {
    if (_configurationService.isDemoArtworksMode()) {
      return [];
    }

    List<String> addresses = [];

    final personas = await _cloudDB.personaDao.getPersonas();

    for (var persona in personas) {
      final personaWallet = persona.wallet();
      if (!await personaWallet.isWalletCreated()) continue;
      final ethAddress = await personaWallet.getETHEip55Address();

      if (ethAddress.isEmpty) continue;

      addresses.add(ethAddress);
      addresses.add(await personaWallet.getTezosAddress());
      addresses.add(await personaWallet.getBitmarkAddress());
    }

    final linkedAccounts =
        await _cloudDB.connectionDao.getUpdatedLinkedAccounts();

    for (final linkedAccount in linkedAccounts) {
      addresses.addAll(linkedAccount.accountNumbers);
    }

    return addresses;
  }

  @override
  Future<List<String>> getAddress(String blockchain) async {
    final addresses = <String>[];
    // Full accounts
    final personas = await _cloudDB.personaDao.getPersonas();
    for (var persona in personas) {
      final personaWallet = persona.wallet();
      if (!await personaWallet.isWalletCreated()) continue;
      switch (blockchain.toLowerCase()) {
        case "tezos":
          addresses.add(await personaWallet.getTezosAddress());
          break;
        case "ethereum":
          final address = await personaWallet.getETHEip55Address();
          if (address.isNotEmpty) {
            addresses.add(address);
          }
          break;
        case "bitmark":
          addresses.add(await personaWallet.getBitmarkAddress());
          break;
      }
    }

    // Linked accounts.
    // Currently, only support tezos blockchain.
    final linkedAccounts =
        await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
    final linkedAddresses = linkedAccounts
        .where((e) =>
            e.connectionType == ConnectionType.walletBeacon.rawValue ||
            e.connectionType == ConnectionType.beaconP2PPeer.rawValue)
        .map((e) => e.accountNumber);
    addresses.addAll(linkedAddresses);

    return addresses;
  }

  @override
  Future<List<String>> getHiddenAddresses() async {
    List<String> hiddenAddresses = [];

    final personas = await _cloudDB.personaDao.getPersonas();
    final hiddenPersonaUUIDs =
        _configurationService.getPersonaUUIDsHiddenInGallery();

    for (var persona in personas) {
      if (!hiddenPersonaUUIDs.contains(persona.uuid)) continue;
      final personaWallet = persona.wallet();
      if (!await personaWallet.isWalletCreated()) continue;
      final ethAddress = await personaWallet.getETHEip55Address();

      if (ethAddress.isEmpty) continue;
      hiddenAddresses.add(ethAddress);
      hiddenAddresses.add(await personaWallet.getTezosAddress());
      hiddenAddresses.add(await personaWallet.getBitmarkAddress());
    }

    final linkedAccounts =
        await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
    final hiddenLinkedAccounts =
        _configurationService.getLinkedAccountsHiddenInGallery();

    for (final linkedAccount in linkedAccounts) {
      if (hiddenLinkedAccounts.contains(linkedAccount.hiddenGalleryKey)) {
        hiddenAddresses.addAll(linkedAccount.accountNumbers);
      }
    }

    return hiddenAddresses;
  }

  @override
  Future<List<String>> getShowedAddresses() async {
    if (_configurationService.isDemoArtworksMode()) {
      return [await getDemoAccount()];
    }

    List<String> addresses = [];

    final personas = await _cloudDB.personaDao.getPersonas();
    final hiddenPersonaUUIDs =
        _configurationService.getPersonaUUIDsHiddenInGallery();

    for (var persona in personas) {
      if (hiddenPersonaUUIDs.contains(persona.uuid)) continue;

      final personaWallet = persona.wallet();
      if (!await personaWallet.isWalletCreated()) continue;
      final ethAddress = await personaWallet.getETHEip55Address();

      if (ethAddress.isEmpty) continue;

      addresses.add(ethAddress);
      addresses.add(await personaWallet.getTezosAddress());
      addresses.add(await personaWallet.getBitmarkAddress());
    }

    final linkedAccounts =
        await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
    final hiddenLinkedAccounts =
        _configurationService.getLinkedAccountsHiddenInGallery();

    for (final linkedAccount in linkedAccounts) {
      if (hiddenLinkedAccounts.contains(linkedAccount.hiddenGalleryKey)) {
        continue;
      }

      addresses.addAll(linkedAccount.accountNumbers);
    }

    return addresses;
  }

  @override
  Future<String> authorizeToViewer() async {
    var ec = getS256();
    final privateKey = ec.generatePrivateKey();

    final base58PublicKey = Base58Encode(
        [231, 1] + hexToBytes(privateKey.publicKey.toCompressedHex()));
    await _autonomyApi.addKeypair({
      "publicKey": base58PublicKey,
    });

    return "keypair_$base58PublicKey||${privateKey.toHex()}";
  }
}

class AccountImportedException implements Exception {
  final Persona persona;

  AccountImportedException({required this.persona});
}
