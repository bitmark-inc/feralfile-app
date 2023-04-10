import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
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
                    _explain(),
                    PostcardButton(
                      text: "next_design_your_stamp".tr(),
                      onTap: () async {
                        if (isGetLocation) {
                          final location = await getGeoLocationWithPermission();
                          if (!mounted || location == null) return;
                          Navigator.of(context).pushNamed(AppRouter.designStamp,
                              arguments: DesignStampPayload(
                                  widget.payload.asset, location));
                        } else {
                          Navigator.of(context).pushNamed(AppRouter.designStamp,
                              arguments: DesignStampPayload(
                                  widget.payload.asset, null));
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            "game_runs_from_".tr(
                              namedArgs: {
                                "from": POSRCARD_GAME_START,
                                "to": POSRCARD_GAME_END,
                              },
                            ),
                            style: theme.textTheme.ppMori400Grey14),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _explain() {
    final explainTextList = [
      'postcard_explain_1',
      'postcard_explain_2',
      'postcard_explain_3',
      'postcard_explain_4',
      'postcard_explain_5',
      'postcard_explain_6',
      'postcard_explain_7',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColor.white,
      child: Column(
        children: explainTextList
            .mapIndexed((index, text) {
              return [
                _explainRow(
                  "${index + 1}",
                  text.tr(),
                ),
                if (index != explainTextList.length - 1) addOnlyDivider()
              ];
            })
            .flattened
            .toList(),
      ),
    );
  }

  Widget _explainRow(String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.ppMori400Black14,
          ),
          const SizedBox(width: 60),
          Expanded(
            child: Text(
              content,
              style: theme.textTheme.ppMori400Black14,
              overflow: TextOverflow.visible,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class PostcardExplainPayload {
  final AssetToken asset;
  PostcardExplainPayload(this.asset);
}
