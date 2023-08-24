import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddressAlias extends StatefulWidget {
  static const String tag = 'address_alias';
  final AddressAliasPayload payload;

  const AddressAlias({Key? key, required this.payload}) : super(key: key);

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
        _nameAddress = "enter_eth_alias".tr();
        break;
      case WalletType.Tezos:
        _nameAddress = "enter_tex_alias".tr();
        break;
      default:
        _nameAddress = "enter_address_alias".tr();
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
    bool isProcessing = false;
    return Scaffold(
      appBar: getBackAppBar(context,
          title: "address_alias".tr(),
          onBack: () => Navigator.of(context).pop()),
      body: BlocConsumer<PersonaBloc, PersonaState>(
        listener: (context, state) async {
          switch (state.createAccountState) {
            case ActionState.done:
              await _doneNaming();
              isProcessing = false;
              break;
            case ActionState.loading:
              isProcessing = true;
              break;
            case ActionState.error:
              isProcessing = false;
              break;
            default:
              isProcessing = false;
              break;
          }
        },
        builder: (context, state) {
          return Padding(
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
                    labelSemantics: "enter_alias_full",
                    title: "",
                    placeholder: "enter_address".tr(),
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
                      child: PrimaryButton(
                        text: "continue".tr(),
                        isProcessing: isProcessing,
                        onTap: isSavingAliasDisabled
                            ? null
                            : () {
                                context.read<PersonaBloc>().add(
                                    CreatePersonaAddressesEvent(
                                        _nameController.text.trim(),
                                        widget.payload.walletType));
                              },
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future _doneNaming() async {
    if (Platform.isAndroid) {
      final isAndroidEndToEndEncryptionAvailable =
          await injector<AccountService>()
              .isAndroidEndToEndEncryptionAvailable();

      if (!mounted) return;

      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context).pushReplacementNamed(AppRouter.cloudAndroidPage,
            arguments: isAndroidEndToEndEncryptionAvailable);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.cloudAndroidPage, (route) => false,
            arguments: isAndroidEndToEndEncryptionAvailable);
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
}

class AddressAliasPayload {
  final WalletType walletType;

  //constructor
  AddressAliasPayload(
    this.walletType,
  );
}
