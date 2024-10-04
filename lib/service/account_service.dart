//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/android_backup_channel.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/ios_backup_channel.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/primary_address_channel.dart'
    as primary_address_channel;
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/wallet_address_ext.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/services/address_service.dart' as nft;
import 'package:nft_collection/services/address_service.dart' as nft_address;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class AccountService {
  Future<void> migrateAccount();

  List<WalletAddress> getWalletsAddress(CryptoType cryptoType);

  Future<WalletStorage> getDefaultAccount();

  Future<WalletIndex> getAccountByAddress({
    required String chain,
    required String address,
  });

  Future androidBackupKeys();

  Future deleteAllKeys();

  Future<List<Connection>> removeDoubleViewOnly(List<String> addresses);

  Future<bool?> isAndroidEndToEndEncryptionAvailable();

  Future<List<WalletAddress>> createNewWallet(
      {String name = '', String passphrase = ''});

  Future<WalletStorage> importWords(String words, String passphrase,
      {WalletType walletType = WalletType.MultiChain});

  Future<Connection> nameLinkedAccount(Connection connection, String name);

  Future<Connection> linkManuallyAddress(String address, CryptoType cryptoType,
      {String? name});

  Future deleteLinkedAccount(Connection connection);

  Future linkIndexerTokenID(String indexerTokenID);

  Future setHideLinkedAccountInGallery(String address, bool isEnabled);

  Future setHideAddressInGallery(List<String> addresses, bool isEnabled);

  bool isLinkedAccountHiddenInGallery(String address);

  Future<List<String>> getAllAddresses({bool logHiddenAddress = false});

  Future<List<String>> getAddress(String blockchain,
      {bool withViewOnly = false});

  Future<List<AddressIndex>> getHiddenAddressIndexes();

  Future<List<String>> getShowedAddresses();

  Future<bool> addAddressWallet(String uuid, List<AddressInfo> addresses);

  Future<void> deleteAddressWallet(WalletAddress walletAddress);

  Future<WalletAddress?> getWalletByAddress(String address);

  Future<void> updateAddressWallet(WalletAddress walletAddress);

  List<Connection> getAllViewOnlyAddresses();

  Future<List<WalletAddress>> insertNextAddress(WalletType walletType,
      {String? name});

  Future<List<WalletAddress>> insertNextAddressFromUuid(
      String uuid, WalletType walletType,
      {String? name});

  Future<List<WalletAddress>> insertAddressAtIndexAndUuid(String uuid,
      {required WalletType walletType, required int index, String? name});

  Future<String?> getBackupDeviceID();
}

class AccountServiceImpl extends AccountService {
  final TezosBeaconService _tezosBeaconService;
  final ConfigurationService _configurationService;
  final AndroidBackupChannel _androidBackupChannel = AndroidBackupChannel();
  final IOSBackupChannel _iosBackupChannel = IOSBackupChannel();
  final BackupService _backupService;
  final nft.AddressService _nftCollectionAddressService;
  final AddressService _addressService;
  final CloudManager _cloudObject;

  AccountServiceImpl(
    this._tezosBeaconService,
    this._configurationService,
    this._backupService,
    this._nftCollectionAddressService,
    this._addressService,
    this._cloudObject,
  );

  @override
  Future<List<WalletAddress>> createNewWallet(
      {String name = '', String passphrase = ''}) async {
    final uuid = const Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.createKey(passphrase, name);
    log.fine('[AccountService] Created persona $uuid}');

    await _addressService.registerPrimaryAddress(
        info: primary_address_channel.AddressInfo(
      uuid: uuid,
      chain: 'ethereum',
      index: 0,
    ));

    final wallets = await insertNextAddressFromUuid(uuid, WalletType.MultiChain,
        name: name);
    await androidBackupKeys();
    return wallets;
  }

