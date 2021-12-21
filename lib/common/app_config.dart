class AppConfig {
  static const String openSeaApiKey = "";
  static const AppConfigNetwork mainNetworkConfig = AppConfigNetwork("", "", "", "");
  static const AppConfigNetwork testNetworkConfig = AppConfigNetwork("", "", "", "");
}

class AppConfigNetwork {
  final String web3RpcUrl;
  final String bitmarkApiUrl;
  final String indexerApiUrl;
  final String feralFileApiUrl;

  const AppConfigNetwork(this.web3RpcUrl, this.bitmarkApiUrl, this.indexerApiUrl,
      this.feralFileApiUrl);
}
