//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/android_backup_channel.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
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
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

abstract class AccountService {
  Future<List<WalletAddress>> deriveAddressFromFirstPersona(
      WalletType walletType);

  Future<List<WalletAddress>> getWalletsAddress(CryptoType cryptoType);

  Future<WalletStorage> getDefaultAccount();

  Future<WalletAddress> getOrCreatePrimaryWallet();

  Future<WalletIndex> getAccountByAddress({
    required String chain,
    required String address,
  });

  Future androidBackupKeys();

  Future deleteAllKeys();

  Future<List<Connection>> removeDoubleViewOnly(List<String> addresses);

  Future<bool?> isAndroidEndToEndEncryptionAvailable();

  Future androidRestoreKeys();

  Future<List<WalletAddress>> createNewWallet(
      {String name = '', String passphrase = '', bool isDefault = false});

  Future<WalletStorage> importPersona(String words, String passphrase,
      {WalletType walletType = WalletType.Autonomy});

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

  Future<bool> addAddressPersona(String uuid, List<AddressInfo> addresses);

  Future<void> deleteAddressPersona(WalletAddress walletAddress);

  Future<WalletAddress?> getAddressPersona(String address);

  Future<void> updateAddressPersona(WalletAddress walletAddress);

  Future<void> restoreIfNeeded();

  List<Connection> getAllViewOnlyAddresses();

  Future<List<WalletAddress>> insertNextAddress(WalletType walletType,
      {String? name});

  Future<List<WalletAddress>> insertNextAddressFromUuid(
      String uuid, WalletType walletType,
      {String? name});

  Future<List<WalletAddress>> insertAddressAtIndexAndUuid(String uuid,
      {required WalletType walletType, required int index, String? name});

  Future<void> restoreUUIDs(List<String> personaUUIDs);
}

