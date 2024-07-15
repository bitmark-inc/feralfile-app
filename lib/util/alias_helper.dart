class AliasHelper {
  static const List<String> _LOWERCASE_AC_ACCOUNT_ALIAS = [
    'john gerrard',
  ];

  static String transform(String value, {bool isArtistOrCurator = false}) {
    value = value.trim();

    if (value.isNotEmpty && isArtistOrCurator) {
      value = _removeArtistCuratorAliasSuffixes(value);

      if (_LOWERCASE_AC_ACCOUNT_ALIAS.contains(value.toLowerCase())) {
        value = value.toLowerCase();
      }
    }

    bool isSingleWord = value.split(' ').length == 1;
    int valueLength = value.length;

    // If long alias as a web3 address
    if (isSingleWord) {
      if (valueLength > 40) {
        value = _formatLongValue(value);
      } else if (value.startsWith('tz') && valueLength >= 36) {
        value = _formatTezosValue(value);
      }
    }

    return value;
  }

  static String _formatLongValue(String value) =>
      '[${value.substring(0, 4)}....${value.substring(value.length - 4)}]';

  static String _formatTezosValue(String value) =>
      '${value.substring(0, 7)}...${value.substring(value.length - 4)}';

  static String _removeArtistCuratorAliasSuffixes(String value) {
    const a2pSuffix = AppSetting.a2pSuffix;
    const custodySuffix = AppSetting.custodySuffix;
    const tezosSuffix = AppSetting.tezosSuffix;

    return value
        .replaceAll(RegExp('$a2pSuffix\$'), '')
        .replaceAll(RegExp('$custodySuffix\$'), '')
        .replaceAll(RegExp('$tezosSuffix\$'), '');
  }
}

class AppSetting {
  static const a2pSuffix = '<A2P>';
  static const custodySuffix = '_custody';
  static const tezosSuffix = '_tez';
}
