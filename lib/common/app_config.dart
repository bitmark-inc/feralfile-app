class AppConfig {
  static const String ffAuthorizationPrefix =
      "FERAL FILE AUTHORIZATION\n\nTimestamp: ";
  static const String openSeaApiKey = "";
  static const AppConfigNetwork testNetworkConfig = AppConfigNetwork(
      "https://rinkeby.infura.io/v3/20aba74f4e8642b88808ff4df18c10ff",
      "https://hangzhounet.smartpy.io",
      "https://api.test.bitmark.com",
      "https://indexer.test.autonomy.io",
      "https://autonomy-auth.test.bitmark.com",
      "https://feralfile1.dev.bitmark.com");
  static const AppConfigNetwork mainNetworkConfig = AppConfigNetwork(
      "https://mainnet.infura.io/v3/ab0e0fe9710b412ca73bb044713a3523",
      "https://mainnet.smartpy.io/",
      "https://api.bitmark.com",
      "https://indexer.autonomy.io",
      "https://autonomy-auth.test.bitmark.com",
      "https://feralfile.com");
}

class AppConfigNetwork {
  final String web3RpcUrl;
  final String tezosNodeClientUrl;
  final String bitmarkApiUrl;
  final String indexerApiUrl;
  final String autonomyAuthUrl;
  final String feralFileApiUrl;

  const AppConfigNetwork(
      this.web3RpcUrl,
      this.tezosNodeClientUrl,
      this.bitmarkApiUrl,
      this.indexerApiUrl,
      this.autonomyAuthUrl,
      this.feralFileApiUrl);
}
