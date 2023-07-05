import 'package:autonomy_flutter/common/injector.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry/sentry.dart';

class ImportSeedsPage extends StatefulWidget {
  static const String tag = 'import_seeds_page';

  const ImportSeedsPage({Key? key}) : super(key: key);

  @override
  State<ImportSeedsPage> createState() => _ImportSeedsPageState();
}

class _ImportSeedsPageState extends State<ImportSeedsPage> {
  bool _isImporting = false;
  bool isError = false;
  final TextEditingController _phraseTextController = TextEditingController();
  bool _isSubmissionEnabled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "import_address".tr(),
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
                    SizedBox(
                      height: 160,
                      child: AuTextField(
                        labelSemantics: "enter_seed",
                        title: "",
                        placeholder: "enter_recovery_phrase".tr(),
                        //"Enter recovery phrase with each word separated by a space",
                        maxLines: null,
                        hintMaxLines: 3,
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: "continue".tr(),
              enabled: _isSubmissionEnabled && !isError,
              isProcessing: _isImporting,
              onTap: () {
                _import();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future _import() async {
    try {
      setState(() {
        isError = false;
        _isImporting = true;
      });
      final accountService = injector<AccountService>();

      final persona =
          await accountService.importPersona(_phraseTextController.text.trim());
      setState(() {
        _isImporting = false;
      });
      if (!mounted) return;
      Navigator.of(context).pushNamed(SelectAddressesPage.tag,
          arguments: SelectAddressesPayload(persona: persona));

      if (!mounted) return;
    } catch (exception) {
      log.info("Import wallet fails ${exception.toString()}");
      if (!(exception is PlatformException &&
          exception.code == "importKey error")) {
        Sentry.captureException(exception);
      }
      UIHelper.hideInfoDialog(context);
      setState(() {
        isError = true;
        _isImporting = false;
      });
    }
  }
}
