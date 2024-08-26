import 'dart:async';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:social_share/social_share.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> manualShare(String caption, String url) async {
  final encodeCaption = Uri.encodeQueryComponent(caption);
  final twitterUrl = '${SocialApp.twitterPrefix}?url=$url&text=$encodeCaption';
  final twitterUri = Uri.parse(twitterUrl);
  unawaited(launchUrl(twitterUri, mode: LaunchMode.externalApplication));
}

void shareToTwitter({required AssetToken token, String? twitterCaption}) {
  final prefix = Environment.tokenWebviewPrefix;
  final url = '$prefix/token/${token.id}';
  final caption = twitterCaption ?? token.twitterCaption;
  unawaited(SocialShare.checkInstalledAppsForShare().then(
    (data) {
      if (data?[SocialApp.twitter]) {
        SocialShare.shareTwitter(caption, url: url);
      } else {
        manualShare(caption, url);
      }
    },
  ));
}
