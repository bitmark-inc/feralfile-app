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
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/android_backup_channel.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/services/address_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import 'iap_service.dart';

abstract class AccountService {
  Future<WalletStorage> getDefaultAccount();

  Future<Persona> getOrCreateDefaultPersona();

  Future<WalletStorage?> getCurrentDefaultAccount();

  Future<WalletIndex> getAccountByAddress({
    required String chain,
    required String address,
  });

  Future androidBackupKeys();

  Future<List<Connection>> removeDoubleViewOnly(List<String> addresses);

  Future<bool?> isAndroidEndToEndEncryptionAvailable();

  Future androidRestoreKeys();

  Future<Persona> createPersona({String name = '', bool isDefault = false});

  Future<Persona> importPersona(String words,
      {WalletType walletType = WalletType.Autonomy});

  Future<Connection> nameLinkedAccount(Connection connection, String name);

  Future<Connection> linkManuallyAddress(String address, CryptoType cryptoType,
      {String? name});

  Future deletePersona(Persona persona);

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

  Future<bool> addAddressPersona(
      Persona newPersona, List<AddressInfo> addresses);

  Future<void> deleteAddressPersona(
      Persona persona, WalletAddress walletAddress);

  Future<WalletAddress?> getAddressPersona(String address);

  Future<void> updateAddressPersona(WalletAddress walletAddress);

  Future<void> restoreIfNeeded({bool isCreateNew = true});
}

class AccountServiceImpl extends AccountService {
  final CloudDatabase _cloudDB;
  final TezosBeaconService _tezosBeaconService;
  final ConfigurationService _configurationService;
  final AndroidBackupChannel _backupChannel = AndroidBackupChannel();
  final AuditService _auditService;
  final AutonomyService _autonomyService;
  final BackupService _backupService;
  final AddressService _addressService;

  final _defaultAccountLock = Lock();

  AccountServiceImpl(
    this._cloudDB,
    this._tezosBeaconService,
    this._configurationService,
    this._auditService,
    this._autonomyService,
    this._backupService,
    this._addressService,
  );

  @override
  Future<Persona> createPersona(
      {String name = '', bool isDefault = false}) async {
    final uuid = const Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.createKey(name);
    final persona = Persona.newPersona(
        uuid: uuid, defaultAccount: isDefault ? 1 : null, name: name);
    await _cloudDB.personaDao.insertPersona(persona);
    await androidBackupKeys();
    await _auditService.auditPersonaAction('create', persona);
    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent(MixpanelEvent.createFullAccount,
        data: {'isDefault': isDefault}, hashedData: {'id': persona.uuid});
    _autonomyService.postLinkedAddresses();
    log.info('[AccountService] Created persona ${persona.uuid}}');
    return persona;
  }

  @override
  Future<Persona> importPersona(String words,
      {WalletType walletType = WalletType.Autonomy}) async {
    final personas = await _cloudDB.personaDao.getPersonas();
    for (final persona in personas) {
      final mnemonic = await persona.wallet().exportMnemonicWords();
      if (mnemonic == words) {
        return persona;
      }
    }

    final uuid = const Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.importKey(
        words, '', DateTime.now().microsecondsSinceEpoch);

    final persona = Persona.newPersona(uuid: uuid);
    await _cloudDB.personaDao.insertPersona(persona);
    await androidBackupKeys();
    await _auditService.auditPersonaAction('import', persona);
    final metricClient = injector.get<MetricClientService>();
    unawaited(
        metricClient.addEvent(MixpanelEvent.importFullAccount, hashedData: {
      'id': uuid,
    }));
    log.info('[AccountService] imported persona ${persona.uuid}');
    return persona;
  }

  @override
  Future<WalletStorage> getDefaultAccount() async =>
      _defaultAccountLock.synchronized(() async => await _getDefaultAccount());

