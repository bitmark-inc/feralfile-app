class AliasHelper {
  static const List<String> _lowercaseAcAccountAlias = [
    'john gerrard',
  ];

  static const _a2pSuffix = '<A2P>';
  static const _custodySuffix = '_custody';
  static const _tezosSuffix = '_tez';

  static String transform(String value, {bool isArtistOrCurator = false}) {
    value = value.trim();

    if (value.isNotEmpty && isArtistOrCurator) {
      value = _removeArtistCuratorAliasSuffixes(value);

      if (_lowercaseAcAccountAlias.contains(value.toLowerCase())) {
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

  static String _removeArtistCuratorAliasSuffixes(String value) => value
      .replaceAll(RegExp('$_a2pSuffix\$'), '')
      .replaceAll(RegExp('$_custodySuffix\$'), '')
      .replaceAll(RegExp('$_tezosSuffix\$'), '');
}
