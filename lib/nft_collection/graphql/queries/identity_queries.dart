const String identity = r'''
  query identity($account: String!) {
  identity(account: $account) {
    blockchain
    accountNumber
    name
  }
}
''';
