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

Future<String> getDemoAccount() async {
  return await isAppCenterBuild() ? "demo" : "demo2";
}

Future<String> getOneSignalAppID() async {
  return await isAppCenterBuild()
      ? "d7a33375-97d4-45b8-8e45-09e3ce0aa25b"
      : "60c6ff6b-b7af-44ad-b924-5e674e7d54c4";
}

Future<String> getAppVariant() async {
  return await isAppCenterBuild() ? "inhouse" : "production";
}

enum WalletApp {
  MetaMask,
  Kukai,
  Temple,
}

class GallerySortProperty {
  static const Platform = 'Platform';
  static const Medium = 'Medium';
  static const ArtistName = 'Artist name';
  static const Chain = "Chain";

  static List<String> get getList => [Platform, Medium, ArtistName, Chain];
}

extension RawValue on WalletApp {
  String get rawValue => this.toString().split('.').last;
}
