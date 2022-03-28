import 'dart:io';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/android_backup_channel.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/wallet_connect.dart';

import 'wallet_connect_dapp_service/wc_connected_session.dart';

class AccountService {
  final CloudDatabase _cloudDB;
  final WalletConnectService _walletConnectService;
  final TezosBeaconService _tezosBeaconService;
  final ConfigurationService _configurationService;
  final AndroidBackupChannel _backupChannel = AndroidBackupChannel();

  AccountService(this._cloudDB, this._walletConnectService,
      this._tezosBeaconService, this._configurationService);

  Future<Persona> createPersona() async {
    final uuid = Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.createKey("");

    final persona = Persona.newPersona(uuid: uuid, name: "");
    await _cloudDB.personaDao.insertPersona(persona);
    await androidBackupKeys();

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

    return persona;
  }

  Future deletePersona(Persona persona) async {
    await _cloudDB.personaDao.deletePersona(persona);
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

      await setHidePersonaInGallery(persona.uuid, false);
    } catch (exception) {
      Sentry.captureException(exception);
    }
  }

  Future deleteLinkedAccount(Connection connection) async {
    await _cloudDB.connectionDao
        .deleteConnectionsByAccountNumber(connection.accountNumber);
    await setHideLinkedAccountInGallery(connection.accountNumber, false);
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
  }

  Future<Connection> linkETHWallet(WCConnectedSession session) async {
    final connection = Connection.fromETHWallet(session);
    final alreadyLinkedAccount =
        await getExistingAccount(connection.accountNumber);
    if (alreadyLinkedAccount != null) {
      throw AlreadyLinkedException(alreadyLinkedAccount);
    }

    _cloudDB.connectionDao.insertConnection(connection);
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
        }
      });

      //Import persona to database if needed
      accounts.forEach((account) async {
        final existingAccount =
            await _cloudDB.personaDao.findById(account.uuid);
        if (existingAccount == null) {
          _cloudDB.personaDao.insertPersona(Persona(
              uuid: account.uuid,
              name: account.name,
              createdAt: DateTime.now()));
        }
      });
    }
  }

  Future<Connection?> getExistingAccount(String accountNumber) async {
    final existingConnections = await _cloudDB.connectionDao
        .getConnectionsByAccountNumber(accountNumber);

    if (existingConnections.isEmpty) return null;

    return existingConnections.first;
  }
}
