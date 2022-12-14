//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NamePersonaPage extends StatefulWidget {
  final String uuid;

  const NamePersonaPage({Key? key, required this.uuid}) : super(key: key);

  @override
  State<NamePersonaPage> createState() => _NamePersonaPageState();
}

class _NamePersonaPageState extends State<NamePersonaPage> {
  final TextEditingController _nameController = TextEditingController();

  bool isSavingAliasDisabled = true;

  void saveAliasButtonChangedState() {
    setState(() {
      isSavingAliasDisabled = !isSavingAliasDisabled;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uuid = widget.uuid;
    context.read<PersonaBloc>().add(GetInfoPersonaEvent(uuid));
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
      appBar: getBackAppBar(
        context,
        onBack: null,
      ),
      body: BlocListener<PersonaBloc, PersonaState>(
        listener: (context, state) {
          switch (state.namePersonaState) {
            case ActionState.notRequested:
              _nameController.text = state.persona?.name ?? "";
              break;

            case ActionState.done:
              _doneNaming();
              break;

            default:
              break;
          }
        },
        child: Container(
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "account_alias".tr(),
                        style: theme.textTheme.headline1,
                      ),
                      addTitleSpace(),
                      Text(
                        injector<ConfigurationService>().isDoneOnboarding()
                            ? "need_add_alias".tr()
                            : "aa_you_can_add".tr(),
                        style: theme.textTheme.bodyText1,
                      ),
                      const SizedBox(height: 40),
                      AuTextField(
                          title: "",
                          placeholder: "enter_alias".tr(),
                          controller: _nameController,
                          onChanged: (valueChanged) {
                            if (_nameController.text.trim().isEmpty !=
                                isSavingAliasDisabled) {
                              saveAliasButtonChangedState();
                            }
                          }),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AuFilledButton(
                          text: "save_alias".tr().toUpperCase(),
                          onPress: isSavingAliasDisabled
                              ? null
                              : () {
                                  context.read<PersonaBloc>().add(
                                      NamePersonaEvent(
                                          _nameController.text.trim()));
                                },
                        ),
                      ),
                    ],
                  ),
                  !injector<ConfigurationService>().isDoneOnboarding()
                      ? TextButton(
                          onPressed: () async {
                            //_doneNaming();

                            if (!mounted) {
                              _doneNaming();
                              return;
                            }
                            context
                                .read<PersonaBloc>()
                                .add(NamePersonaEvent(''));
                          },
                          child:
                              Text("skip".tr(), style: theme.textTheme.button))
                      : const SizedBox(),
                ],
              ),
            ],
          ),
        ),
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
