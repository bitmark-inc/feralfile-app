import 'dart:convert';

import 'package:autonomy_flutter/model/prompt.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/prompt_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';

class ChoosePromptPage extends StatelessWidget {
  final ChoosePromptPayload payload;

  const ChoosePromptPage({required this.payload, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const backgroundColor = AppColor.chatPrimaryColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: getCloseAppBar(
        context,
        title: 'choose_prompt'.tr(),
        titleStyle: theme.textTheme.moMASans700Black16.copyWith(fontSize: 18),
        onClose: () {
          Navigator.of(context).pop();
        },
        withBottomDivider: false,
        statusBarColor: backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 32),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 70),
              Text(
                'select_prompt'.tr(),
                style: theme.textTheme.moMASans400Grey12,
              ),
              ...payload.prompts.map((prompt) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: PromptView(
                      prompt: prompt,
                      expandable: true,
                      onTap: () async {
                        final postcardMetadata = payload
                            .assetToken.postcardMetadata
                          ..prompt = prompt;

                        final asset = payload.assetToken
                          ..asset?.artworkMetadata =
                              jsonEncode(postcardMetadata.toJson());
                        if (prompt.cid != null) {
                          asset.setPreviewUrlWithCID(prompt.cid!);
                        }

                        await Navigator.of(context).pushNamed(
                            AppRouter.designStamp,
                            arguments: DesignStampPayload(asset, true));
                      },
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class ChoosePromptPayload {
  final AssetToken assetToken;
  final List<Prompt> prompts;

  ChoosePromptPayload({required this.assetToken, required this.prompts});
}
