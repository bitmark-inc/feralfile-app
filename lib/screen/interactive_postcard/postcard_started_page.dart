import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nft_collection/models/asset_token.dart';

class PostcardStartedPage extends StatefulWidget {
  final AssetToken assetToken;

  const PostcardStartedPage({super.key, required this.assetToken});

  @override
  State<StatefulWidget> createState() {
    return _PostcardStartedPageState();
  }
}

class _PostcardStartedPageState extends State<PostcardStartedPage>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    injector<ConfigurationService>().setAutoShowPostcard(false);
  }

  final _isGetLocation = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = widget.assetToken;
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leadingWidth: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              asset.title ?? '',
              style: theme.textTheme.ppMori400White16,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Semantics(
            label: 'close_icon',
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              constraints: const BoxConstraints(
                maxWidth: 44,
                maxHeight: 44,
              ),
              icon: Icon(
                AuIcon.close,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: addOnlyDivider(color: AppColor.auGreyBackground),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 150,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PostcardRatio(assetToken: widget.assetToken),
                PostcardButton(
                  text: "next_design_your_stamp".tr(),
                  onTap: () async {
                    await _onStarted(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStarted(BuildContext context) async {
    if (_isGetLocation) {
      final counter = widget.assetToken.postcardMetadata.counter;
      GeoLocation? geoLocation;
      if (counter <= 1) {
        geoLocation = moMAGeoLocation;
      } else {
        geoLocation = await getGeoLocationWithPermission();
      }
      if (!mounted || geoLocation == null) return;
      Navigator.of(context).pushNamed(AppRouter.designStamp,
          arguments: DesignStampPayload(widget.assetToken, geoLocation));
    }
  }
}
