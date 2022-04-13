import 'package:package_info_plus/package_info_plus.dart';

const INDEXER_TOKENS_MAXIMUM = 50;
const CLOUDFLAREIMAGEURLPREFIX =
    'https://imagedelivery.net/iCRs13uicXIPOWrnuHbaKA/';
const AUTONOMY_TV_PEER_NAME = 'Autonomy TV';
const DEFAULT_IPFS_PREFIX = 'https://ipfs.io';
const CLOUDFLARE_IPFS_PREFIX = 'https://cloudflare-ipfs.com';
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