  @override
  Future<WalletStorage> importWords(String words, String passphrase,
      {WalletType walletType = WalletType.MultiChain}) async {
    late String firstEthAddress;
    try {
      firstEthAddress =
          await LibAukDart.calculateFirstEthAddress(words, passphrase);
    } catch (e) {
      rethrow;
    }

    final addresses = _cloudObject.addressObject.getAllAddresses()
      ..unique((element) => element.uuid);
    for (final address in addresses) {
      final ethAddress = await address.wallet.getETHAddress();
      if (ethAddress == firstEthAddress) {
        return address.wallet;
      }
    }

    final uuid = const Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.importKey(
        words, passphrase, '', DateTime.now().microsecondsSinceEpoch);

    if (Platform.isAndroid) {
      final backupAccounts = await _androidBackupChannel.restoreKeys();
      await _androidBackupChannel
          .backupKeys([...backupAccounts.map((e) => e.uuid), uuid]);
    }

    log.fine('[AccountService] imported persona $uuid');
    return walletStorage;
  }

  @override
  Future<WalletStorage> getDefaultAccount() async {
    final defaultWallet = await _getDefaultWallet();
    if (defaultWallet == null) {
      throw AccountException(message: 'Default wallet not found');
    }
    return defaultWallet;
  }

  @override
  Future<WalletIndex> getAccountByAddress({
    required String chain,
    required String address,
  }) async {
    switch (chain.caip2Namespace) {
      case Wc2Chain.ethereum:
      case Wc2Chain.tezos:
        final walletAddress = _cloudObject.addressObject.findByAddress(address);
        if (walletAddress != null) {
          return WalletIndex(
              WalletStorage(walletAddress.uuid), walletAddress.index);
        }
    }
    throw AccountException(
      message: 'Wallet not found. Chain $chain, address: $address',
    );
  }

  Future<WalletStorage?> _getDefaultWallet() async {
    /// we can improve this by checking if the wallet is exist in the server
    String? uuid;
    if (Platform.isIOS) {
      final uuids = await _iosBackupChannel.getUUIDsFromKeychain();
      uuid = uuids.firstOrNull;
    } else {
      final accounts = await _androidBackupChannel.restoreKeys();
      uuid = accounts.firstOrNull?.uuid;
    }

    if (uuid == null) {
      return null;
    }
    return LibAukDart.getWallet(uuid);
  }

  Future<WalletAddress> getPrimaryWallet() async {
    final primaryAddress =
        await injector<AddressService>().getPrimaryAddressInfo();
    if (primaryAddress == null) {
      log.info('[AccountService] getPrimaryWallet - '
          'PrimaryAddressInfo not found');
      unawaited(Sentry.captureMessage(
          '[PrimaryAddressInfo] PrimaryAddressInfo found'));
      throw AccountException(message: 'PrimaryAddressInfo found');
    }
    var addresses =
        _cloudObject.addressObject.getAddressesByUuid(primaryAddress.uuid);

    if (addresses.isEmpty) {
      await _restoreAddressesFromOS();

      await Future.delayed(const Duration(seconds: 1));
      addresses =
          _cloudObject.addressObject.getAddressesByUuid(primaryAddress.uuid);
    }

    final primaryWallet = addresses
        .firstWhereOrNull((element) => element.index == primaryAddress.index);
    if (primaryWallet == null) {
      log.info('[AccountService] getPrimaryWallet - '
          'PrimaryWallet not found, primaryAddress: $primaryAddress');
      unawaited(
          Sentry.captureMessage('[PrimaryAddressInfo] No PrimaryWallet found'));
      throw AccountException(message: 'No PrimaryWallet found');
    }
    return primaryWallet;
  }