class AccountServiceImpl extends AccountService {
  final TezosBeaconService _tezosBeaconService;
  final ConfigurationService _configurationService;
  final AndroidBackupChannel _backupChannel = AndroidBackupChannel();
  final BackupService _backupService;
  final nft.AddressService _nftCollectionAddressService;
  final AddressService _addressService;
  final CloudObjects _cloudObject;
  final _defaultAccountLock = Lock();

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
      {String name = '',
      String passphrase = '',
      bool isDefault = false}) async {
    final uuid = const Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.createKey(passphrase, name);
    await androidBackupKeys();
    log.fine('[AccountService] Created persona $uuid}');
    if (isDefault) {
      await _addressService.registerPrimaryAddress(
          info: primary_address_channel.AddressInfo(
        uuid: uuid,
        chain: 'ethereum',
        index: 0,
      ));
    }
    final wallets =
        await insertNextAddressFromUuid(uuid, WalletType.Autonomy, name: name);
    return wallets;
  }

  @override
  Future<WalletStorage> importPersona(String words, String passphrase,
      {WalletType walletType = WalletType.Autonomy}) async {
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

    await androidBackupKeys();
    log.fine('[AccountService] imported persona $uuid');
    return walletStorage;
  }

  @override
  Future<WalletStorage> getDefaultAccount() async =>
      _defaultAccountLock.synchronized(() => _getDefaultAccount());

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

  Future<WalletStorage> _getDefaultAccount() async {
    final primaryWallet = await getPrimaryWallet();
    return LibAukDart.getWallet(primaryWallet.uuid);
  }

  Future<WalletAddress> getPrimaryWallet() async {
    final primaryAddress =
        await injector<AddressService>().getPrimaryAddressInfo();
    if (primaryAddress == null) {
      unawaited(Sentry.captureMessage(
          '[PrimaryAddressInfo] PrimaryAddressInfo found'));
      throw AccountException(message: 'PrimaryAddressInfo found');
    }
    var addresses =
        _cloudObject.addressObject.getAddressesByPersona(primaryAddress.uuid);

    if (addresses.isEmpty) {
      await MigrationUtil(injector()).migrationFromKeychain();
      await androidRestoreKeys();

      await Future.delayed(const Duration(seconds: 1));
      addresses =
          _cloudObject.addressObject.getAddressesByPersona(primaryAddress.uuid);
    }

    final primaryWallet = addresses
        .firstWhereOrNull((element) => element.index == primaryAddress.index);
    if (primaryWallet == null) {
      unawaited(
          Sentry.captureMessage('[PrimaryAddressInfo] No PrimaryWallet found'));
      throw AccountException(message: 'No PrimaryWallet found');
    }
    return primaryWallet;
  }

  @override
  Future<WalletAddress> getOrCreatePrimaryWallet() async {
    try {
      final primaryWallet = await getPrimaryWallet();
      return primaryWallet;
    } catch (exception) {
      if (exception is AccountException) {
        final walletAddresses = await createNewWallet(isDefault: true);
        return walletAddresses.firstWhere(
            (element) => element.cryptoType == CryptoType.ETH.source);
      } else {
        rethrow;
      }
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
            await _cloudObject.connectionObject.deleteConnection(connection);
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
    await _cloudObject.connectionObject.deleteConnection(connection);
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
    final personaAddress = _cloudObject.addressObject.getAllAddresses();
    if (personaAddress.any((element) => element.address == checkSumAddress)) {
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

    /// to do:
    /// after apply new onboarding, we disable view-only address at onboarding,
    /// therefore, we do not need to register primary address here
    final allAddresses = await _addressService.getAllEthereumAddress();
    if (allAddresses.isEmpty) {
      // for case when import view-only address,
      // the default account is not exist,
      // we should create new account,
      // derive ethereum and tezos address at index 0
      await getOrCreatePrimaryWallet();
    }
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

      await _backupChannel.backupKeys(uuids);
    }
  }

  @override
  Future deleteAllKeys() async {
    if (Platform.isAndroid) {
      await _backupChannel.deleteAllKeys();
    }
  }

  @override
  Future<void> restoreUUIDs(List<String> personaUUIDs) async {
    final List<String> brokenUUIDs = [];
    for (var uuid in personaUUIDs) {
      final wallet = WalletStorage(uuid);
      if (!(await wallet.isWalletCreated())) {
        brokenUUIDs.add(uuid);
      }
    }
    personaUUIDs.removeWhere((element) => brokenUUIDs.contains(element));

    final addresses = _cloudObject.addressObject.getAllAddresses();
    final dbUuids = addresses.map((e) => e.uuid).toSet().toList();
    if (dbUuids.length == personaUUIDs.length &&
        dbUuids
            .every((element) => personaUUIDs.contains(element.toLowerCase()))) {
      //Database is up-to-date, skip migrating
      return;
    }

    // remove uuids not in keychain
    final uuidsToRemove = dbUuids
        .where((element) => !personaUUIDs.contains(element.toLowerCase()))
        .toList();

    for (var uuid in uuidsToRemove) {
      await _cloudObject.addressObject.deleteAddressesByPersona(uuid);
    }
    log.info('[_migration android/ios] personaUUIDs  : $personaUUIDs');
    for (var personaUUID in personaUUIDs) {
      //Cleanup duplicated persona
      final oldAddresses =
          _cloudObject.addressObject.getAddressesByPersona(personaUUID);
      if (oldAddresses.isEmpty) {
        await insertNextAddressFromUuid(personaUUID, WalletType.Autonomy);
      }
    }
  }

  @override
  Future androidRestoreKeys() async {
    if (Platform.isAndroid) {
      final accounts = await _backupChannel.restoreKeys();

      final uuids = accounts.map((e) => e.uuid.toLowerCase()).toSet().toList();

      await restoreUUIDs(uuids);

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
      _backupChannel.isEndToEndEncryptionAvailable();

  @override
  Future<List<String>> getAllAddresses({bool logHiddenAddress = false}) async {
    if (_configurationService.isDemoArtworksMode()) {
      return [];
    }

    List<String> addresses = [];
    final addressPersona = _cloudObject.addressObject.getAllAddresses();
    addresses.addAll(addressPersona.map((e) => e.address));

    final linkedAccounts = _cloudObject.connectionObject.getLinkedAccounts();

    addresses.addAll(linkedAccounts.expand((e) => e.accountNumbers));
    if (logHiddenAddress) {
      log.fine(
          '[Account Service] all addresses (persona ${addressPersona.length}): '
          '${addresses.join(", ")}');
      final hiddenAddresses = addressPersona
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
    if (_configurationService.isDemoArtworksMode()) {
      return [await getDemoAccount()];
    }

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
  Future<bool> addAddressPersona(
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
    // check if primary address is not set
    final primaryAddressInfo = await _addressService.getPrimaryAddressInfo();
    if (primaryAddressInfo == null) {
      try {
        final addressInfo = await _addressService.pickAddressAsPrimary();
        await _addressService.registerPrimaryAddress(
            info: addressInfo, withDidKey: true);
      } catch (e, stacktrace) {
        log.info('Error while picking primary address', e, stacktrace);
        // rethrow;
      }
    }
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
  Future<void> deleteAddressPersona(WalletAddress walletAddress) async {
    await _cloudObject.addressObject.deleteAddress(walletAddress);
    await _nftCollectionAddressService.deleteAddresses([walletAddress.address]);
    switch (CryptoType.fromSource(walletAddress.cryptoType)) {
      case CryptoType.ETH:
        final connections = _cloudObject.connectionObject
            .getConnectionsByType(ConnectionType.dappConnect2.rawValue);
        for (var connection in connections) {
          if (connection.accountNumber.contains(walletAddress.address)) {
            await _cloudObject.connectionObject.deleteConnection(connection);
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
            await _cloudObject.connectionObject.deleteConnection(connection);
          }
        }
        return;
      default:
        return;
    }
  }

  @override
  Future<void> updateAddressPersona(WalletAddress walletAddress) async {
    await _cloudObject.addressObject.updateAddress(walletAddress);
  }

  @override
  Future<void> restoreIfNeeded() async {
    final iapService = injector<IAPService>();
    final migrationUtil = MigrationUtil(this);
    await androidRestoreKeys();
    await migrationUtil.migrationFromKeychain();
    final addresses = _cloudObject.addressObject.getAllAddresses();

    final hasAddresses = addresses.isNotEmpty;
    if (!hasAddresses) {
      await _configurationService.setDoneOnboarding(hasAddresses);
    }
    if (_configurationService.isDoneOnboarding()) {
      // dont need to force update, because
      await injector<AuthService>().getAuthToken();
      await _cloudObject.downloadAll();
      return;
    }
    // for user who did not onboarded before
    if (hasAddresses) {
      unawaited(_configurationService.setOldUser());
      final backupVersion = await _backupService.getBackupVersion();
      if (backupVersion.isNotEmpty) {
        // if user has backup, restore from cloud
        unawaited(_backupService.restoreCloudDatabase());
        unawaited(injector<MetricClientService>()
            .mixPanelClient
            .initIfDefaultAccount());
      }

      // make sure has addresses
      // case 1: user has no backup,
      // case 2: user has backup but no addresses
      final addresses = await _addressService.getAllEthereumAddress();
      if (addresses.isEmpty) {
        await getOrCreatePrimaryWallet();
      }

      // now has addresses, check if primary address is exist
      final primaryAddressInfo = await _addressService.getPrimaryAddressInfo();

      // if primary address is not exist, pick one and register as primary
      if (primaryAddressInfo == null) {
        final primaryAddressInfo = await _addressService.pickAddressAsPrimary();
        await _addressService.registerPrimaryAddress(
            info: primaryAddressInfo, withDidKey: true);
      }
    } else {
      // for new user, create default persona
      await createNewWallet(isDefault: true);
      await _configurationService.setDoneOnboarding(true);
      await _cloudObject.setMigrated();
      unawaited(injector<MetricClientService>()
          .mixPanelClient
          .initIfDefaultAccount());
    }

    unawaited(iapService.restore());
  }

  @override
  Future<WalletAddress?> getAddressPersona(String address) async =>
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
      await Future.forEach<Connection>(viewOnlyAddresses,
          (element) => _cloudObject.connectionObject.deleteConnection(element));
    }
    return result;
  }

  @override
  List<Connection> getAllViewOnlyAddresses() {
    final connections = _cloudObject.connectionObject.getLinkedAccounts();
    return connections;
  }

  @override
  Future<List<WalletAddress>> getWalletsAddress(CryptoType cryptoType) async =>
      _cloudObject.addressObject.getAddressesByType(cryptoType.source);

  @override
  Future<List<WalletAddress>> deriveAddressFromFirstPersona(
          WalletType walletType) async =>
      await insertNextAddress(walletType);

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
    final walletAddresses = _cloudObject.addressObject.findByWalletID(uuid);
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
      case WalletType.Autonomy:
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
