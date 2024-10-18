import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class AddressAlias extends StatefulWidget {
  final AddressAliasPayload payload;

  const AddressAlias({required this.payload, super.key});

  @override
  State<AddressAlias> createState() => _AddressAliasState();
}

class _AddressAliasState extends State<AddressAlias> {
  final TextEditingController _nameController = TextEditingController();
  bool isSavingAliasDisabled = true;
  late String _nameAddress;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    switch (widget.payload.walletType) {
      case WalletType.Ethereum:
        _nameAddress = 'enter_eth_alias'.tr();
      case WalletType.Tezos:
        _nameAddress = 'enter_tex_alias'.tr();
      default:
        _nameAddress = 'name_address'.tr();
        break;
    }
    focusNode.requestFocus();
  }

  void saveAliasButtonChangedState() {
    setState(() {
      isSavingAliasDisabled = !isSavingAliasDisabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(context,
          title: 'address_alias'.tr(),
          onBack: () => Navigator.of(context).pop()),
      body: Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              _nameAddress,
              style: theme.textTheme.ppMori400Black14,
            ),
            const SizedBox(height: 10),
            AuTextField(
                labelSemantics: 'enter_alias_full',
                title: '',
                placeholder: 'name_address'.tr(),
                controller: _nameController,
                focusNode: focusNode,
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
                            await injector<AccountService>().insertNextAddress(
                                widget.payload.walletType,
                                name: _nameController.text.trim());
                            if (!context.mounted) {
                              return;
                            }
                            _doneNaming(context);
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

  void _doneNaming(BuildContext context) {
    nameContinue(context);
  }
}

class AddressAliasPayload {
  final WalletType walletType;

  //constructor
  AddressAliasPayload(
    this.walletType,
  );
}