  @override
  Future<WalletStorage?> getCurrentDefaultAccount() async {
    var personas = await _cloudDB.personaDao.getDefaultPersonas();

    if (personas.isEmpty) {
      await MigrationUtil(_configurationService, _cloudDB, this, injector(),
              _auditService, _backupService)
          .migrationFromKeychain();
      await androidRestoreKeys();

      await Future.delayed(const Duration(seconds: 1));
      personas = await _cloudDB.personaDao.getDefaultPersonas();
    }

    if (personas.isEmpty) {
      personas = await _cloudDB.personaDao.getPersonas();
    }

    if (personas.isEmpty) return null;
    final defaultWallet = personas.first.wallet();

    return await defaultWallet.isWalletCreated() ? defaultWallet : null;
  }

  @override
  Future<WalletIndex> getAccountByAddress({
    required String chain,
    required String address,
  }) async {
    switch (chain.caip2Namespace) {
      case Wc2Chain.ethereum:
      case Wc2Chain.tezos:
        final walletAddress = await _cloudDB.addressDao.findByAddress(address);
        if (walletAddress != null) {
          return WalletIndex(
              WalletStorage(walletAddress.uuid), walletAddress.index);
        }
        break;
      case Wc2Chain.autonomy:
        var personas = await _cloudDB.personaDao.getPersonas();
        for (Persona p in personas) {
          final wallet = p.wallet();
          if (await wallet.getAccountDID() == address) {
            return WalletIndex(wallet, -1);
          }
        }
    }
    throw AccountException(
      message: 'Wallet not found. Chain $chain, address: $address',
    );
  }

  Future<WalletStorage> _getDefaultAccount() async {
    final Persona defaultPersona = await getOrCreateDefaultPersona();

    return LibAukDart.getWallet(defaultPersona.uuid);
  }

  @override
  Future<Persona> getOrCreateDefaultPersona() async {
    var personas = await _cloudDB.personaDao.getDefaultPersonas();

    if (personas.isEmpty) {
      await MigrationUtil(_configurationService, _cloudDB, this, injector(),
              _auditService, _backupService)
          .migrationFromKeychain();
      await androidRestoreKeys();

      await Future.delayed(const Duration(seconds: 1));
      personas = await _cloudDB.personaDao.getDefaultPersonas();
    }

    final Persona defaultPersona;
    if (personas.isEmpty) {
      personas = await _cloudDB.personaDao.getPersonas();
      if (personas.isNotEmpty) {
        defaultPersona = personas.first;
        defaultPersona.defaultAccount = 1;
        await _cloudDB.personaDao.updatePersona(defaultPersona);
      } else {
        log.info('[AccountService] create default account');
        defaultPersona = await createPersona(isDefault: true);
      }
    } else {
      defaultPersona = personas.first;
    }
    return defaultPersona;
  }

  @override
  Future deletePersona(Persona persona) async {
    log.info('[AccountService] deletePersona start - ${persona.uuid}');
    await _cloudDB.personaDao.deletePersona(persona);
    await _auditService.auditPersonaAction('delete', persona);

    await androidBackupKeys();
    await LibAukDart.getWallet(persona.uuid).removeKeys();

    final connections = await _cloudDB.connectionDao.getConnections();
    Set<P2PPeer> bcPeers = {};

    log.info('[AccountService] deletePersona - '
        'deleteConnections ${connections.length}');
    for (var connection in connections) {
      switch (connection.connectionType) {
        case 'beaconP2PPeer':
          if (persona.uuid == connection.beaconConnectConnection?.personaUuid) {
            await _cloudDB.connectionDao.deleteConnection(connection);
            injector<MetricClientService>().onRemoveConnection(connection);
            final bcPeer = connection.beaconConnectConnection?.peer;
            if (bcPeer != null) bcPeers.add(bcPeer);
          }
          break;

        // Note: Should app delete feralFileWeb3 too ??
      }
    }

    try {
      for (var peer in bcPeers) {
        await _tezosBeaconService.removePeer(peer);
      }
    } catch (exception) {
      Sentry.captureException(exception);
    }

    log.info('[AccountService] deletePersona finished - ${persona.uuid}');
  }

