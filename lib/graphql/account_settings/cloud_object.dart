import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_client.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object/address_cloud_object.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object/connection_cloud_object.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CloudObjects {
  late final String _requester;
  late final String _deviceId;
  late final String _flavor;

  late final WalletAddressCloudObject _walletAddressObject;
  late final AccountSettingsDB _addressAccountSettingsDB;

  late final ConnectionCloudObject _connectionObject;
  late final AccountSettingsDB _connectionAccountSettingsDB;

  late final AccountSettingsDB _settingsDataDB;

  CloudObjects() {
    unawaited(_init());
  }

  Future<void> _getBackupId() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? deviceId = await MigrationUtil.getBackupDeviceID();
    _deviceId = deviceId ?? '_';
    _flavor = packageInfo.packageName.contains('inhouse')
        ? 'mobile_inhouse'
        : 'mobile_prd';
    _requester = '${deviceId}_${packageInfo.packageName}';
  }

  Future<void> _init() async {
    await _getBackupId();

    /// Wallet Address
    _addressAccountSettingsDB = AccountSettingsDBImpl(injector(),
        [_flavor, _commonKeyPrefix, _db, _walletAddressKeyPrefix].join('.'));
    _walletAddressObject = WalletAddressCloudObject(_addressAccountSettingsDB);

    /// Connection
    _connectionAccountSettingsDB = AccountSettingsDBImpl(
        injector(), [_flavor, _deviceId, _db, _connectionKeyPrefix].join('.'));
    _connectionObject = ConnectionCloudObject(_connectionAccountSettingsDB);

    /// Settings
    _settingsDataDB = AccountSettingsDBImpl(injector(),
        [_flavor, _deviceId, _settings, _settingsDataKeyPrefix].join('.'));
  }

  // this will be shared across all physical devices
  static const _commonKeyPrefix = 'common';

  // this for saving database object
  static const _db = 'db';

  // this for saving settings configuration
  static const _settings = 'settings';

  // this for saving wallet address table
  static const _walletAddressKeyPrefix = 'wallet_address_tb';

  // this for saving connection table
  static const _connectionKeyPrefix = 'connection_tb';

  // this for saving settings data
  static const _settingsDataKeyPrefix = 'settings_data_tb';

  WalletAddressCloudObject get addressObject => _walletAddressObject;

  ConnectionCloudObject get connectionObject => _connectionObject;

  AccountSettingsDB get settingsDataDB => _settingsDataDB;

  Future<void> setMigrated() async {
    final data = [
      {'key': settingsDataDB.migrateKey, 'value': 'true'},
      {'key': _addressAccountSettingsDB.migrateKey, 'value': 'true'},
      {'key': _connectionAccountSettingsDB.migrateKey, 'value': 'true'}
    ];
    final didMigrate =
        await injector<AccountSettingsClient>().write(data: data);
    await injector<ConfigurationService>()
        .setMigrateToAccountSetting(didMigrate);
  }

  Future<void> copyDataFrom(CloudDatabase source) async {
    await source.addressDao.getAllAddresses().then((addresses) async {
      final data = addresses.map((e) => e.toKeyValue).toList();
      await _addressAccountSettingsDB.write(data);
    });

    await source.connectionDao.getConnections().then((connections) async {
      final data = connections.map((e) => e.toKeyValue).toList();
      await _connectionAccountSettingsDB.write(data);
    });

    try {
      await injector<IAPApi>().deleteAllProfiles(_requester);
    } catch (_) {}
  }

  Future<void> downloadAll() async {
    await Future.wait([
      _addressAccountSettingsDB.download(),
      _connectionAccountSettingsDB.download(),
      injector<SettingsDataService>().restoreSettingsData(),
    ]);
  }

  void clearCache() {
    _addressAccountSettingsDB.clearCache();
    _connectionAccountSettingsDB.clearCache();
    _settingsDataDB.clearCache();
  }

  Future<void> deleteAll() async {
    await injector<AccountSettingsClient>().delete(vars: {'search': ''});
  }

  Future<void> forceUpload() async {
    await _addressAccountSettingsDB.forceUpload();
    await _connectionAccountSettingsDB.forceUpload();
    await _settingsDataDB.forceUpload();
  }
}
