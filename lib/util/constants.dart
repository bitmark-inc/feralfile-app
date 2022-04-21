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
  static const Source = 'Source';
  static const Medium = 'Medium';
  static const ArtistName = 'Artist name';
  static const Chain = "Chain";

  static List<String> get getList => [Source, Medium, ArtistName, Chain];
}

extension RawValue on WalletApp {
  String get rawValue => this.toString().split('.').last;
}

class ReportIssueType {
  static const Feature = 'feature';
  static const Bug = 'bug';
  static const Feedback = 'feedback';
  static const Other = 'other';

  static List<String> get getList => [Feature, Bug, Feedback, Other];

  static String toTitle(String item) {
    switch (item) {
      case Feature:
        return 'Request a feature';
      case Bug:
        return 'Report a bug';
      case Feedback:
        return 'Share feedback';
      default:
        return 'Something else?';
    }
  }

  static String introMessage(String item) {
    switch (item) {
      case Feature:
        return 'Thanks for taking the time to help us improve Autonomy. We’re always looking for great ideas. What feature would you like to request?';
      case Bug:
        return 'We’re sorry to hear you’ve experienced a problem using Autonomy. Thanks for taking the time to help us improve. Please describe the bug for us.';
      case Feedback:
        return 'Thanks for taking the time to share your feedback with us. What’s on your mind?';
      default:
        return 'Thanks for reaching out to the Autonomy team! What’s on your mind?';
    }
  }
}