  @override
  Future deleteLinkedAccount(Connection connection) async {
    await _cloudDB.connectionDao.deleteConnection(connection);
    final addressIndexes = connection.addressIndexes;
    Future.wait(addressIndexes.map((element) async {
      await setHideLinkedAccountInGallery(element.address, false);
    }));
    await _addressService
        .deleteAddresses(addressIndexes.map((e) => e.address).toList());
    final metricClient = injector.get<MetricClientService>();
    unawaited(metricClient.addEvent(MixpanelEvent.deleteLinkedAccount,
        hashedData: {'address': connection.accountNumber}));
  }

  @override
  Future<Connection> linkManuallyAddress(String address, CryptoType cryptoType,
      {String? name}) async {
    String checkSumAddress = address;
    if (cryptoType == CryptoType.ETH || cryptoType == CryptoType.USDC) {
      checkSumAddress = address.getETHEip55Address();
    }
    final personaAddress = await _cloudDB.addressDao.getAllAddresses();
    if (personaAddress.any((element) => element.address == checkSumAddress)) {
      throw LinkAddressException(message: 'already_imported_address'.tr());
    }
    final doubleConnections = await _cloudDB.connectionDao
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

    await _cloudDB.connectionDao.insertConnection(connection);
    await _addressService.addAddresses([checkSumAddress]);
    _autonomyService.postLinkedAddresses();
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

    await _cloudDB.connectionDao.insertConnection(connection);
  }

  @override
  bool isLinkedAccountHiddenInGallery(String address) =>
      _configurationService.isLinkedAccountHiddenInGallery(address);

  @override
  Future setHideLinkedAccountInGallery(String address, bool isEnabled) async {
    await _configurationService
        .setHideLinkedAccountInGallery([address], isEnabled);
    await _addressService.setIsHiddenAddresses([address], isEnabled);
    unawaited(injector<SettingsDataService>().backup());
    final metricClient = injector.get<MetricClientService>();
    unawaited(metricClient.addEvent(MixpanelEvent.hideLinkedAccount,
        hashedData: {'address': address}));
  }

  @override
  Future setHideAddressInGallery(List<String> addresses, bool isEnabled) async {
    await Future.wait(addresses
        .map((e) => _cloudDB.addressDao.setAddressIsHidden(e, isEnabled)));
    await _addressService.setIsHiddenAddresses(addresses, isEnabled);
    unawaited(injector<SettingsDataService>().backup());
    final metricClient = injector.get<MetricClientService>();
    unawaited(metricClient.addEvent(MixpanelEvent.hideAddresses,
        hashedData: {'addresses': addresses.join('||')}));
  }

  @override
  Future androidBackupKeys() async {
    if (Platform.isAndroid) {
      final accounts = await _cloudDB.personaDao.getPersonas();
      final uuids = accounts.map((e) => e.uuid).toList();

      await _backupChannel.backupKeys(uuids);
    }
  }

  @override
  Future androidRestoreKeys() async {
    if (Platform.isAndroid) {
      final accounts = await _backupChannel.restoreKeys();

      final personas = await _cloudDB.personaDao.getPersonas();
      if (personas.length == accounts.length &&
          personas.every((element) =>
              accounts.map((e) => e.uuid).contains(element.uuid))) {
        //Database is up-to-date, skip migrating
        return;
      }

      //Import persona to database if needed
      for (var account in accounts) {
        final existingAccount =
            await _cloudDB.personaDao.findById(account.uuid);
        if (existingAccount == null) {
          final backupVersion = await _backupService
              .fetchBackupVersion(LibAukDart.getWallet(account.uuid));
          final defaultAccount = backupVersion.isNotEmpty ? 1 : null;

          final persona = Persona.newPersona(
            uuid: account.uuid,
            name: account.name,
            createdAt: DateTime.now(),
            defaultAccount: defaultAccount,
          );
          await _cloudDB.personaDao.insertPersona(persona);
          await _auditService.auditPersonaAction(
              '[androidRestoreKeys] insert', persona);
        }
      }

      //Cleanup broken personas
      final currentPersonas = await _cloudDB.personaDao.getPersonas();
      var shouldBackup = false;
      for (var persona in currentPersonas) {
        if (!(await persona.wallet().isWalletCreated())) {
          await _cloudDB.personaDao.deletePersona(persona);
          shouldBackup = true;
        }
      }

      if (shouldBackup || (personas.isNotEmpty && accounts.isEmpty)) {
        await androidBackupKeys();
      }
    }
  }

