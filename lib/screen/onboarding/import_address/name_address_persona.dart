import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class NameAddressPersona extends StatefulWidget {
  final NameAddressPersonaPayload payload;

  const NameAddressPersona({required this.payload, super.key});

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
    return Scaffold(
      appBar: getBackAppBar(context,
          title: 'import_address'.tr(),
          onBack: () => Navigator.of(context).pop()),
      body: Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'enter_address_alias'.tr(),
              style: theme.textTheme.ppMori400Black14,
            ),
            const SizedBox(height: 10),
            AuTextField(
                labelSemantics: 'enter_alias_full',
                title: '',
                placeholder: 'enter_address'.tr(),
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
                  child: PrimaryAsyncButton(
                    text: 'continue'.tr(),
                    onTap: isSavingAliasDisabled
                        ? null
                        : () async {
                            final accountService = injector<AccountService>();
                            final listAddressInfo =
                                widget.payload.listAddressInfo;
                            final name = _nameController.text.trim();

                            // update name
                            await Future.forEach(listAddressInfo,
                                (AddressInfo addressInfo) async {
                              final walletAddress = await accountService
                                  .getAddressPersona(addressInfo.address);
                              if (walletAddress == null) {
                                return;
                              }
                              await accountService.updateAddressPersona(
                                  walletAddress.copyWith(name: name));
                            });
                            await doneNaming(context);
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

Future<void> doneNaming(BuildContext context) async {
  nameContinue(context);
}

class NameAddressPersonaPayload {
  final List<AddressInfo> listAddressInfo;

  //constructor
  NameAddressPersonaPayload(
    this.listAddressInfo,
  );
}
