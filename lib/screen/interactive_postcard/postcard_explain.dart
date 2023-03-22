import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';

import 'design_stamp.dart';

class PostcardExplain extends StatefulWidget {
  static const String tag = 'postcard_explain_screen';
  final PostcardExplainPayload payload;

  const PostcardExplain({Key? key, required this.payload}) : super(key: key);

  @override
  State<PostcardExplain> createState() => _PostcardExplainState();
}

class _PostcardExplainState extends State<PostcardExplain> {
  bool isGetLocation = true;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColor.primaryBlack,
      appBar: getBackAppBar(
        context,
        title: "how_it_works".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
        isWhite: false,
      ),
      body: Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  addTitleSpace(),
                  Text(
                    "postcard_explain".tr(),
                    style: theme.textTheme.ppMori400White14,
                  ),
                ],
              )),
            ),
            PrimaryButton(
              text: "continue".tr(),
              onTap: () async {
                if(isGetLocation) {
                  final location = await getGeoLocationWithPermission();
                  if (!mounted || location == null) return;
                  Navigator.of(context).pushNamed(AppRouter.designStamp,
                      arguments: DesignStampPayload(widget.payload.asset, location));
                } else {
                  Navigator.of(context).pushNamed(AppRouter.designStamp,
                      arguments: DesignStampPayload(widget.payload.asset, null));
                }


              },
            ),
          ],
        ),
      ),
    );
  }
}

class PostcardExplainPayload {
  final AssetToken asset;
  PostcardExplainPayload(this.asset);
}
