import 'dart:convert';
import 'dart:io';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_data.dart';
import 'package:flutter/services.dart';

class MigrationUtil {
  static const MethodChannel _channel = const MethodChannel('migration_util');
  CloudDatabase _cloudDB;

  MigrationUtil(this._cloudDB);

  Future<void> migrateIfNeeded(bool isIOS) async {
    if (isIOS) {
      await _migrationiOS();
    } else {
      await _migrationAndroid();
    }
  }

  Future<void> migrationFromKeychain(bool isIOS) async {
    if (isIOS) {
      await _migrationFromKeychain();
    }
    // TODO: support scan keys in Android when it's doable
  }

  static Future<String?> getBackupDeviceID() async {
    if (Platform.isIOS) {
      final String? deviceId = await _channel.invokeMethod("getDeviceID", {});

      return deviceId ?? await getDeviceID();
    } else {
      return await getDeviceID();
    }
  }

  Future _migrationiOS() async {
    log.info('[_migrationiOS] start');
    final String jsonString =
        await _channel.invokeMethod('getiOSMigrationData', {});
    if (jsonString.isEmpty) return;

    log.info('[_migrationiOS] get jsonString $jsonString');

    final jsonData = json.decode(jsonString);
    final migrationData = MigrationData.fromJson(jsonData);

    for (var mPersona in migrationData.personas) {
      final wallet = Persona.newPersona(uuid: mPersona.uuid).wallet();
      final address = await wallet.getETHAddress();

      if (address.isEmpty) continue;
      final name = await wallet.getName();

      final persona = Persona(
          uuid: mPersona.uuid, name: name, createdAt: mPersona.createdAt);

      await _cloudDB.personaDao.insertPersona(persona);
    }

    for (var con in migrationData.ffTokenConnections) {
      final ffConnection =
          FeralFileConnection(source: con.source, ffAccount: con.ffAccount);
      final connection = Connection(
        key: con.token,
        name: con.ffAccount.alias,
        data: json.encode(ffConnection),
        connectionType: ConnectionType.feralFileToken.rawValue,
        accountNumber: con.ffAccount.accountNumber,
        createdAt: con.createdAt,
      );

      await _cloudDB.connectionDao.insertConnection(connection);
    }

    for (var con in migrationData.ffWeb3Connections) {
      final ffWeb3Connection = FeralFileWeb3Connection(
          personaAddress: con.address,
          source: con.source,
          ffAccount: con.ffAccount);
      final connection = Connection(
        key: con.topic,
        name: con.ffAccount.alias,
        data: json.encode(ffWeb3Connection),
        connectionType: ConnectionType.feralFileWeb3.rawValue,
        accountNumber: con.ffAccount.accountNumber,
        createdAt: con.createdAt,
      );

      await _cloudDB.connectionDao.insertConnection(connection);
    }

    for (var con in migrationData.walletBeaconConnections) {
      final connection = Connection(
        key: con.tezosWalletConnection.address,
        name: con.name,
        data: json.encode(con.tezosWalletConnection),
        connectionType: ConnectionType.walletBeacon.rawValue,
        accountNumber: con.tezosWalletConnection.address,
        createdAt: con.createdAt,
      );

      await _cloudDB.connectionDao.insertConnection(connection);
    }

    for (var con in migrationData.walletConnectConnections) {
      if (con.wcConnectedSession.accounts.isEmpty) continue;
      final connection = Connection(
        key: con.wcConnectedSession.accounts.first,
        name: con.name,
        data: json.encode(con.wcConnectedSession),
        connectionType: ConnectionType.walletConnect.rawValue,
        accountNumber: con.wcConnectedSession.accounts.first,
        createdAt: con.createdAt,
      );

      await _cloudDB.connectionDao.insertConnection(connection);
    }

    await _channel.invokeMethod("cleariOSMigrationData", {});
    log.info('[_migrationIOS] Done');
  }

  Future _migrationAndroid() async {
    final personasCount = await _cloudDB.personaDao.getPersonasCount();
    if ((personasCount ?? 0) > 0) return;

    final String jsonString =
        await _channel.invokeMethod('getExistingUuids', {});

    if (jsonString.isNotEmpty) {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final uuids = json["personas"] ?? [];
      // The android app is currently supporting single persona only.
      for (var uuid in uuids) {
        final wallet = Persona.newPersona(uuid: uuid).wallet();
        final address = await wallet.getETHAddress();

        if (address.isEmpty) continue;
        final name = await wallet.getName();

        final persona =
            Persona(uuid: uuid, name: name, createdAt: DateTime.now());

        await _cloudDB.personaDao.insertPersona(persona);
      }
    }
  }

  Future _migrationFromKeychain() async {
    final List personaUUIDs =
        await _channel.invokeMethod('getWalletUUIDsFromKeychain', {});

    log.info(
        "[_migrationFromKeychain] personaUUIDs from Keychain: $personaUUIDs");
    for (var uuid in personaUUIDs) {
      final wallet = Persona.newPersona(uuid: uuid).wallet();
      final name = await wallet.getName();
      final persona =
          Persona(uuid: uuid, name: name, createdAt: DateTime.now());

      await _cloudDB.personaDao.insertPersona(persona);
    }
  }
}
