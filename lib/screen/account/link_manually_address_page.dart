import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';

class LinkManuallyAddressPage extends StatefulWidget {
  const LinkManuallyAddressPage({Key? key}) : super(key: key);

  @override
  State<LinkManuallyAddressPage> createState() =>
      _LinkManuallyAddressPageState();
}

class _LinkManuallyAddressPageState extends State<LinkManuallyAddressPage> {
  TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Link Address",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "To manually input an address (Debug only).",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 40),
                    AuTextField(
                      title: "",
                      placeholder: "Paste address",
                      controller: _addressController,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "LINK".toUpperCase(),
                    onPress: () => _linkManuallyAddress(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _linkManuallyAddress() async {
    await injector<AccountService>()
        .linkManuallyAddress(_addressController.text);
    UIHelper.showInfoDialog(
        context, 'Account linked', 'Autonomy has linked your address.');

    Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context)
            .popUntil((route) => route.settings.name == AppRouter.settingsPage);
      } else {
        doneOnboarding(context);
      }
    });
  }
}
