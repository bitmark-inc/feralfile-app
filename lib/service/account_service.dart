import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/android_backup_channel.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/wallet_connect.dart';

import 'wallet_connect_dapp_service/wc_connected_session.dart';

abstract class AccountService {
  Future<WalletStorage> getDefaultAccount();
  Future androidBackupKeys();
  Future<bool?> isAndroidEndToEndEncryptionAvailable();
  Future androidRestoreKeys();
  Future<Persona> createPersona({String name = ""});
  Future<Persona> importPersona(String words);
  Future<Persona> namePersona(Persona persona, String name);
  Future<Connection> nameLinkedAccount(Connection connection, String name);
  Future<Connection> linkETHWallet(WCConnectedSession session);
  Future<Connection> linkETHBrowserWallet(String address, WalletApp walletApp);
  Future linkManuallyAddress(String address);
  Future deletePersona(Persona persona);
  Future deleteLinkedAccount(Connection connection);
  Future linkIndexerTokenID(String indexerTokenID);

  Future setHidePersonaInGallery(String personaUUID, bool isEnabled);
  Future setHideLinkedAccountInGallery(String address, bool isEnabled);
  bool isPersonaHiddenInGallery(String personaUUID);
  bool isLinkedAccountHiddenInGallery(String address);
}

class AccountServiceImpl extends AccountService {
  final CloudDatabase _cloudDB;
  final WalletConnectService _walletConnectService;
  final TezosBeaconService _tezosBeaconService;
  final ConfigurationService _configurationService;
  final AndroidBackupChannel _backupChannel = AndroidBackupChannel();
  final AuditService _auditService;
  final AutonomyService _autonomyService;

  AccountServiceImpl(
      this._cloudDB,
      this._walletConnectService,
      this._tezosBeaconService,
      this._configurationService,
      this._auditService,
      this._autonomyService);

  Future<Persona> createPersona({String name = ""}) async {
    final uuid = Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.createKey(name);

    final persona = Persona.newPersona(uuid: uuid, name: "");
    await _cloudDB.personaDao.insertPersona(persona);
    await androidBackupKeys();
    await _auditService.audiPersonaAction('create', persona);
    injector<AWSService>().storeEventWithDeviceData("create_full_account",
        hashingData: {"id": uuid});
    _autonomyService.postLinkedAddresses();

    return persona;
  }

  Future<Persona> importPersona(String words) async {
    final uuid = Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.importKey(
        words, "", DateTime.now().microsecondsSinceEpoch);

    final persona = Persona.newPersona(uuid: uuid, name: "");
    await _cloudDB.personaDao.insertPersona(persona);
    await androidBackupKeys();
    await _auditService.audiPersonaAction('import', persona);
    injector<AWSService>().storeEventWithDeviceData("import_full_account",
        hashingData: {"id": uuid});
    _autonomyService.postLinkedAddresses();

    return persona;
  }

  Future<WalletStorage> getDefaultAccount() async {
    var personas = await _cloudDB.personaDao.getPersonas();

    if (personas.isEmpty) {
      await MigrationUtil(_configurationService, _cloudDB, this,
              injector<NavigationService>(), injector(), _auditService)
          .migrationFromKeychain(Platform.isIOS);
      await androidRestoreKeys();

      await Future.delayed(Duration(seconds: 1));
      personas = await _cloudDB.personaDao.getPersonas();
    }

    final Persona defaultPersona;
    if (personas.isEmpty) {
      defaultPersona = await createPersona(name: "Default");
    } else {
      defaultPersona = personas.first;
    }

    return LibAukDart.getWallet(defaultPersona.uuid);
  }

  Future deletePersona(Persona persona) async {
    await _cloudDB.personaDao.deletePersona(persona);
    await LibAukDart.getWallet(persona.uuid).removeKeys();
    await androidBackupKeys();
    await _auditService.audiPersonaAction('delete', persona);

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

      await setHidePersonaInGallery(persona.uuid, false);
    } catch (exception) {
      Sentry.captureException(exception);
    }

