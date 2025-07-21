import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_client.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object/address_cloud_object.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object/playlist_cloud_object.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CloudManager {
  CloudManager() {
    unawaited(_init());
  }

  late final String _deviceId;
  late final String _flavor;

  late final WalletAddressCloudObject _walletAddressObject;

  // this settings is for one device
  late final CloudDB _deviceSettingsDB;

  // this settings is shared across all devices
  late final CloudDB _userSettingsDB;

  late final PlaylistCloudObject _playlistCloudObject;

  //save ff device
  late final CloudDB _ffDeviceCloudDB;

  Future<void> _getBackupId() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? deviceId = await getDeviceID();
    _deviceId = deviceId;
    _flavor = packageInfo.packageName.contains('inhouse')
        ? 'mobile_inhouse'
        : 'mobile_prd';
  }

  Future<void> _init() async {
    await _getBackupId();

    /// Wallet Address
    final addressCloudDB = CloudDBImpl(injector(),
        [_flavor, _commonKeyPrefix, _db, _walletAddressKeyPrefix].join('.'));

    _walletAddressObject = WalletAddressCloudObject(addressCloudDB);

    /// device settings
    _deviceSettingsDB = CloudDBImpl(injector(),
        [_flavor, _deviceId, _settings, _settingsDataKeyPrefix].join('.'));

    /// user settings
    _userSettingsDB = CloudDBImpl(
        injector(), [_flavor, _commonKeyPrefix, _settings, _db].join('.'));

    /// playlist
    final playlistCloudDB = CloudDBImpl(injector(),
        [_flavor, _commonKeyPrefix, _db, _playlistKeyPrefix].join('.'));
    _playlistCloudObject = PlaylistCloudObject(playlistCloudDB);

    /// ff device
    _ffDeviceCloudDB = CloudDBImpl(injector(),
        [_flavor, _commonKeyPrefix, _db, _ffDeviceKeyPrefix].join('.'));
  }

  // this will be shared across all physical devices
  static const _commonKeyPrefix = 'common';

  // this for saving database object
  static const _db = 'db';

  // this for saving settings configuration
  static const _settings = 'settings';

  // this for saving wallet address table
  static const _walletAddressKeyPrefix = 'wallet_address_tb';

  // this for saving settings data
  static const _settingsDataKeyPrefix = 'settings_data_tb';

  // this for saving playlist data
  static const _playlistKeyPrefix = 'playlist';

  // this for saving ff device data
  static const _ffDeviceKeyPrefix = 'ff_device';

  WalletAddressCloudObject get addressObject => _walletAddressObject;

  CloudDB get deviceSettingsDB => _deviceSettingsDB;

  CloudDB get userSettingsDB => _userSettingsDB;

  PlaylistCloudObject get playlistCloudObject => _playlistCloudObject;

  CloudDB get ffDeviceDB => _ffDeviceCloudDB;

  Future<void> downloadAll({bool includePlaylists = false}) async {
    log.info('[CloudManager] downloadAll');
    if (includePlaylists) {
      unawaited(playlistCloudObject.download());
    }
    unawaited(injector<SettingsDataService>().restoreSettingsData());
    await Future.wait([
      addressObject.download(),
    ]);

    await deviceSettingsDB.download();

    await ffDeviceDB.download();
    log.info('[CloudManager] downloadAll done');
  }

  void clearCache() {
    _walletAddressObject.clearCache();
    _deviceSettingsDB.clearCache();
    _userSettingsDB.clearCache();
    _playlistCloudObject.clearCache();
    _ffDeviceCloudDB.clearCache();
  }

  Future<void> deleteAll() async {
    await injector<AccountSettingsClient>().delete(vars: {'search': ''});
  }
}
