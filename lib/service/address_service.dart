import 'package:autonomy_flutter/model/address.dart';
import 'package:autonomy_flutter/service/domain_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:web3dart/credentials.dart';

abstract class DomainAddressService {
  String? verifyEthereumAddress(String address);

  String? verifyTezosAddress(String address);

  Address? verifyAddress(String value);

  Future<Address?> verifyEthereumAddressOrDomain(String value);

  Future<Address?> verifyTezosAddressOrDomain(String value);

  Future<Address?> verifyAddressOrDomain(String value);

  Future<Address?> verifyAddressOrDomainWithType(String value, CryptoType type);
}

class DomainAddressServiceImpl implements DomainAddressService {
  final DomainService _domainService;

  DomainAddressServiceImpl(this._domainService);

  @override
  Address? verifyAddress(String value) {
    final ethAddress = verifyEthereumAddress(value);
    if (ethAddress != null) {
      return Address(address: ethAddress, type: CryptoType.ETH);
    }
    final tezosAddress = verifyTezosAddress(value);
    if (tezosAddress != null) {
      return Address(address: tezosAddress, type: CryptoType.XTZ);
    }
    return null;
  }

  @override
  Future<Address?> verifyEthereumAddressOrDomain(String value) async {
    final ethAddress = verifyEthereumAddress(value);
    if (ethAddress != null) {
      return Future.value(Address(address: ethAddress, type: CryptoType.ETH));
    }
    final address = await _domainService.getEthAddress(value);
    final checksumAddress =
        address == null ? null : verifyEthereumAddress(address);
    if (checksumAddress != null) {
      return Address(
          address: checksumAddress, domain: value, type: CryptoType.ETH);
    }
    return null;
  }

  @override
  Future<Address?> verifyAddressOrDomain(String value) async {
    final address = verifyAddress(value);
    if (address != null) {
      return address;
    }
    final ethAddress = await verifyEthereumAddressOrDomain(value);
    if (ethAddress != null) {
      return ethAddress;
    }
    final tezosAddress = await verifyTezosAddressOrDomain(value);
    if (tezosAddress != null) {
      return tezosAddress;
    }
    return null;
  }

  @override
  String? verifyEthereumAddress(String address) {
    try {
      final checksumAddress = EthereumAddress.fromHex(address).hexEip55;
      return checksumAddress;
    } catch (_) {
      return null;
    }
  }

  @override
  String? verifyTezosAddress(String address) =>
      address.isValidTezosAddress ? address : null;

  @override
  Future<Address?> verifyTezosAddressOrDomain(String value) async {
    final tezosAddress = verifyTezosAddress(value);
    if (tezosAddress != null) {
      return Future.value(Address(address: tezosAddress, type: CryptoType.XTZ));
    }
    final address = await _domainService.getTezosAddress(value);
    if (address != null) {
      return Address(address: address, domain: value, type: CryptoType.XTZ);
    }
    return null;
  }

  @override
  Future<Address?> verifyAddressOrDomainWithType(
      String value, CryptoType type) async {
    switch (type) {
      case CryptoType.ETH:
      case CryptoType.USDC:
        return await verifyEthereumAddressOrDomain(value);
      case CryptoType.XTZ:
        return await verifyTezosAddressOrDomain(value);
      default:
        return null;
    }
  }
}
