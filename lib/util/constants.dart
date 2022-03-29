import 'package:package_info_plus/package_info_plus.dart';

const INDEXER_TOKENS_MAXIMUM = 50;
const CLOUDFLAREIMAGEURLPREFIX =
    'https://imagedelivery.net/iCRs13uicXIPOWrnuHbaKA/';

Future<bool> isAppCenterBuild() async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.packageName == "com.bitmark.autonomy.inhouse";
}

enum WalletApp {
  MetaMask,
  Kukai,
  Temple,
}

extension RawValue on WalletApp {
  String get rawValue => this.toString().split('.').last;
}
