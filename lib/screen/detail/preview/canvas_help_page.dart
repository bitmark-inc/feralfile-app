import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class CanvasHelpPage extends StatelessWidget {
  const CanvasHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar:
            getCloseAppBar(context, title: 'autonomy_canvas'.tr(), onClose: () {
          Navigator.of(context).pop();
        }),
        body: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
            child: Column(
              children: [
                addTitleSpace(),
                ..._questionAnswer(context),
                Text(
                  'we_hope_this_helps'.tr(),
                  style: theme.textTheme.ppMori400Black16,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ));
  }

  List<Widget> _questionAnswer(BuildContext context) {
    final questions = [
      'canvas_help_q1'.tr(),
      'canvas_help_q2'.tr(),
      'canvas_help_q3'.tr(),
      'canvas_help_q4'.tr(),
    ];
    final answers = [
      'canvas_help_a1'.tr(),
      'canvas_help_a2'.tr(),
      'canvas_help_a3'.tr(),
      'canvas_help_a4'.tr(),
    ];
    final theme = Theme.of(context);
    return questions
        .mapIndexed((index, e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                      style: theme.textTheme.ppMori700Black16,
                      children: [
                        const TextSpan(text: 'Q: '),
                        TextSpan(
                          text: questions[index],
                        )
                      ]),
                ),
                const SizedBox(
                  height: 12,
                ),
                RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                        style: theme.textTheme.ppMori400Black16.copyWith(),
                        children: [
                          const TextSpan(text: 'A: '),
                          TextSpan(
                            text: answers[index],
                          ),
                        ])),
                const SizedBox(
                  height: 40,
                )
              ],
            ))
        .toList();
  }
}
