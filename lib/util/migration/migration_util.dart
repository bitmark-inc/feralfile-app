import 'dart:convert';
import 'dart:io';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/android_backup_channel.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MigrationUtil {
  static const MethodChannel _channel = const MethodChannel('migration_util');
  ConfigurationService _configurationService;
  CloudDatabase _cloudDB;
  AccountService _accountService;
  NavigationService _navigationService;
  IAPService _iapService;

  MigrationUtil(this._configurationService, this._cloudDB, this._accountService,
      this._navigationService, this._iapService);

  Future<void> migrateIfNeeded() async {
    if (Platform.isIOS) {
      await _migrationiOS();
    } else {
      await _migrationAndroid();
    }
    await _askForNotification();
    _iapService.restore();
    log.info("[migration] finished");
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
    final previousBuildNumber = _configurationService.getPreviousBuildNumber();

    if (previousBuildNumber == null) {
      final packageInfo = await PackageInfo.fromPlatform();
      _configurationService.setPreviousBuildNumber(packageInfo.buildNumber);
      _accountService.androidBackupKeys();
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

  Future _askForNotification() async {
    if ((await _cloudDB.personaDao.getPersonas()).isEmpty ||
        _configurationService.isNotificationEnabled() != null) {
      // Skip asking for notifications
      return;
    }

    await Future<dynamic>.delayed(Duration(seconds: 1), () async {
      final context = _navigationService.navigatorKey.currentContext;
      if (context == null) return null;

      return await Navigator.of(context).pushNamed(
          AppRouter.notificationOnboardingPage,
          arguments: {"isOnboarding": false});
    });
  }
}