  Future deleteWalletAddress(WalletAddress walletAddress) async {
    await _cloudObject.addressObject.deleteAddress(walletAddress);
    await _nftCollectionAddressService.deleteAddresses([walletAddress.address]);

    final connections = _cloudObject.connectionObject.getConnections();
    Set<P2PPeer> bcPeers = {};

    log.info('[AccountService] deletePersona - '
        'deleteConnections ${connections.length}');
    for (var connection in connections) {
      switch (connection.connectionType) {
        case 'beaconP2PPeer':
          if (walletAddress.uuid ==
                  connection.beaconConnectConnection?.personaUuid &&
              walletAddress.index ==
                  connection.beaconConnectConnection?.index) {
            await _cloudObject.connectionObject.deleteConnections([connection]);
            final bcPeer = connection.beaconConnectConnection?.peer;
            if (bcPeer != null) {
              bcPeers.add(bcPeer);
            }
          }

        // Note: Should app delete feralFileWeb3 too ??
      }
    }

    try {
      for (var peer in bcPeers) {
        await _tezosBeaconService.removePeer(peer);
      }
    } catch (exception) {
      unawaited(Sentry.captureException(exception));
    }
  }

  @override
  Future deleteLinkedAccount(Connection connection) async {
    await _cloudObject.connectionObject.deleteConnections([connection]);
    final addressIndexes = connection.addressIndexes;
    await Future.wait(addressIndexes.map((element) async {
      await setHideLinkedAccountInGallery(element.address, false);
    }));
    await _nftCollectionAddressService
        .deleteAddresses(addressIndexes.map((e) => e.address).toList());
  }

  @override
  Future<Connection> linkManuallyAddress(String address, CryptoType cryptoType,
      {String? name}) async {
    String checkSumAddress = address;
    if (cryptoType == CryptoType.ETH || cryptoType == CryptoType.USDC) {
      checkSumAddress = address.getETHEip55Address();
    }
    final walletAddress = _cloudObject.addressObject.getAllAddresses();
    if (walletAddress.any((element) => element.address == checkSumAddress)) {
      throw LinkAddressException(message: 'already_imported_address'.tr());
    }
    final doubleConnections = _cloudObject.connectionObject
        .getConnectionsByAccountNumber(checkSumAddress);
    if (doubleConnections.isNotEmpty) {
      throw LinkAddressException(message: 'already_viewing_address'.tr());
    }
    final connection = Connection(
      key: checkSumAddress,
      name: name ?? cryptoType.source,
      data: '{"blockchain":"${cryptoType.source}"}',
      connectionType: ConnectionType.manuallyAddress.rawValue,
      accountNumber: checkSumAddress,
      createdAt: DateTime.now(),
    );

    await _cloudObject.connectionObject.writeConnection(connection);
    await _nftCollectionAddressService.addAddresses([checkSumAddress]);
    return connection;
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

    await _cloudObject.connectionObject.writeConnection(connection);
  }

  @override
  bool isLinkedAccountHiddenInGallery(String address) =>
      _configurationService.isLinkedAccountHiddenInGallery(address);

  @override
  Future setHideLinkedAccountInGallery(String address, bool isEnabled) async {
    await _configurationService
        .setHideLinkedAccountInGallery([address], isEnabled);
    await _nftCollectionAddressService
        .setIsHiddenAddresses([address], isEnabled);
    unawaited(injector<SettingsDataService>().backup());
  }

  @override
  Future setHideAddressInGallery(List<String> addresses, bool isEnabled) async {
    await Future.wait(addresses.map(
        (e) => _cloudObject.addressObject.setAddressIsHidden(e, isEnabled)));
    await _nftCollectionAddressService.setIsHiddenAddresses(
        addresses, isEnabled);
    unawaited(injector<SettingsDataService>().backup());
  }

  @override
  Future androidBackupKeys() async {
    if (Platform.isAndroid) {
      final addresses = _cloudObject.addressObject.getAllAddresses();
      final uuids = addresses.map((e) => e.uuid).toSet().toList();

      await _androidBackupChannel.backupKeys(uuids);
    }
  }

  @override
  Future deleteAllKeys() async {
    final uuids = _cloudObject.addressObject
        .getAllAddresses()
        .map((e) => e.uuid)
        .toSet()
        .toList();
    for (var uuid in uuids) {
      await LibAukDart.getWallet(uuid).removeKeys();
    }
    if (Platform.isAndroid) {
      await _androidBackupChannel.deleteBlockStoreData();
    }
  }

