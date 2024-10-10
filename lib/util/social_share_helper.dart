import 'package:autonomy_flutter/util/constants.dart';
import 'package:social_share/social_share.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialShareHelper {
  static Future<void> _manualShare(
      String caption, String url, List<String> hashTags) async {
    final encodeCaption = Uri.encodeQueryComponent(caption);
    final hashTagsString = hashTags.join(',');
    final twitterUrl = '${SocialApp.twitterPrefix}?url=$url&text=$encodeCaption'
        '&hashtags=$hashTagsString';
    final twitterUri = Uri.parse(twitterUrl);
    await launchUrl(twitterUri, mode: LaunchMode.externalApplication);
  }

  static Future<void> shareTwitter(
      {required String url, String? caption, List<String>? hashTags}) async {
    await SocialShare.checkInstalledAppsForShare().then((data) {
      if (data?[SocialApp.twitter]) {
        SocialShare.shareTwitter(caption ?? '', url: url, hashtags: hashTags);
      } else {
        _manualShare(caption ?? '', url, hashTags ?? []);
      }
    });
  }
}
