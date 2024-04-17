import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/select_addresses.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sentry/sentry.dart';

class ImportSeedsPage extends StatefulWidget {
  const ImportSeedsPage({super.key});

  @override
  State<ImportSeedsPage> createState() => _ImportSeedsPageState();
}

class _ImportSeedsPageState extends State<ImportSeedsPage> {
  bool isError = false;
  final TextEditingController _phraseTextController = TextEditingController();
  final TextEditingController _passphraseTextController =
      TextEditingController();
  bool _isSubmissionEnabled = false;
  bool _obscureText = true;
  bool _passphraseObscureText = true;

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
                      addTitleSpace(),
                      Text(
                        'input_your_mnemonic'.tr(),
                        style: Theme.of(context).textTheme.ppMori400Black14,
                      ),
                      const SizedBox(height: 5),
                      AuTextField(
                        labelSemantics: 'enter_seed',
                        title: '',
                        enableSuggestions: false,
                        obscureText: _obscureText,
                        placeholder: 'enter_recovery_phrase'.tr(),
                        hintMaxLines: 1,
                        controller: _phraseTextController,
                        isError: isError,
                        onChanged: (value) {
                          final numberOfWords = value.trim().split(' ').length;
                          setState(() {
                            _isSubmissionEnabled =
                                [12, 15, 18, 21, 24].contains(numberOfWords);
                            isError = false;
                          });
                        },
                        suffix: IconButton(
                          icon: SvgPicture.asset(
                            _obscureText
                                ? 'assets/images/unhide.svg'
                                : 'assets/images/hide.svg',
                            colorFilter: const ColorFilter.mode(
                                AppColor.primaryBlack, BlendMode.srcIn),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
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
                enabled: _isSubmissionEnabled && !isError,
                onTap: () async => _import(),
              ),
            ],
          ),
        ),
      );

  Future<void> _import() async {
    try {
      setState(() {
        isError = false;
      });
      final accountService = injector<AccountService>();

      final persona = await accountService.importPersona(
        _phraseTextController.text.trim(),
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
        isError = true;
      });
    }
  }
}
