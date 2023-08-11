import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NameAddressPersona extends StatefulWidget {
  static const String tag = 'name_address_persona';
  final NameAddressPersonaPayload payload;

  const NameAddressPersona({Key? key, required this.payload}) : super(key: key);

  @override
  State<NameAddressPersona> createState() => _NameAddressPersonaState();
}

class _NameAddressPersonaState extends State<NameAddressPersona> {
  final TextEditingController _nameController = TextEditingController();
  bool isSavingAliasDisabled = true;

  void saveAliasButtonChangedState() {
    setState(() {
      isSavingAliasDisabled = !isSavingAliasDisabled;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isProcessing = false;
    return Scaffold(
      appBar: getBackAppBar(context,
          title: "import_address".tr(),
          onBack: () => Navigator.of(context).pop()),
      body: Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "enter_address_alias".tr(),
              style: theme.textTheme.ppMori400Black14,
            ),
            const SizedBox(height: 10),
            AuTextField(
                labelSemantics: "enter_alias_full",
                title: "",
                placeholder: "enter_address".tr(),
                controller: _nameController,
                onChanged: (valueChanged) {
                  if (_nameController.text.trim().isEmpty !=
                      isSavingAliasDisabled) {
                    saveAliasButtonChangedState();
                  }
                }),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: "continue".tr(),
                    isProcessing: isProcessing,
                    onTap: isSavingAliasDisabled
                        ? null
                        : () async {
                            final accountService = injector<AccountService>();
                            final walletAddress =
                                await accountService.getAddressPersona(
                                    widget.payload.addressInfo.address);
                            if (walletAddress == null) return;
                            await accountService.updateAddressPersona(
                                walletAddress.copyWith(
                                    name: _nameController.text.trim()));
                            if (!mounted) return;
                            doneNaming(context);
                          },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

Future doneNaming(BuildContext context) async {
  if (Platform.isAndroid) {
    final isAndroidEndToEndEncryptionAvailable =
        await injector<AccountService>().isAndroidEndToEndEncryptionAvailable();

    if (context.mounted) {
      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context).pushReplacementNamed(AppRouter.cloudAndroidPage,
            arguments: isAndroidEndToEndEncryptionAvailable);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.cloudAndroidPage, (route) => false,
            arguments: isAndroidEndToEndEncryptionAvailable);
      }
    }
  } else {
    if (injector<ConfigurationService>().isDoneOnboarding()) {
      Navigator.of(context)
          .pushReplacementNamed(AppRouter.cloudPage, arguments: "nameAlias");
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.cloudPage, (route) => false,
          arguments: "nameAlias");
    }
  }
}

class NameAddressPersonaPayload {
  final AddressInfo addressInfo;

  //constructor
  NameAddressPersonaPayload(
    this.addressInfo,
  );
}
