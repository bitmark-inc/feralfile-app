import 'package:autonomy_flutter/model/prompt.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/design_stamp.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PromptPage extends StatefulWidget {
  final DesignStampPayload payload;

  const PromptPage({required this.payload, super.key});

  @override
  State<PromptPage> createState() => _PromptPageState();
}

class _PromptPageState extends State<PromptPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isPromptValid = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const backgroundColor = AppColor.chatPrimaryColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: getBackAppBar(
        context,
        title: 'prompt'.tr(),
        titleStyle: theme.textTheme.moMASans700Black18,
        statusBarColor: backgroundColor,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 32),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    Text(
                      'add_prompt_desc'.tr(),
                      style: theme.textTheme.moMASans400Grey12,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColor.white,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: TextField(
                        controller: _controller,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          final isValid = _isValidPrompt(value);
                          if (isValid != _isPromptValid) {
                            setState(() {
                              _isPromptValid = isValid;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'add_prompt_hint'.tr(),
                          hintStyle: theme.textTheme.moMASans700AuGrey18,
                        ),
                        maxLines: 5,
                        minLines: 5,
                        style: theme.textTheme.moMASans700Black18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                    flex: 4,
                    child: PostcardButton(
                      text: 'save_prompt'.tr(),
                      enabled: _isPromptValid,
                      onTap: () async {
                        final assetWithPrompt = widget.payload.asset
                            .setAssetPrompt(
                                Prompt.getUserPrompt(_controller.text.trim()));
                        await Navigator.of(context).pushNamed(
                            AppRouter.designStamp,
                            arguments:
                                DesignStampPayload(assetWithPrompt, true));
                      },
                    )),
                Flexible(
                    child: PostcardButton(
                  text: 'skip'.tr(),
                  color: backgroundColor,
                  textColor: AppColor.auQuickSilver,
                  textStyle: theme.textTheme.moMASans400Grey12,
                  onTap: () async {
                    await Navigator.of(context).pushNamed(AppRouter.designStamp,
                        arguments: widget.payload);
                  },
                )),
              ],
            )
          ],
        ),
      ),
    );
  }

  bool _isValidPrompt(String prompt) =>
      prompt.trim().isNotEmpty && prompt.trim().length <= 1000;
}
