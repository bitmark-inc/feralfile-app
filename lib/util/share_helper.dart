import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:social_share/social_share.dart';
import 'package:url_launcher/url_launcher.dart';

void manualShare(String caption, String url) async {
  final encodeCaption = Uri.encodeQueryComponent(caption);
  final twitterUrl = "${SocialApp.twitterPrefix}?url=$url&text=$encodeCaption";
  final twitterUri = Uri.parse(twitterUrl);
  launchUrl(twitterUri, mode: LaunchMode.externalApplication);
}

void shareToTwitter({required AssetToken token, String? twitterCaption}) {
  final metricClientService = injector<MetricClientService>();
  final prefix = Environment.tokenWebviewPrefix;
  final url = '$prefix/token/${token.id}';
  final caption = twitterCaption ?? token.twitterCaption;
  SocialShare.checkInstalledAppsForShare().then(
    (data) {
      if (data?[SocialApp.twitter]) {
        SocialShare.shareTwitter(caption, url: url);
      } else {
        manualShare(caption, url);
      }
    },
  );
  metricClientService.addEvent(MixpanelEvent.share, data: {
    "id": token.id,
    "to": "Twitter",
    "caption": caption,
    "title": token.title,
    "artistID": token.artistID,
  });
}