  Future<void> _restoreUUIDs(List<String> uuids) async {
    final List<String> brokenUUIDs = [];
    for (var uuid in uuids) {
      final wallet = WalletStorage(uuid);
      if (!(await wallet.isWalletCreated())) {
        brokenUUIDs.add(uuid);
      }
    }
    uuids.removeWhere((element) => brokenUUIDs.contains(element));

    final addresses = _cloudObject.addressObject.getAllAddresses();
    final dbUuids = addresses.map((e) => e.uuid).toSet().toList();
    if (dbUuids.length == uuids.length &&
        dbUuids.every((element) => uuids.contains(element.toLowerCase()))) {
      //Database is up-to-date, skip migrating
      return;
    }

    // remove uuids not in keychain
    final uuidsToRemove = dbUuids
        .where((element) => !uuids.contains(element.toLowerCase()))
        .toList();

    for (var uuid in uuidsToRemove) {
      await _cloudObject.addressObject.deleteAddressesByUuid(uuid);
    }
    log.info('[_migration android/ios] uuids  : $uuids');
    for (var uuid in uuids) {
      //Cleanup duplicated uuids
      final oldAddresses = _cloudObject.addressObject.getAddressesByUuid(uuid);
      if (oldAddresses.isEmpty) {
        await insertNextAddressFromUuid(uuid, WalletType.MultiChain);
      }
    }
  }

  Future _androidRestoreKeys() async {
    if (Platform.isAndroid) {
      final accounts = await _androidBackupChannel.restoreKeys();

      final uuids = accounts.map((e) => e.uuid.toLowerCase()).toSet().toList();

      await _restoreUUIDs(uuids);

      await androidBackupKeys();
    }
  }

  @override
  Future<Connection> nameLinkedAccount(
      Connection connection, String name) async {
    connection.name = name;
    await _cloudObject.connectionObject.writeConnection(connection);
    return connection;
  }

  Future<Connection?> getExistingAccount(String accountNumber) async {
    final existingConnections = _cloudObject.connectionObject
        .getConnectionsByAccountNumber(accountNumber);

    if (existingConnections.isEmpty) {
      return null;
    }

    return existingConnections.first;
  }

  @override
  Future<bool?> isAndroidEndToEndEncryptionAvailable() =>
      _androidBackupChannel.isEndToEndEncryptionAvailable();

  @override
  Future<List<String>> getAllAddresses({bool logHiddenAddress = false}) async {
    List<String> addresses = [];
    final walletAddress = _cloudObject.addressObject.getAllAddresses();
    addresses.addAll(walletAddress.map((e) => e.address));

    final linkedAccounts = _cloudObject.connectionObject.getLinkedAccounts();

    addresses.addAll(linkedAccounts.expand((e) => e.accountNumbers));
    if (logHiddenAddress) {
      log.fine(
          '[Account Service] all addresses (persona ${walletAddress.length}): '
          '${addresses.join(", ")}');
      final hiddenAddresses = walletAddress
          .where((element) => element.isHidden)
          .map((e) => e.address.maskOnly(5))
          .toList()
        ..addAll(_configurationService.getLinkedAccountsHiddenInGallery());
      log.fine(
          "[Account Service] hidden addresses: ${hiddenAddresses.join(", ")}");
    }

    return addresses;
  }

  @override
  Future<List<String>> getAddress(String blockchain,
      {bool withViewOnly = false}) async {
    // Full accounts
    final walletAddresses = _cloudObject.addressObject.getAddressesByType(
        CryptoType.fromSource(blockchain.toLowerCase()).source);

    final addresses = walletAddresses.map((e) => e.address).toList();

    if (withViewOnly) {
      final connections = _cloudObject.connectionObject.getLinkedAccounts();
      for (var connection in connections) {
        if (connection.accountNumber.isEmpty) {
          continue;
        }
        final cryptoType =
            CryptoType.fromAddress(connection.accountNumber).source;
        if (cryptoType.toLowerCase() == blockchain.toLowerCase()) {
          addresses.add(connection.accountNumber);
        }
      }
    }

    return addresses;
  }