    injector<AWSService>().storeEventWithDeviceData("delete_full_account",
        hashingData: {"id": persona.uuid});
    _autonomyService.postLinkedAddresses();
  }

  Future deleteLinkedAccount(Connection connection) async {
    await _cloudDB.connectionDao
        .deleteConnectionsByAccountNumber(connection.accountNumber);
    await setHideLinkedAccountInGallery(connection.accountNumber, false);
    injector<AWSService>().storeEventWithDeviceData("delete_linked_account",
        hashingData: {"address": connection.accountNumber});
    _autonomyService.postLinkedAddresses();
  }

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

  Future<Connection> linkETHWallet(WCConnectedSession session) async {
    final connection = Connection.fromETHWallet(session);
    final alreadyLinkedAccount =
        await getExistingAccount(connection.accountNumber);
    if (alreadyLinkedAccount != null) {
      throw AlreadyLinkedException(alreadyLinkedAccount);
    }

    await _cloudDB.connectionDao.insertConnection(connection);
    injector<AWSService>().storeEventWithDeviceData("link_eth_wallet",
        hashingData: {"address": connection.accountNumber});
    _autonomyService.postLinkedAddresses();
    return connection;
  }

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
    injector<AWSService>().storeEventWithDeviceData("link_eth_wallet_browser",
        hashingData: {"address": connection.accountNumber});
    _autonomyService.postLinkedAddresses();
    return connection;
  }

  bool isPersonaHiddenInGallery(String personaUUID) {
    return _configurationService.isPersonaHiddenInGallery(personaUUID);
  }

  bool isLinkedAccountHiddenInGallery(String address) {
    return _configurationService.isLinkedAccountHiddenInGallery(address);
  }

  Future setHidePersonaInGallery(String personaUUID, bool isEnabled) async {
    _configurationService.setHidePersonaInGallery(personaUUID, isEnabled);
  }

  Future setHideLinkedAccountInGallery(String address, bool isEnabled) async {
    _configurationService.setHideLinkedAccountInGallery(address, isEnabled);
    injector<AWSService>().storeEventWithDeviceData("hide_linked_account",
        hashingData: {"address": address});
  }

  Future androidBackupKeys() async {
    if (Platform.isAndroid) {
      final accounts = await _cloudDB.personaDao.getPersonas();
      final uuids = accounts.map((e) => e.uuid).toList();

      if (uuids.isNotEmpty) {
        await _backupChannel.backupKeys(uuids);
      }
    }
  }

  Future androidRestoreKeys() async {
    if (Platform.isAndroid) {
      final accounts = await _backupChannel.restoreKeys();

      //Remove persona from database if keys not found
      final personas = await _cloudDB.personaDao.getPersonas();
      personas.forEach((persona) async {
        if (!accounts.any((element) => element.uuid == persona.uuid)) {
          await _cloudDB.personaDao.deletePersona(persona);
          await _auditService.audiPersonaAction(
              '[androidRestoreKeys] delete', persona);
        }
      });

      //Import persona to database if needed
      accounts.forEach((account) async {
        final existingAccount =
            await _cloudDB.personaDao.findById(account.uuid);
        if (existingAccount == null) {
          final persona = Persona(
              uuid: account.uuid,
              name: account.name,
              createdAt: DateTime.now());
          await _cloudDB.personaDao.insertPersona(persona);
          await _auditService.audiPersonaAction(
              '[androidRestoreKeys] insert', persona);
        }
      });
    }
  }

  Future<Persona> namePersona(Persona persona, String name) async {
    await persona.wallet().updateName(name);
    final updatedPersona = persona.copyWith(name: name);
    await _cloudDB.personaDao.updatePersona(updatedPersona);
    await _auditService.audiPersonaAction('name', updatedPersona);

    return updatedPersona;
  }

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

  Future<bool?> isAndroidEndToEndEncryptionAvailable() {
    return _backupChannel.isEndToEndEncryptionAvailable();
  }
}
