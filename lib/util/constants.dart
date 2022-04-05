import 'package:package_info_plus/package_info_plus.dart';

const INDEXER_TOKENS_MAXIMUM = 50;
const CLOUDFLAREIMAGEURLPREFIX =
    'https://imagedelivery.net/iCRs13uicXIPOWrnuHbaKA/';
const AUTONOMY_TV_PEER_NAME = 'Autonomy TV';
const RESET_LOCAL_CACHE_VERSION = '0.26.1';

Future<bool> isAppCenterBuild() async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.packageName.contains("inhouse");
}

enum WalletApp {
  MetaMask,
  Kukai,
  Temple,
}

extension RawValue on WalletApp {
  String get rawValue => this.toString().split('.').last;
}