  @override
  Future<List<String>> getShowedAddresses() async {
    List<String> addresses = [];

    final walletAddress =
        _cloudObject.addressObject.findAddressesWithHiddenStatus(false);
    addresses.addAll(walletAddress.map((e) => e.address).toList());

    final linkedAccounts = _cloudObject.connectionObject.getLinkedAccounts();
    final hiddenLinkedAccounts =
        _configurationService.getLinkedAccountsHiddenInGallery();

    for (final linkedAccount in linkedAccounts) {
      for (final addressIndex in linkedAccount.addressIndexes) {
        if (hiddenLinkedAccounts.contains(addressIndex.address)) {
          continue;
        }
        addresses.add(addressIndex.address);
      }
    }

    return addresses;
  }

  @override
  Future<bool> addAddressWallet(
      String uuid, List<AddressInfo> addresses) async {
    bool result = false;
    final replacedConnections =
        await removeDoubleViewOnly(addresses.map((e) => e.address).toList());
    if (replacedConnections.isNotEmpty) {
      result = true;
    }

    final timestamp = DateTime.now();
    final walletAddresses = addresses
        .map((e) => WalletAddress(
            address: e.address,
            uuid: uuid,
            index: e.index,
            cryptoType: e.getCryptoType().source,
            createdAt: timestamp,
            name: replacedConnections
                    .firstWhereOrNull((element) =>
                        element.accountNumber == e.address &&
                        element.name.isNotEmpty)
                    ?.name ??
                e.getCryptoType().source))
        .toList();
    await _cloudObject.addressObject.insertAddresses(walletAddresses);
    await _nftCollectionAddressService
        .addAddresses(addresses.map((e) => e.address).toList());
    return result;
  }

  @override
  Future<List<AddressIndex>> getHiddenAddressIndexes() async {
    List<AddressIndex> hiddenAddresses = [];
    final hiddenWalletAddresses =
        _cloudObject.addressObject.findAddressesWithHiddenStatus(true);
    hiddenAddresses
        .addAll(hiddenWalletAddresses.map((e) => e.addressIndex).toList());

    final linkedAccounts = _cloudObject.connectionObject.getLinkedAccounts();
    final hiddenLinkedAccounts =
        _configurationService.getLinkedAccountsHiddenInGallery();

    for (final linkedAccount in linkedAccounts) {
      for (final addressIndex in linkedAccount.addressIndexes) {
        if (hiddenLinkedAccounts.contains(addressIndex.address)) {
          hiddenAddresses.add(addressIndex);
        }
      }
    }

    return hiddenAddresses.toSet().toList();
  }

  @override
  Future<void> deleteAddressWallet(WalletAddress walletAddress) async {
    await _cloudObject.addressObject.deleteAddress(walletAddress);
    await _nftCollectionAddressService.deleteAddresses([walletAddress.address]);
    switch (CryptoType.fromSource(walletAddress.cryptoType)) {
      case CryptoType.ETH:
        final connections = _cloudObject.connectionObject
            .getConnectionsByType(ConnectionType.dappConnect2.rawValue);
        for (var connection in connections) {
          if (connection.accountNumber.contains(walletAddress.address)) {
            await _cloudObject.connectionObject.deleteConnections([connection]);
          }
        }
        return;
      case CryptoType.XTZ:
        final connections = _cloudObject.connectionObject
            .getConnectionsByType(ConnectionType.beaconP2PPeer.rawValue);

        for (var connection in connections) {
          if (connection.beaconConnectConnection?.personaUuid ==
                  walletAddress.uuid &&
              connection.beaconConnectConnection?.index ==
                  walletAddress.index) {
            await _cloudObject.connectionObject.deleteConnections([connection]);
          }
        }
        return;
      default:
        return;
    }
  }

  @override
  Future<void> updateAddressWallet(WalletAddress walletAddress) async {
    await _cloudObject.addressObject.updateAddresses([walletAddress]);
  }