  @override
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

  @override
  Future<bool?> isAndroidEndToEndEncryptionAvailable() =>
      _backupChannel.isEndToEndEncryptionAvailable();

  @override
  Future<List<String>> getAllAddresses({bool logHiddenAddress = false}) async {
    if (_configurationService.isDemoArtworksMode()) {
      return [];
    }

    List<String> addresses = [];
    final addressPersona = await _cloudDB.addressDao.getAllAddresses();
    addresses.addAll(addressPersona.map((e) => e.address));

    final linkedAccounts =
        await _cloudDB.connectionDao.getUpdatedLinkedAccounts();

    addresses.addAll(linkedAccounts.expand((e) => e.accountNumbers));
    if (logHiddenAddress) {
      log.info(
          "[Account Service] all addresses (persona ${addressPersona.length}): ${addresses.join(", ")}");
      final hiddenAddresses = addressPersona
          .where((element) => element.isHidden)
          .map((e) => e.address.maskOnly(5))
          .toList();
      hiddenAddresses
          .addAll(_configurationService.getLinkedAccountsHiddenInGallery());
      log.info(
          "[Account Service] hidden addresses: ${hiddenAddresses.join(", ")}");
    }

    return addresses;
  }

  @override
  Future<List<String>> getAddress(String blockchain,
      {bool withViewOnly = false}) async {
    final addresses = <String>[];
    // Full accounts
    final personas = await _cloudDB.personaDao.getPersonas();
    for (var persona in personas) {
      final personaWallet = persona.wallet();
      if (!await personaWallet.isWalletCreated()) continue;
      switch (blockchain.toLowerCase()) {
        case 'tezos':
          addresses.addAll(await persona.getTezosAddresses());
          break;
        case 'ethereum':
          final address = await personaWallet.getETHEip55Address();
          if (address.isNotEmpty) {
            addresses.addAll(await persona.getEthAddresses());
          }
          break;
      }
    }

    if (withViewOnly) {
      final connections =
          await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
      for (var connection in connections) {
        if (connection.accountNumber.isEmpty) continue;
        final crytoType =
            CryptoType.fromAddress(connection.accountNumber).source;
        if (crytoType.toLowerCase() == blockchain.toLowerCase()) {
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
        await _cloudDB.addressDao.findAddressesWithHiddenStatus(false);
    addresses.addAll(walletAddress.map((e) => e.address).toList());

    final linkedAccounts =
        await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
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
      Persona newPersona, List<AddressInfo> addresses) async {
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
            uuid: newPersona.uuid,
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
    await _cloudDB.addressDao.insertAddresses(walletAddresses);
    await _addressService
        .addAddresses(addresses.map((e) => e.address).toList());
    return result;
  }

  @override
  Future<List<AddressIndex>> getHiddenAddressIndexes() async {
    List<AddressIndex> hiddenAddresses = [];
    final hiddenWalletAddresses =
        await _cloudDB.addressDao.findAddressesWithHiddenStatus(true);
    hiddenAddresses
        .addAll(hiddenWalletAddresses.map((e) => e.addressIndex).toList());

    final linkedAccounts =
        await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
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
  Future<void> deleteAddressPersona(
      Persona persona, WalletAddress walletAddress) async {
    _cloudDB.addressDao.deleteAddress(walletAddress);
    final metricClientService = injector<MetricClientService>();
    await _addressService.deleteAddresses([walletAddress.address]);
    switch (CryptoType.fromSource(walletAddress.cryptoType)) {
      case CryptoType.ETH:
        final connections = await _cloudDB.connectionDao
            .getConnectionsByType(ConnectionType.dappConnect2.rawValue);
        for (var connection in connections) {
          if (connection.accountNumber.contains(walletAddress.address)) {
            _cloudDB.connectionDao.deleteConnection(connection);
            metricClientService.onRemoveConnection(connection);
          }
        }
        return;
      case CryptoType.XTZ:
        final connections = await _cloudDB.connectionDao
            .getConnectionsByType(ConnectionType.beaconP2PPeer.rawValue);

        for (var connection in connections) {
          if (connection.beaconConnectConnection?.personaUuid == persona.uuid &&
              connection.beaconConnectConnection?.index ==
                  walletAddress.index) {
            _cloudDB.connectionDao.deleteConnection(connection);
            metricClientService.onRemoveConnection(connection);
          }
        }
        return;
      default:
        return;
    }
  }

  @override
  Future<void> updateAddressPersona(WalletAddress walletAddress) async {
    await _cloudDB.addressDao.updateAddress(walletAddress);
  }

  @override
  Future<void> restoreIfNeeded({bool isCreateNew = true}) async {
    if (_configurationService.isDoneOnboarding()) return;

    final iapService = injector<IAPService>();
    final auditService = injector<AuditService>();
    final migrationUtil = MigrationUtil(_configurationService, _cloudDB, this,
        iapService, auditService, _backupService);
    await androidBackupKeys();
    await migrationUtil.migrationFromKeychain();
    final personas = await _cloudDB.personaDao.getPersonas();
    final connections = await _cloudDB.connectionDao.getConnections();
    if (personas.isNotEmpty || connections.isNotEmpty) {
      _configurationService.setOldUser();
      final defaultAccount = await getDefaultAccount();
      final backupVersion =
          await _backupService.fetchBackupVersion(defaultAccount);
      if (backupVersion.isNotEmpty) {
        _backupService.restoreCloudDatabase(defaultAccount, backupVersion);
        for (var persona in personas) {
          if (persona.name != '') {
            persona.wallet().updateName(persona.name);
          }
        }
        await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
        _configurationService.setDoneOnboarding(true);
        injector<MetricClientService>().mixPanelClient.initIfDefaultAccount();
        injector<NavigationService>()
            .navigateTo(AppRouter.homePageNoTransition);
      }
    } else if (isCreateNew) {
      _configurationService.setDoneOnboarding(true);
      final persona = await createPersona();
      await persona.insertNextAddress(WalletType.Tezos);
      await persona.insertNextAddress(WalletType.Ethereum);
      injector<MetricClientService>().mixPanelClient.initIfDefaultAccount();
      injector<NavigationService>().navigateTo(AppRouter.homePageNoTransition);
    }
  }

  @override
  Future<WalletAddress?> getAddressPersona(String address) async =>
      await _cloudDB.addressDao.findByAddress(address);

  @override
  Future<List<Connection>> removeDoubleViewOnly(List<String> addresses) async {
    final List<Connection> result = [];
    final linkedAccounts = await _cloudDB.connectionDao.getLinkedAccounts();
    final viewOnlyAddresses = linkedAccounts
        .where((con) => addresses.contains(con.accountNumber))
        .toList();
    if (viewOnlyAddresses.isNotEmpty) {
      result.addAll(viewOnlyAddresses);
      await Future.forEach<Connection>(viewOnlyAddresses,
          (element) => _cloudDB.connectionDao.deleteConnection(element));
    }
    return result;
  }
}

class AccountImportedException implements Exception {
  final Persona persona;

  AccountImportedException({required this.persona});
}

class AccountException implements Exception {
  final String? message;

  AccountException({this.message});
}

class LinkAddressException implements Exception {
  final String message;

  LinkAddressException({required this.message});
}
