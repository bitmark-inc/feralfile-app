import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:nft_collection/services/address_service.dart';

class MigrateAddressUtil {
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDB;
  final AddressService _addressService;

  MigrateAddressUtil(
      this._configurationService, this._cloudDB, this._addressService);

  Future<void> migrateViewOnlyAddresses() async {
    if (_configurationService.getDidMigrateAddress()) return;

    final manualConnections = await _cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.manuallyAddress.rawValue);
    final needChecksumConnections = manualConnections
        .where((element) => element.key != _tryChecksum(element.key))
        .toList();

    if (needChecksumConnections.isNotEmpty) {
      final checksumConnections = needChecksumConnections.map((e) {
        final checksumAddress = _tryChecksum(e.key);
        return e.copyWith(key: checksumAddress, accountNumber: checksumAddress);
      }).toList();
      final personaAddresses =
          (await _cloudDB.addressDao.getAddressesByType(CryptoType.ETH.source))
              .map((e) => e.address);
      final connectionAddresses = manualConnections.map((e) => e.key);
      checksumConnections.removeWhere((element) =>
          personaAddresses.contains(element.key) ||
          connectionAddresses.contains(element.key));
      await _cloudDB.connectionDao.deleteConnections(needChecksumConnections);
      await _addressService
          .deleteAddresses(needChecksumConnections.map((e) => e.key).toList());
      await _cloudDB.connectionDao.insertConnections(checksumConnections);
      await _addressService
          .addAddresses(checksumConnections.map((e) => e.key).toList());
    }

    _configurationService.setDidMigrateAddress(true);
  }

  String _tryChecksum(String address) {
    try {
      return address.getETHEip55Address();
    } catch (_) {
      return address;
    }
  }
}