  @override
  Future<void> migrateAccount() async {
    log.info('[AccountService] migrateAccount');
    final cloudDb = injector<CloudDatabase>();
    final isDoneOnboarding = _configurationService.isDoneOnboarding();
    final result = await Future.wait([
      _getDefaultWallet(),
      _addressService.getPrimaryAddressInfo(),
      cloudDb.addressDao.getAllAddresses(),
    ]);

    // make sure to call restoreKeys to activate all seed data
    final defaultWallet = result[0] as WalletStorage?;
    final addressInfo = result[1] as primary_address_channel.AddressInfo?;
    final localCloudDB = result[2]! as List<WalletAddress>;

    log.info('[AccountService] migrateAccount - '
        'addressInfo: ${addressInfo?.uuid}, '
        'localCloudDB: ${localCloudDB.length}, '
        'isDoneOnboarding: $isDoneOnboarding, '
        'defaultWallet: ${defaultWallet?.uuid}');

    /// in previous version, we assume that if user has primary address,
    /// that is their default account (using to save cloud data base)
    /// but if user has no primary address, but have backup version,
    /// we will take the first uuid as default account
    // case 1: complete new user, no primary address, no backup keychain
    // nothing to do other than create new wallet
    if (addressInfo == null && defaultWallet == null) {
      log.info('[AccountService] migrateAccount: case 1 complete new user');
      await createNewWallet();
      unawaited(_cloudObject.setMigrated());
      log.info('[AccountService] migrateAccount: case 1 finished');
      return;
    }

    // case 2: update app from old version using did key
    if (addressInfo == null && isDoneOnboarding && defaultWallet != null) {
      log.info('[AccountService] migrateAccount: '
          'case 2 update app from old version using did key');
      await _addressService.registerPrimaryAddress(
        info: primary_address_channel.AddressInfo(
            uuid: defaultWallet.uuid, chain: 'ethereum', index: 0),
        withDidKey: true,
      );
      await _cloudObject.copyDataFrom(cloudDb);
      unawaited(cloudDb.removeAll());

      unawaited(_cloudObject.setMigrated());
      // ensure that we have addresses;
      unawaited(_ensureHavingWalletAddress());
      log.info('[AccountService] migrateAccount: case 2 finished');
      return;
    }

    // case 3: restore app from old version using did key
    // we register first uuid as primary address (with didKey = true)
    // then restore
    if (addressInfo == null && !isDoneOnboarding && defaultWallet != null) {
      log.info('[AccountService] migrateAccount: '
          'case 3 restore app from old version using did key');
      await _addressService.registerPrimaryAddress(
        info: primary_address_channel.AddressInfo(
            uuid: defaultWallet.uuid, chain: 'ethereum', index: 0),
        withDidKey: true,
      );

      await injector<SettingsDataService>()
          .restoreSettingsData(fromProfileData: true);
      await _backupService.restoreCloudDatabase();

      // ensure that we have addresses;
      unawaited(_ensureHavingWalletAddress());
      log.info('[AccountService] migrateAccount: case 3 finished');
      return;
    }

    // from case 4, user has primary address,
    // we need to check if user has migrate to account-settings;

    // this is to reduce loading time
    bool didMigrate = _configurationService.didMigrateToAccountSetting();
    if (!didMigrate) {
      didMigrate =
          await _cloudObject.addressObject.accountSettingsDB.didMigrate();
    }

    log.info('[AccountService] migrateAccount - didMigrate: $didMigrate');

    // case 4: migrated user
    if (didMigrate) {
      log.info('[AccountService] migrateAccount: case 4 migrated user');
      unawaited(_cloudObject.downloadAll());
      log.info('[AccountService] migrateAccount: case 4 finished');
      return;
    }

    // if user has not migrated, there are 2 cases:
    // update app and restore app
    // we need to check if user using ethereum or tezos for each case to migrate

    // case 5: update app from old version using primary address
    if (isDoneOnboarding) {
      log.info('[AccountService] migrateAccount: '
          'case 5 update app from old version using primary address');
      // migrate to ethereum first, then upload to account-settings
      if (!addressInfo!.isEthereum) {
        await _addressService.migrateToEthereumAddress(addressInfo);
      }
      await _cloudObject.copyDataFrom(cloudDb);
      unawaited(_cloudObject
          .setMigrated()
          .then((_) => unawaited(cloudDb.removeAll())));
      log.info('[AccountService] migrateAccount: case 5 finished');
    }

    // case 6: restore app from old version using primary address
    else {
      log.info('[AccountService] migrateAccount: '
          'case 6 restore app from old version using primary address');
      await injector<SettingsDataService>()
          .restoreSettingsData(fromProfileData: true);
      await _backupService.restoreCloudDatabase();
      // now all data are in _cloudObject cache
      if (!addressInfo!.isEthereum) {
        // migrate to tezos
        await _addressService.migrateToEthereumAddress(addressInfo);

        await _cloudObject.uploadCurrentCache();
      }

      unawaited(_cloudObject.setMigrated());
      log.info('[AccountService] migrateAccount: case 6 finished');
    }

    // ensure that we have addresses;
    unawaited(_ensureHavingWalletAddress());
  }

