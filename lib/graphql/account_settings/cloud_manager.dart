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
  late final String _deviceId;
  late final String _flavor;

  late final WalletAddressCloudObject _walletAddressObject;

  // this settings is for one device
  late final AccountSettingsDB _deviceSettingsDB;

  // this settings is shared across all devices
  late final AccountSettingsDB _userSettingsDB;

  late final PlaylistCloudObject _playlistCloudObject;

  CloudManager() {
    unawaited(_init());
  }

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
    final addressAccountSettingsDB = AccountSettingsDBImpl(injector(),
        [_flavor, _commonKeyPrefix, _db, _walletAddressKeyPrefix].join('.'));

    _walletAddressObject = WalletAddressCloudObject(addressAccountSettingsDB);

    /// device settings
    _deviceSettingsDB = AccountSettingsDBImpl(injector(),
        [_flavor, _deviceId, _settings, _settingsDataKeyPrefix].join('.'));

    /// user settings
    _userSettingsDB = AccountSettingsDBImpl(
        injector(), [_flavor, _commonKeyPrefix, _settings, _db].join('.'));

    /// playlist
    final playlistAccountSettingsDB = AccountSettingsDBImpl(injector(),
        [_flavor, _commonKeyPrefix, _db, _playlistKeyPrefix].join('.'));
    _playlistCloudObject = PlaylistCloudObject(playlistAccountSettingsDB);
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

  WalletAddressCloudObject get addressObject => _walletAddressObject;

  AccountSettingsDB get deviceSettingsDB => _deviceSettingsDB;

  AccountSettingsDB get userSettingsDB => _userSettingsDB;

  PlaylistCloudObject get playlistCloudObject => _playlistCloudObject;

  Future<void> downloadAll({bool includePlaylists = false}) async {
    log.info('[CloudManager] downloadAll');
    if (includePlaylists) {
      unawaited(_playlistCloudObject.db.download());
    }
    unawaited(injector<SettingsDataService>().restoreSettingsData());
    await Future.wait([
      _walletAddressObject.download(),
    ]);
    log.info('[CloudManager] downloadAll done');
  }

  void clearCache() {
    _walletAddressObject.db.clearCache();
    _deviceSettingsDB.clearCache();
    _userSettingsDB.clearCache();
    _playlistCloudObject.db.clearCache();
  }

  Future<void> deleteAll() async {
    await injector<AccountSettingsClient>().delete(vars: {'search': ''});
  }
}
