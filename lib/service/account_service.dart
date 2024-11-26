//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/keychain_service.dart';
import 'package:autonomy_flutter/util/android_backup_channel.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/exception.dart';
import 'package:autonomy_flutter/util/ios_backup_channel.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart'
    as primary_address_channel;
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/services/address_service.dart' as nft;
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class AccountService {
  Future<void> migrateAccount(Future<dynamic> Function() createLoginJwt);

  // get all addresses
  List<WalletAddress> getWalletsAddress(CryptoType cryptoType);

  Future<WalletAddress> nameLinkedAccount(WalletAddress address, String name);

  Future<WalletAddress> linkManuallyAddress(
      String address, CryptoType cryptoType,
      {String? name});

  Future deleteLinkedAccount(Connection connection);

  Future linkIndexerTokenID(String indexerTokenID);

  Future setHideLinkedAccountInGallery(String address, bool isEnabled);

  Future setHideAddressInGallery(List<String> addresses, bool isEnabled);

  Future<List<String>> getAllAddresses({bool logHiddenAddress = false});

  Future<List<String>> getAddress(String blockchain,
      {bool withViewOnly = false});

  Future<List<AddressIndex>> getHiddenAddressIndexes();

  Future<List<String>> getShowedAddresses();

  Future<void> updateAddressWallet(WalletAddress walletAddress);

  List<Connection> getAllViewOnlyAddresses();

  Future<String?> getBackupDeviceID();
}

class AccountServiceImpl extends AccountService {
  final ConfigurationService _configurationService;
  final AndroidBackupChannel _androidBackupChannel = AndroidBackupChannel();
  final IOSBackupChannel _iosBackupChannel = IOSBackupChannel();
  final nft.AddressService _nftCollectionAddressService;
  final AddressService _addressService;
  final CloudManager _cloudObject;

  AccountServiceImpl(
    this._tezosBeaconService,
    this._configurationService,
    this._nftCollectionAddressService,
    this._addressService,
    this._cloudObject,
  );

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

    final uuids = await _getUuidsFromLocal();

    String? uuid = uuids.firstOrNull;