  Future<void> _ensureHavingWalletAddress() async {
    log.info('[AccountService] _ensureHavingWalletAddress');
    final allAddresses = _cloudObject.addressObject.getAllAddresses();
    if (allAddresses.isEmpty) {
      log.info('[AccountService] _ensureHavingWalletAddress - no addresses');
      await _restoreAddressesFromOS();
      return;
    }
    final primaryAddress =
        await injector<AddressService>().getPrimaryAddressInfo();
    if (primaryAddress == null) {
      return;
    }
    if (allAddresses.any((element) =>
        element.uuid == primaryAddress.uuid &&
        element.index == primaryAddress.index &&
        element.cryptoType.toLowerCase() == primaryAddress.chain)) {
      return;
    }
    await insertAddressAtIndexAndUuid(primaryAddress.uuid,
        name: '', walletType: WalletType.Ethereum, index: primaryAddress.index);
  }

  @override
  Future<WalletAddress?> getWalletByAddress(String address) async =>
      _cloudObject.addressObject.findByAddress(address);

  @override
  Future<List<Connection>> removeDoubleViewOnly(List<String> addresses) async {
    final List<Connection> result = [];
    final linkedAccounts = _cloudObject.connectionObject.getLinkedAccounts();
    final viewOnlyAddresses = linkedAccounts
        .where((con) => addresses.contains(con.accountNumber))
        .toList();
    if (viewOnlyAddresses.isNotEmpty) {
      result.addAll(viewOnlyAddresses);
      await _cloudObject.connectionObject.deleteConnections(viewOnlyAddresses);
    }
    return result;
  }

  @override
  List<Connection> getAllViewOnlyAddresses() {
    final connections = _cloudObject.connectionObject.getLinkedAccounts();
    return connections;
  }

  @override
  List<WalletAddress> getWalletsAddress(CryptoType cryptoType) =>
      _cloudObject.addressObject.getAddressesByType(cryptoType.source);

  @override
  Future<List<WalletAddress>> insertNextAddress(WalletType walletType,
      {String? name}) async {
    final primaryAddress =
        await injector<AddressService>().getPrimaryAddressInfo();
    if (primaryAddress == null) {
      throw AccountException(message: 'Primary address not found');
    }
    return await insertNextAddressFromUuid(primaryAddress.uuid, walletType,
        name: name);
  }

