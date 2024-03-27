import 'package:autonomy_flutter/util/string_ext.dart';

class AddEthereumChainParameter {
  final String chainId;
  final List<String>? blockExplorerUrls;
  final String? chainName;
  final List<String>? iconUrls;
  final NativeCurrency? nativeCurrency;
  final List<String> rpcUrls;

  AddEthereumChainParameter({
    required this.chainId,
    required this.rpcUrls,
    this.blockExplorerUrls,
    this.chainName,
    this.iconUrls,
    this.nativeCurrency,
  });

  factory AddEthereumChainParameter.fromJson(Map<String, dynamic> json) =>
      AddEthereumChainParameter(
        chainId: json['chainId'],
        blockExplorerUrls: json['blockExplorerUrls'] != null
            ? List<String>.from(json['blockExplorerUrls'])
            : null,
        chainName: json['chainName'],
        iconUrls: json['iconUrls'] != null
            ? List<String>.from(json['iconUrls'])
            : null,
        nativeCurrency: json['nativeCurrency'] != null
            ? NativeCurrency.fromJson(json['nativeCurrency'])
            : null,
        rpcUrls: List<String>.from(json['rpcUrls']), // Not null
      );

  bool get isValid {
    final chainIdRegExp = RegExp(r'^0x[0-9a-fA-F]+$');

    if (chainIdRegExp.hasMatch(chainId) &&
        _isValidUrlList(rpcUrls, allowNullAndEmpty: false) &&
        _isValidUrlList(iconUrls) &&
        _isValidUrlList(blockExplorerUrls) &&
        (nativeCurrency == null ||
            (nativeCurrency!.name.isNotEmpty &&
                nativeCurrency!.symbol.isNotEmpty &&
                nativeCurrency!.decimals > 0))) {
      return true;
    }

    return false;
  }

  bool _isValidUrlList(List<dynamic>? urls, {bool allowNullAndEmpty = true}) {
    if (urls == null || urls.isEmpty) {
      return allowNullAndEmpty;
    }
    for (String url in urls) {
      if (!url.isValidUrl() || url.isInvalidRPCScheme()) {
        return false;
      }
    }
    return true;
  }

  String get chainNet {
    switch (int.parse(chainId.substring('0x'.length), radix: 16)) {
      case 1:
        return 'Mainnet';
      case 5:
        return 'Goerli';
      case 11155111:
        return 'Sepolia';
      default:
        return 'unknown';
    }
  }
}

class NativeCurrency {
  final String name;
  final String symbol;
  final int decimals;

  NativeCurrency({
    required this.name,
    required this.symbol,
    required this.decimals,
  });

  factory NativeCurrency.fromJson(Map<String, dynamic> json) => NativeCurrency(
        name: json['name'],
        symbol: json['symbol'],
        decimals: json['decimals'],
      );
}