    if (uuid == null) {
      return null;
    }
    return LibAukDart.getWallet(uuid);
  }

  Future<List<String>> _getUuidsFromLocal() async {
    if (Platform.isIOS) {
      return await _iosBackupChannel.getUUIDsFromKeychain();
    } else {
      final accounts = await _androidBackupChannel.restoreKeys();
      return accounts.map((e) => e.uuid).toList();
    }
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
    await _nftCollectionAddressService
        .deleteAddresses(addressIndexes.map((e) => e.address).toList());
  }

  @override
  Future<WalletAddress> linkManuallyAddress(
      String address, CryptoType cryptoType,
      {String? name}) async {
    String checkSumAddress = address;
    if (cryptoType == CryptoType.ETH || cryptoType == CryptoType.USDC) {
      checkSumAddress = address.getETHEip55Address();
    }
    final walletAddress = _cloudObject.addressObject.getAllAddresses();
    if (walletAddress.any((element) => element.address == checkSumAddress)) {
      throw LinkAddressException(message: 'already_imported_address'.tr());
    }
    final doubleAddress = _cloudObject.addressObject
        .getAllAddresses()
        .firstWhereOrNull((element) => element.address == checkSumAddress);
    if (doubleAddress != null) {
      throw LinkAddressException(message: 'already_viewing_address'.tr());
    }
    final walletAddress = WalletAddress(
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
  Future setHideLinkedAccountInGallery(String address, bool isEnabled) async {
    final connection = _cloudObject.connectionObject
        .getConnectionsByAccountNumber(address)
        .firstOrNull;
    if (connection == null) {
      return;
    }
    await _cloudObject.connectionObject
        .writeConnection(connection.copyWith(isHidden: isEnabled));
    await _nftCollectionAddressService
        .setIsHiddenAddresses([address], isEnabled);
  }

  @override
  Future setHideAddressInGallery(List<String> addresses, bool isEnabled) async {
    await Future.wait(addresses.map(
        (e) => _cloudObject.addressObject.setAddressIsHidden(e, isEnabled)));
    await _nftCollectionAddressService.setIsHiddenAddresses(
        addresses, isEnabled);
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
    if (Platform.isAndroid) {
      final accounts = await _androidBackupChannel.restoreKeys();
      final uuids = accounts.map((e) => e.uuid).toSet().toList();
      await _removeUUIDs(uuids);
      await _androidBackupChannel.deleteBlockStoreData();
    } else {
      final uuids = await _iosBackupChannel.getUUIDsFromKeychain();
      await _removeUUIDs(uuids);
      await injector<KeychainService>().clearKeychainItems();
    }
  }

  Future<void> _removeUUIDs(List<String> uuids) async {
    for (var uuid in uuids) {
      await LibAukDart.getWallet(uuid).removeKeys();
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
  Future<WalletAddress> nameLinkedAccount(
      WalletAddress address, String name) async {
    final newAddress = address.copyWith(name: name);
    await _cloudObject.addressObject.updateAddresses([newAddress]);
    return newAddress;
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

    addresses.addAll(linkedAccounts.map((e) => e.accountNumber).toList());
    if (logHiddenAddress) {
      log.fine(
          '[Account Service] all addresses (persona ${walletAddress.length}): '
          '${addresses.join(", ")}');
      final hiddenAddresses = walletAddress
          .where((element) => element.isHidden)
          .map((e) => e.address.maskOnly(5))
          .toList()
        ..addAll(linkedAccounts
            .where((element) => element.isHidden)
            .map((e) => e.accountNumber)
            .toList());
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

    final linkedAccounts = _cloudObject.connectionObject
        .getLinkedAccounts()
        .where((element) => element.isViewing);

    addresses.addAll(linkedAccounts.map((e) => e.accountNumber));

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
        linkedAccounts.where((element) => element.isHidden).toList();

    hiddenAddresses.addAll(hiddenLinkedAccounts
        .expand((element) => element.addressIndexes.toList()));

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
  Future<void> migrateAccount(Future<dynamic> Function() createLoginJwt) async {
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

    /// Migrate passkeys note:
    /// To simplify this migration on mobile, we will not support restoring
    /// backed-up data for users who uninstall and then reinstall apps that
    /// still use didKey and the Tezos primary address.
    /// The data that will not be restored includes playlists, settings,
    /// and derived addresses. However, we will automatically derive a pair
    /// of addresses for each wallet that users own.
    // case 1: complete new user, no primary address, no backup keychain
    // nothing to do other than create new wallet
    /// create passkeys, no need to migrate
    if (defaultWallet == null) {
      log.info('[AccountService] migrateAccount: case 1 complete new user');
      await createNewWallet(
        createLoginJwt: createLoginJwt,
      );
      unawaited(_cloudObject.setMigrated());
      log.info('[AccountService] migrateAccount: case 1 finished');
      return;
    }

    // case 2: update app from old version using did key
    // case 3: restore app from old version using did key
    // we won't restore data, just derive addresses automatically
    if (addressInfo == null) {
      log.info('[AccountService] migrateAccount: '
          'case 2/3 update/restore app from old version using did key');
      await _addressService.registerPrimaryAddress(
        info: primary_address_channel.AddressInfo(
          uuid: defaultWallet.uuid,
          chain: 'ethereum',
          index: 0,
        ),
      );
      await createLoginJwt();
      await _cloudObject.copyDataFrom(cloudDb);
      unawaited(cloudDb.removeAll());

      unawaited(_cloudObject.setMigrated());
      // ensure that we have addresses;
      unawaited(_ensureHavingWalletAddress());
      log.info('[AccountService] migrateAccount: case 2 finished');
      return;
    }

    // from case 4, user has primary address,
    // we need to check if user has migrate to account-settings;
    if (!addressInfo.isEthereum) {
      await _addressService.migrateToEthereumAddress(addressInfo);
    }
    await createLoginJwt();

    // we don't care for user use tezos primary address.
    // this is to reduce loading time
    bool didMigrate = _configurationService.didMigrateToAccountSetting();
    if (!didMigrate) {
      didMigrate =
          await _cloudObject.addressObject.accountSettingsDB.didMigrate();
      if (didMigrate) {
        unawaited(_configurationService.setMigrateToAccountSetting(true));
      }
    }

    log.info('[AccountService] migrateAccount - didMigrate: $didMigrate');

    // case 4: migrated user
    if (didMigrate) {
      log.info('[AccountService] migrateAccount: case 4 migrated user');
      await _cloudObject.downloadAll();
      log.info('[AccountService] migrateAccount: case 4 finished');
      return;
    }

    // if user has not migrated, there are 2 cases:
    // update app and restore app
    // case 5/6: update/restore app from old version using primary address

    if (isDoneOnboarding) {
      log.info('[AccountService] migrateAccount: '
          'case 5 update app from old version using primary address');
      // migrate to ethereum first, then upload to account-settings

      await _cloudObject.copyDataFrom(cloudDb);
      unawaited(_cloudObject.setMigrated());
      log.info('[AccountService] migrateAccount: case 5 finished');
    }

    unawaited(cloudDb.removeAll());
    unawaited(_cloudObject.setMigrated());

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
    await _insertWalletAddresses(addresses);
    return addresses;
  }

  Future<void> _insertWalletAddresses(List<WalletAddress> addresses) async {
    await _cloudObject.addressObject.insertAddresses(addresses);
    await injector<nft.AddressService>()
        .addAddresses(addresses.map((e) => e.address).toList());
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
    await _insertWalletAddresses(walletAddresses);
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