  @override
  Future<List<WalletAddress>> insertNextAddressFromUuid(
      String uuid, WalletType walletType,
      {String? name}) async {
    final List<WalletAddress> addresses = [];
    final walletAddresses = _cloudObject.addressObject.getAddressesByUuid(uuid);
    final wallet = LibAukDart.getWallet(uuid);
    final ethIndexes = walletAddresses
        .where((element) => element.cryptoType == CryptoType.ETH.source)
        .map((e) => e.index)
        .toList();
    final ethIndex = _getNextIndex(ethIndexes);
    final tezIndexes = walletAddresses
        .where((element) => element.cryptoType == CryptoType.XTZ.source)
        .map((e) => e.index)
        .toList();
    final tezIndex = _getNextIndex(tezIndexes);
    final ethAddress = WalletAddress(
        address: await wallet.getETHEip55Address(index: ethIndex),
        uuid: uuid,
        index: ethIndex,
        cryptoType: CryptoType.ETH.source,
        createdAt: DateTime.now(),
        name: name ?? CryptoType.ETH.source);
    final tezAddress = WalletAddress(
        address: await wallet.getTezosAddress(index: tezIndex),
        uuid: uuid,
        index: tezIndex,
        cryptoType: CryptoType.XTZ.source,
        createdAt: DateTime.now(),
        name: name ?? CryptoType.XTZ.source);
    switch (walletType) {
      case WalletType.Ethereum:
        addresses.add(ethAddress);
      case WalletType.Tezos:
        addresses.add(tezAddress);
      default:
        addresses.addAll([ethAddress, tezAddress]);
    }
    await removeDoubleViewOnly(addresses.map((e) => e.address).toList());
    await _cloudObject.addressObject.insertAddresses(addresses);
    await injector<nft_address.AddressService>()
        .addAddresses(addresses.map((e) => e.address).toList());
    return addresses;
  }

  @override
  Future<String?> getBackupDeviceID() async {
    if (Platform.isIOS) {
      final String? deviceId = await _iosBackupChannel.getBackupDeviceID();

      return deviceId ?? await getDeviceID();
    } else {
      return await getDeviceID();
    }
  }

  Future<void> _migrationFromKeychain() async {
    if (!Platform.isIOS) {
      return;
    }
    final personaUUIDs = await _iosBackupChannel.getUUIDsFromKeychain();
    await _restoreUUIDs(personaUUIDs);
  }

  Future<void> _restoreAddressesFromOS() async {
    if (Platform.isIOS) {
      await _migrationFromKeychain();
    } else {
      await _androidRestoreKeys();
    }
  }

  @override
  Future<List<WalletAddress>> insertAddressAtIndexAndUuid(String uuid,
      {required WalletType walletType,
      required int index,
      String? name}) async {
    List<WalletAddress> walletAddresses = [];
    switch (walletType) {
      case WalletType.Ethereum:
        walletAddresses = [
          await _generateETHAddressByIndex(uuid, index, name: name)
        ];
      case WalletType.Tezos:
        walletAddresses = [
          await _generateTezosAddressByIndex(uuid, index, name: name),
        ];
      case WalletType.MultiChain:
        walletAddresses = [
          await _generateETHAddressByIndex(uuid, index, name: name),
          await _generateTezosAddressByIndex(uuid, index, name: name)
        ];
    }
    await removeDoubleViewOnly(walletAddresses.map((e) => e.address).toList());
    await _cloudObject.addressObject.insertAddresses(walletAddresses);
    await injector<nft_address.AddressService>()
        .addAddresses(walletAddresses.map((e) => e.address).toList());
    return walletAddresses;
  }

  Future<WalletAddress> _generateETHAddressByIndex(String uuid, int index,
          {String? name}) async =>
      WalletAddress(
          address:
              await LibAukDart.getWallet(uuid).getETHEip55Address(index: index),
          uuid: uuid,
          index: index,
          cryptoType: CryptoType.ETH.source,
          createdAt: DateTime.now(),
          name: name ?? CryptoType.ETH.source);

  Future<WalletAddress> _generateTezosAddressByIndex(String uuid, int index,
          {String? name}) async =>
      WalletAddress(
          address:
              await LibAukDart.getWallet(uuid).getTezosAddress(index: index),
          uuid: uuid,
          index: index,
          cryptoType: CryptoType.XTZ.source,
          createdAt: DateTime.now(),
          name: name ?? CryptoType.XTZ.source);

  int _getNextIndex(List<int> indexes) => (indexes.maxOrNull ?? -1) + 1;
}

class AccountException implements Exception {
  final String? message;

  AccountException({this.message});
}

class LinkAddressException implements Exception {
  final String message;

  LinkAddressException({required this.message});
}
