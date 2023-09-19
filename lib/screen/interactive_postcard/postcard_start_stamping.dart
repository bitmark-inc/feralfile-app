import 'dart:async';

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/models.dart';

class StartStampingPostCardPagePayload {
  final AssetToken asset;

  StartStampingPostCardPagePayload({required this.asset});
}

class StartStampingPostCardPage extends StatefulWidget {
  final StartStampingPostCardPagePayload payload;

  const StartStampingPostCardPage({
    Key? key,
    required this.payload,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _StartStampingPostCardPageState();
  }
}

class _StartStampingPostCardPageState extends State<StartStampingPostCardPage> {
  late bool _isProcessing;

  @override
  void initState() {
    super.initState();
    _isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.payload.asset;
    return PostcardExplain(
      payload: PostcardExplainPayload(
          asset,
          PostcardButton(
            text: "continue".tr(),
            fontSize: 18,
            enabled: !(_isProcessing),
            isProcessing: _isProcessing,
            onTap: () async {
              setState(() {
                _isProcessing = true;
              });
              _onStarted(context, widget.payload.asset);
            },
            color: const Color.fromRGBO(79, 174, 79, 1),
          ),
          onSkip: () {}),
    );
  }

  Future<void> _onStarted(BuildContext context, AssetToken assetToken) async {
    final counter = assetToken.postcardMetadata.counter;
    GeoLocation? geoLocation;
    if (counter <= 1) {
      geoLocation = moMAGeoLocation;
    } else {
      geoLocation = await getGeoLocationWithPermission();
    }
    if (geoLocation == null) return;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.designStamp,
        arguments: DesignStampPayload(assetToken, geoLocation));
  }
}
