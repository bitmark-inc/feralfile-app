import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/select_addresses.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sentry/sentry.dart';

class ImportSeedsPage extends StatefulWidget {
  const ImportSeedsPage({super.key});

  @override
  State<ImportSeedsPage> createState() => _ImportSeedsPageState();
}

class _ImportSeedsPageState extends State<ImportSeedsPage> {
  bool _isError = false;
  static const _rowNumber = 12;
  static const _maxWords = 24;
  final List<TextEditingController> _mnemonicControllers =
      List.generate(_maxWords, (_) => TextEditingController(), growable: false);
  final List<FocusNode> _focusNodes =
      List.generate(_maxWords + 1, (_) => FocusNode(), growable: false);
  final TextEditingController _passphraseTextController =
      TextEditingController();
  bool _isSubmissionEnabled = false;
  bool _obscureText = true;
  bool _passphraseObscureText = true;

  @override
  void dispose() {
    for (var element in _mnemonicControllers) {
      element.dispose();
    }
    for (var element in _focusNodes) {
      element.dispose();
    }
    _passphraseTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'import_address'.tr(),
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
        body: Padding(
          padding: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 34),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'reveal_secret_phrase'.tr(),
                            style: Theme.of(context).textTheme.ppMori400Black14,
                          ),
                          AuToggle(
                            value: !_obscureText,
                            onToggle: (value) {
                              setState(() {
                                _obscureText = !value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'enter_your_mnemonic'.tr(),
                        style: Theme.of(context).textTheme.ppMori400Black14,
                      ),
                      const SizedBox(height: 5),
                      Table(
                        children: List.generate(
                          _rowNumber,
                          (index) => _tableRow(context, index, _rowNumber),
                        ),
                        border: TableBorder.all(
                            color:
                                _isError ? AppColor.red : AppColor.auLightGrey,
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: 'enter_passphrase'.tr().split('only')[0],
                              style:
                                  Theme.of(context).textTheme.ppMori400Black14,
                            ),
                            TextSpan(
                              text: 'only',
                              style:
                                  Theme.of(context).textTheme.ppMori700Black14,
                            ),
                            TextSpan(
                              text: 'enter_passphrase'.tr().split('only')[1],
                              style:
                                  Theme.of(context).textTheme.ppMori400Black14,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      AuTextField(
                        labelSemantics: 'enter_passphrase',
                        title: '',
                        obscureText: _passphraseObscureText,
                        placeholder: 'enter_passphrase_placeholder'.tr(),
                        hintMaxLines: 1,
                        controller: _passphraseTextController,
                        focusNode: _focusNodes[_maxWords],
                        suffix: IconButton(
                          icon: SvgPicture.asset(
                            _passphraseObscureText
                                ? 'assets/images/unhide.svg'
                                : 'assets/images/hide.svg',
                            colorFilter: const ColorFilter.mode(
                                AppColor.primaryBlack, BlendMode.srcIn),
                          ),
                          onPressed: () {
                            setState(() {
                              _passphraseObscureText = !_passphraseObscureText;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'enter_passphrase_warning'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .ppMori400FFQuickSilver12,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryAsyncButton(
                text: 'continue'.tr(),
                enabled: _isSubmissionEnabled && !_isError,
                onTap: () async => _import(),
              ),
            ],
          ),
        ),
      );

  Future<void> _import() async {
    try {
      setState(() {
        _isError = false;
      });
      final accountService = injector<AccountService>();

      final persona = await accountService.importPersona(
        _getMnemonic(),
        _passphraseTextController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      unawaited(Navigator.of(context).pushNamed(AppRouter.selectAddressesPage,
          arguments: SelectAddressesPayload(persona: persona)));

      if (!mounted) {
        return;
      }
    } catch (exception) {
      log.info('Import wallet fails $exception');
      unawaited(Sentry.captureException(exception));
      UIHelper.hideInfoDialog(context);
      setState(() {
        _isError = true;
      });
    }
  }

  TableRow _tableRow(BuildContext context, int index, int itemsEachCol) =>
      TableRow(children: [
        _rowItem(context, index),
        _rowItem(context, index + itemsEachCol),
      ]);

  Widget _rowItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat('00');
    final controller = _mnemonicControllers[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.centerRight,
            child: Text(formatter.format(index + 1),
                style: theme.textTheme.ppMori400Grey14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              enableSuggestions: false,
              focusNode: _focusNodes[index],
              autocorrect: false,
              obscureText: _obscureText,
              controller: controller,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(0, 3, 0, 0),
                isDense: true,
                border: InputBorder.none,
                hintStyle: ResponsiveLayout.isMobile
                    ? theme.textTheme.ppMori400Black14
                        .copyWith(color: AppColor.auQuickSilver)
                    : theme.textTheme.ppMori400Black16
                        .copyWith(color: AppColor.auQuickSilver, fontSize: 20),
              ),
              onSubmitted: (value) {
                if (index < _maxWords) {
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                }
              },
              style: theme.textTheme.ppMori400Black14
                  .copyWith(color: _isError ? AppColor.red : null),
              onChanged: (value) {
                if (value.contains(' ')) {
                  final words = value.split(' ');
                  if (words.last.isEmpty) {
                    words.removeLast();
                  }
                  final wordsLeft = _maxWords - index;
                  final wordsToInsertNum = min(wordsLeft, words.length);
                  for (var i = 0; i < wordsToInsertNum; i++) {
                    if (i != wordsToInsertNum || words[i].isNotEmpty) {
                      _mnemonicControllers[index + i].text = words[i];
                    }
                  }
                  FocusScope.of(context)
                      .requestFocus(_focusNodes[index + wordsToInsertNum]);
                }

                final numberOfWords = _getMnemonic().split(' ').length;
                setState(() {
                  _isSubmissionEnabled =
                      [12, 15, 18, 21, 24].contains(numberOfWords);
                  _isError = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getMnemonic() =>
      _mnemonicControllers.map((e) => e.text.trim()).join(' ').trim();
}
