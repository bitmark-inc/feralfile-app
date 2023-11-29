import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PromptPage extends StatefulWidget {
  const PromptPage({super.key});

  @override
  State<PromptPage> createState() => _PromptPageState();
}

class _PromptPageState extends State<PromptPage> {
  final TextEditingController _controller = TextEditingController();

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
        padding: EdgeInsets.only(bottom: ResponsiveLayout.padding),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'add_prompt_desc'.tr(),
                        style: theme.textTheme.moMASans400Grey12,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColor.white,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: _controller,
                          textAlign: TextAlign.center,
                          maxLines: null,
                          minLines: 5,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
