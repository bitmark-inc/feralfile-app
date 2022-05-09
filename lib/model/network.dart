enum Network { TESTNET, MAINNET }

extension RawValue on Network {
  String get rawValue => this.toString().split('.').last;
}
