import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_explain.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';

class PostcardStartedPage extends StatelessWidget {
  final AssetToken assetToken;

  const PostcardStartedPage({Key? key, required this.assetToken})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = assetToken;
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        leadingWidth: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              asset.title ?? '',
              style: theme.textTheme.ppMori400White16,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Semantics(
            label: 'close_icon',
            child: IconButton(
              onPressed: () => Navigator.pop(context),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PostcardRatio(assetToken: assetToken),
              PostcardButton(
                text: "get_started".tr(),
                onTap: () {
                  _onStarted(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onStarted(BuildContext context) {
    Navigator.of(context).pushNamed(AppRouter.postcardExplain,
        arguments: PostcardExplainPayload(assetToken));
  }
}
